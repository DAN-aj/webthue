package com.rental.etl.core;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * ETLContext – quản lý 2 connection pool OLTP + DWH.
 *
 * PERF FIX v14: LAZY INIT
 *  - Pool chỉ được tạo lần đầu khi ETLContext() được gọi (khi ETL thực sự chạy)
 *  - Không khởi tạo static block → không block Tomcat startup
 *  - connectTimeout giảm từ 20s → 5s, socketTimeout giảm từ 600s → 60s (ETL job)
 */
public class ETLContext implements AutoCloseable {

    // Lazy: chỉ init khi lần đầu ETL chạy
    private static volatile HikariDataSource oltpPool;
    private static volatile HikariDataSource dwhPool;
    private static final Object lock = new Object();

    private final Connection oltpConn;
    private final Connection dwhConn;

    public ETLContext() throws SQLException {
        ensurePools();
        this.oltpConn = oltpPool.getConnection();
        this.dwhConn  = dwhPool.getConnection();
    }

    private static void ensurePools() {
        if (oltpPool != null && dwhPool != null) return;
        synchronized (lock) {
            // FIX v13: tạo cả 2 pool trong cùng 1 lần, gán vào biến local trước,
            // chỉ gán vào static field sau khi cả 2 thành công → tránh partial-init.
            if (oltpPool == null || dwhPool == null) {
                String host = System.getenv().getOrDefault("DB_HOST", "localhost");
                String port = System.getenv().getOrDefault("DB_PORT", "3306");
                String user = System.getenv().getOrDefault("DB_USER", "root");
                String pass = System.getenv().getOrDefault("DB_PASS", "1234");
                String tz   = "?useSSL=false&serverTimezone=Asia/Ho_Chi_Minh&characterEncoding=UTF-8&allowPublicKeyRetrieval=true";

                HikariDataSource newOltp = buildPool("ETL-OLTP",
                    "jdbc:mysql://" + host + ":" + port + "/apartment_rental" + tz, user, pass, 8);
                HikariDataSource newDwh;
                try {
                    newDwh = buildPool("ETL-DWH",
                        "jdbc:mysql://" + host + ":" + port + "/cc_dwh" + tz, user, pass, 8);
                } catch (Exception e) {
                    // FIX: nếu DWH pool tạo thất bại, đóng OLTP pool đã tạo để không leak
                    newOltp.close();
                    throw e;
                }
                // Chỉ gán sau khi cả 2 đều thành công
                oltpPool = newOltp;
                dwhPool  = newDwh;
            }
        }
    }

    private static HikariDataSource buildPool(String name, String url, String user, String pass, int maxSize) {
        HikariConfig cfg = new HikariConfig();
        cfg.setPoolName(name);
        cfg.setJdbcUrl(url);
        cfg.setUsername(user);
        cfg.setPassword(pass);
        cfg.setDriverClassName("com.mysql.cj.jdbc.Driver");
        cfg.setMaximumPoolSize(maxSize);
        cfg.setMinimumIdle(0);           // Không giữ idle connection — ETL chạy theo lịch
        cfg.setConnectionTimeout(5_000); // 5 giây fail-fast
        cfg.setIdleTimeout(60_000);      // Trả về pool sau 60s idle
        cfg.setMaxLifetime(1_800_000);
        cfg.addDataSourceProperty("rewriteBatchedStatements", "true");
        cfg.addDataSourceProperty("cachePrepStmts", "true");
        cfg.addDataSourceProperty("prepStmtCacheSize", "250");
        cfg.addDataSourceProperty("useServerPrepStmts", "true");
        cfg.addDataSourceProperty("socketTimeout",  "120000");  // 2 phút
        cfg.addDataSourceProperty("connectTimeout", "5000");
        return new HikariDataSource(cfg);
    }

    public Connection getOltpConn() { return oltpConn; }
    public Connection getDwhConn()  { return dwhConn;  }

    @Override
    public void close() {
        try { if (oltpConn != null) oltpConn.close(); } catch (Exception ignored) {}
        try { if (dwhConn  != null) dwhConn.close();  } catch (Exception ignored) {}
    }

    // FIX v13: synchronized(lock) để tránh race condition với ensurePools().
    // Trước đây shutdownPools() đọc/ghi oltpPool/dwhPool không được bảo vệ →
    // nếu Tomcat undeploy xảy ra đúng lúc ETL job đang init pool, có thể NPE
    // hoặc pool bị close giữa chừng khi đang lấy connection.
    public static void shutdownPools() {
        synchronized (lock) {
            if (oltpPool != null && !oltpPool.isClosed()) { oltpPool.close(); oltpPool = null; }
            if (dwhPool  != null && !dwhPool.isClosed())  { dwhPool.close();  dwhPool  = null; }
        }
    }
}
