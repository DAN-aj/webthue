package com.rental.etl.aggregation;

import com.rental.etl.core.*;

import java.sql.*;
import java.time.Instant;

/**
 * AggDailyRevenueJob: Tính lại agg_daily_revenue từ fact_contracts + fact_payments.
 * Chạy hàng ngày 03:00. Full Refresh cho 90 ngày gần nhất để đảm bảo nhất quán.
 */
public class AggDailyRevenueJob implements ETLJob {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.agg_daily_revenue (" +
        "  revenue_date      DATE         NOT NULL," +
        "  date_key          INT          NOT NULL," +
        "  location_key      INT          NOT NULL," +
        "  district          VARCHAR(100) NOT NULL," +
        "  total_platform_fee DECIMAL(15,0) DEFAULT 0," +
        "  total_revenue     DECIMAL(15,0) DEFAULT 0," +
        "  contract_count    INT          DEFAULT 0," +
        "  etl_loaded_at     TIMESTAMP    NOT NULL," +
        "  PRIMARY KEY (revenue_date, location_key)," +
        "  INDEX idx_agg_date (revenue_date)," +
        "  INDEX idx_agg_loc (location_key)" +
        ") ENGINE=InnoDB";

    // Refresh 90 ngày gần nhất cho tất cả status có phát sinh doanh thu
    // (active = đang thuê, expired = đã hết hạn — đều có platform_fee)
    private static final String REFRESH_SQL =
        "INSERT INTO cc_dwh.agg_daily_revenue " +
        "(revenue_date, date_key, location_key, district, total_platform_fee, total_revenue, contract_count, etl_loaded_at) " +
        "SELECT " +
        "  t.full_date AS revenue_date," +
        "  fc.date_key," +
        "  fc.location_key," +
        "  l.district," +
        "  SUM(fc.platform_fee)               AS total_platform_fee," +
        "  SUM(fc.monthly_rent)               AS total_revenue," +
        "  COUNT(DISTINCT fc.contract_key)    AS contract_count," +
        "  NOW() AS etl_loaded_at " +
        "FROM cc_dwh.fact_contracts fc " +
        "JOIN cc_dwh.dim_time t ON fc.date_key = t.date_key " +
        "JOIN cc_dwh.dim_location l ON fc.location_key = l.location_key " +
        "WHERE fc.status NOT IN ('pending','rejected') " +  // bao gồm active, expired, terminated, approved
        "  AND t.full_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) " +
        "GROUP BY t.full_date, fc.date_key, fc.location_key, l.district " +
        "ON DUPLICATE KEY UPDATE " +
        "  total_platform_fee = VALUES(total_platform_fee)," +
        "  total_revenue      = VALUES(total_revenue)," +
        "  contract_count     = VALUES(contract_count)," +
        "  etl_loaded_at      = VALUES(etl_loaded_at)";

    private final ETLContext ctx;
    private int rowsProcessed = 0;

    public AggDailyRevenueJob(ETLContext ctx) { this.ctx = ctx; }

    @Override public String getJobName() { return "AggDailyRevenueJob"; }
    @Override public int getRowsProcessed() { return rowsProcessed; }

    @Override
    public void extract() throws Exception {
        ctx.getDwhConn().createStatement().execute(CREATE_TABLE);
    }

    @Override public void transform() {}

    @Override
    public void load() throws Exception {
        try (PreparedStatement ps = ctx.getDwhConn().prepareStatement(REFRESH_SQL)) {
            rowsProcessed = ps.executeUpdate();
        }
        // Cập nhật watermark → isDwhFresh() trả true sau khi job xong
        new WatermarkHelper(ctx.getDwhConn()).updateSuccess(
            getJobName(),
            Timestamp.from(Instant.now()),
            0,
            rowsProcessed
        );
    }
}
