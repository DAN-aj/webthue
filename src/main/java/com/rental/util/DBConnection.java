package com.rental.util;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * Kết nối MySQL qua HikariCP.
 * Chạy trên NetBeans + Tomcat local — cấu hình trong file này hoặc config.properties.
 *
 * ── HƯỚNG DẪN ──────────────────────────────────────────────────
 * Mặc định kết nối:
 *   Host: localhost:3306
 *   Database: apartment_rental
 *   User: root
 *   Pass: 1234
 *
 * Thay đổi nếu cần (DB_USER, DB_PASS, DB_NAME) ngay bên dưới.
 * ────────────────────────────────────────────────────────────────
 */
public class DBConnection {
    private static final HikariDataSource dataSource;

    static {
        // ── Thay đổi thông tin kết nối tại đây nếu cần ──────────
        String dbHost = "localhost";
        String dbPort = "3306";
        String dbName = "apartment_rental";
        String dbUser = "root";
        String dbPass = "1234";
        // ────────────────────────────────────────────────────────

        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:mysql://" + dbHost + ":" + dbPort + "/" + dbName
                + "?useSSL=false&serverTimezone=Asia/Ho_Chi_Minh&characterEncoding=UTF-8&allowPublicKeyRetrieval=true");
        config.setUsername(dbUser);
        config.setPassword(dbPass);
        config.setDriverClassName("com.mysql.cj.jdbc.Driver");

        // Pool sizing
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(3);
        config.setIdleTimeout(300_000);       // 5 phút
        config.setConnectionTimeout(10_000);  // 10 giây
        config.setMaxLifetime(1_200_000);     // 20 phút
        config.setKeepaliveTime(60_000);      // ping mỗi 60s

        // Performance
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        config.addDataSourceProperty("useServerPrepStmts", "true");
        config.addDataSourceProperty("rewriteBatchedStatements", "true");

        dataSource = new HikariDataSource(config);
    }

    public static Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close(); // Trả về pool
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    public static void shutdown() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
        }
    }
}
