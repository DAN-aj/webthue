package com.rental.etl.dimension;

import com.rental.etl.core.*;

import java.sql.*;
import java.util.*;

/**
 * DimLocationLoader: Extract địa lý từ bảng apartments OLTP → dim_location DWH.
 * Chạy hàng ngày 01:00. Incremental: chỉ thêm quận mới.
 */
public class DimLocationLoader implements ETLJob {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.dim_location (" +
        "  location_key INT AUTO_INCREMENT PRIMARY KEY," +
        "  district     VARCHAR(100) NOT NULL," +
        "  city         VARCHAR(100) NOT NULL," +
        "  region       VARCHAR(50)  NOT NULL COMMENT 'Bắc/Trung/Nam'," +
        "  lat          DECIMAL(9,6) NULL," +
        "  lng          DECIMAL(9,6) NULL," +
        "  UNIQUE KEY uq_district_city (district, city)" +
        ") ENGINE=InnoDB";

    private final ETLContext ctx;
    private final List<String[]> extracted = new ArrayList<>();
    private int rowsProcessed = 0;

    public DimLocationLoader(ETLContext ctx) { this.ctx = ctx; }

    @Override public String getJobName() { return "DimLocationLoader"; }
    @Override public int getRowsProcessed() { return rowsProcessed; }

    @Override
    public void extract() throws Exception {
        ctx.getDwhConn().createStatement().execute(CREATE_TABLE);

        // Lấy tất cả (district, city) distinct từ OLTP
        String sql = "SELECT DISTINCT " +
            "COALESCE(district,'Không xác định') AS district, " +
            "COALESCE(city,'Hà Nội') AS city " +
            "FROM apartment_rental.apartments WHERE district IS NOT NULL";
        try (PreparedStatement ps = ctx.getOltpConn().prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                extracted.add(new String[]{rs.getString("district"), rs.getString("city")});
            }
        }
    }

    @Override public void transform() {
        // Gán region dựa trên city
        // (Đã xử lý inline trong load vì nhẹ)
    }

    @Override
    public void load() throws Exception {
        String sql =
            "INSERT IGNORE INTO cc_dwh.dim_location (district, city, region) " +
            "VALUES (?, ?, ?)";
        try (PreparedStatement ps = ctx.getDwhConn().prepareStatement(sql)) {
            for (String[] row : extracted) {
                ps.setString(1, row[0]);
                ps.setString(2, row[1]);
                ps.setString(3, detectRegion(row[1]));
                ps.addBatch();
            }
            int[] counts = ps.executeBatch();
            for (int c : counts) rowsProcessed += (c > 0 ? 1 : 0);
        }
    }

    private String detectRegion(String city) {
        if (city == null) return "Bắc";
        city = city.toLowerCase();
        if (city.contains("hà nội") || city.contains("hải phòng") ||
            city.contains("quảng ninh") || city.contains("nam định")) return "Bắc";
        if (city.contains("đà nẵng") || city.contains("huế") ||
            city.contains("quảng nam") || city.contains("nghệ an")) return "Trung";
        return "Nam"; // TP.HCM và các tỉnh phía Nam
    }
}
