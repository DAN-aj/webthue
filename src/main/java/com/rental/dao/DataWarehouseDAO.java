package com.rental.dao;

import com.google.gson.Gson;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.*;
import java.util.*;

/**
 * DataWarehouseDAO – truy vấn DWH (cc_dwh).
 *
 * PERF FIX v14: LAZY INIT
 *  - Pool không khởi tạo static block → không block Tomcat startup
 *  - Chỉ kết nối khi được gọi lần đầu (thường là ETL page, không phải dashboard)
 *  - connectTimeout = 3s fail-fast; minimumIdle = 0
 */
public class DataWarehouseDAO {

    private static volatile HikariDataSource dwhPool;
    private static final Object lock = new Object();
    private final Gson gson = new Gson();

    private static HikariDataSource getPool() {
        if (dwhPool != null) return dwhPool;
        synchronized (lock) {
            if (dwhPool == null) {
                String host = System.getenv().getOrDefault("DB_HOST", "localhost");
                String port = System.getenv().getOrDefault("DB_PORT", "3306");
                String user = System.getenv().getOrDefault("DB_USER", "root");
                String pass = System.getenv().getOrDefault("DB_PASS", "1234");
                String tz   = "?useSSL=false&serverTimezone=Asia/Ho_Chi_Minh" +
                              "&characterEncoding=UTF-8&allowPublicKeyRetrieval=true";

                HikariConfig cfg = new HikariConfig();
                cfg.setPoolName("DWH-Report");
                cfg.setJdbcUrl("jdbc:mysql://" + host + ":" + port + "/cc_dwh" + tz);
                cfg.setUsername(user);
                cfg.setPassword(pass);
                cfg.setDriverClassName("com.mysql.cj.jdbc.Driver");
                cfg.setMaximumPoolSize(4);
                cfg.setMinimumIdle(0);           // Không giữ idle connection
                cfg.setConnectionTimeout(3_000); // 3 giây fail-fast
                cfg.setIdleTimeout(60_000);
                cfg.setMaxLifetime(600_000);
                cfg.addDataSourceProperty("connectTimeout", "3000");
                cfg.addDataSourceProperty("socketTimeout",  "10000");
                cfg.addDataSourceProperty("cachePrepStmts", "true");
                cfg.addDataSourceProperty("prepStmtCacheSize", "50");
                dwhPool = new HikariDataSource(cfg);
            }
        }
        return dwhPool;
    }

    public Connection getConnection() throws SQLException {
        return getPool().getConnection();
    }

    public boolean isDwhFresh() {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "SELECT last_run_at FROM cc_dwh.etl_watermark " +
                "WHERE job_name='AggDailyRevenueJob'")) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Timestamp last = rs.getTimestamp("last_run_at");
                long hoursAgo = (System.currentTimeMillis() - last.getTime()) / 3_600_000;
                return hoursAgo < 24;
            }
        } catch (Exception ignored) {}
        return false;
    }

    public String getLastEtlRunAt() {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "SELECT MAX(last_run_at) FROM cc_dwh.etl_watermark")) {
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getString(1) : "Chưa chạy";
        } catch (Exception e) { return "Lỗi kết nối DWH"; }
    }

    public String getRevenueByMonth() {
        return queryLabelValue(
            "SELECT DATE_FORMAT(revenue_date,'%Y-%m') AS label, " +
            "SUM(total_platform_fee) AS value " +
            "FROM cc_dwh.agg_daily_revenue " +
            "WHERE revenue_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) " +
            "GROUP BY label ORDER BY label");
    }

    public String getRevenueByDistrict() {
        return queryLabelValue(
            "SELECT district AS label, SUM(total_platform_fee) AS value " +
            "FROM cc_dwh.agg_daily_revenue " +
            "GROUP BY district ORDER BY value DESC LIMIT 8");
    }

    public String getContractsByMonth() {
        return queryLabelValue(
            "SELECT DATE_FORMAT(revenue_date,'%Y-%m') AS label, " +
            "SUM(contract_count) AS value " +
            "FROM cc_dwh.agg_daily_revenue " +
            "WHERE revenue_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) " +
            "GROUP BY label ORDER BY label");
    }

    public String getOccupancyByDistrict() {
        return queryLabelValue(
            "SELECT district AS label, occupancy_rate AS value " +
            "FROM cc_dwh.agg_occupancy_rate " +
            "WHERE calc_date = (SELECT MAX(calc_date) FROM cc_dwh.agg_occupancy_rate) " +
            "ORDER BY value DESC LIMIT 10");
    }

    public List<Map<String, Object>> getRecentAuditLog(int limit) {
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "SELECT job_name, started_at, finished_at, rows_processed, status, error_message " +
                "FROM etl_audit_log ORDER BY log_id DESC LIMIT ?")) {
            ps.setInt(1, limit);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("jobName",       rs.getString("job_name"));
                row.put("startedAt",     rs.getString("started_at"));
                row.put("finishedAt",    rs.getString("finished_at"));
                row.put("rowsProcessed", rs.getInt("rows_processed"));
                row.put("status",        rs.getString("status"));
                row.put("errorMessage",  rs.getString("error_message"));
                list.add(row);
            }
        } catch (Exception ignored) {}
        return list;
    }

    private String queryLabelValue(String sql) {
        List<String> labels = new ArrayList<>();
        List<Double>  data  = new ArrayList<>();
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                labels.add(rs.getString(1));
                data.add(rs.getDouble(2));
            }
        } catch (Exception e) {
            System.err.println("[DWH DAO] " + e.getMessage());
        }
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("labels", labels);
        map.put("data",   data);
        return gson.toJson(map);
    }
}
