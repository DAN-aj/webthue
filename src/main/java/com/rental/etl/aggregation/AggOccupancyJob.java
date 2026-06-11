package com.rental.etl.aggregation;

import com.rental.etl.core.*;

import java.sql.*;

/**
 * AggOccupancyJob: Tính tỷ lệ lấp đầy (occupancy rate) theo quận.
 * Chạy hàng ngày 03:30. Full Refresh.
 */
public class AggOccupancyJob implements ETLJob {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.agg_occupancy_rate (" +
        "  calc_date        DATE         NOT NULL," +
        "  location_key     INT          NOT NULL," +
        "  district         VARCHAR(100) NOT NULL," +
        "  total_apartments INT          DEFAULT 0," +
        "  active_contracts INT          DEFAULT 0," +
        "  occupancy_rate   DECIMAL(5,2) DEFAULT 0.00 COMMENT '%'," +
        "  etl_loaded_at    TIMESTAMP    NOT NULL," +
        "  PRIMARY KEY (calc_date, location_key)" +
        ") ENGINE=InnoDB";

    // Tính cho ngày hôm nay: số hợp đồng active / tổng căn hộ approved theo quận
    private static final String REFRESH_SQL =
        "INSERT INTO cc_dwh.agg_occupancy_rate " +
        "(calc_date, location_key, district, total_apartments, active_contracts, occupancy_rate, etl_loaded_at) " +
        "SELECT " +
        "  CURDATE() AS calc_date," +
        "  l.location_key," +
        "  l.district," +
        "  COUNT(DISTINCT da.apt_key)   AS total_apartments," +
        "  COUNT(DISTINCT CASE WHEN fc.status='active' THEN fc.contract_key END) AS active_contracts," +
        "  ROUND(" +
        "    COUNT(DISTINCT CASE WHEN fc.status='active' THEN fc.contract_key END) * 100.0 " +
        "    / NULLIF(COUNT(DISTINCT da.apt_key), 0), 2" +
        "  ) AS occupancy_rate," +
        "  NOW() AS etl_loaded_at " +
        "FROM cc_dwh.dim_apartment da " +
        "JOIN cc_dwh.dim_location l ON da.location_key = l.location_key " +
        "LEFT JOIN cc_dwh.fact_contracts fc ON da.apt_key = fc.apt_key " +
        "WHERE da.is_current = TRUE " +
        "GROUP BY l.location_key, l.district " +
        "ON DUPLICATE KEY UPDATE " +
        "  total_apartments = VALUES(total_apartments)," +
        "  active_contracts = VALUES(active_contracts)," +
        "  occupancy_rate   = VALUES(occupancy_rate)," +
        "  etl_loaded_at    = VALUES(etl_loaded_at)";

    private final ETLContext ctx;
    private int rowsProcessed = 0;

    public AggOccupancyJob(ETLContext ctx) { this.ctx = ctx; }

    @Override public String getJobName() { return "AggOccupancyJob"; }
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
        new com.rental.etl.core.WatermarkHelper(ctx.getDwhConn()).updateSuccess(
            getJobName(),
            java.sql.Timestamp.from(java.time.Instant.now()),
            0,
            rowsProcessed
        );
    }
}
