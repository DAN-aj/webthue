package com.rental.etl.dimension;

import com.rental.etl.core.*;

import java.sql.*;
import java.time.Instant;
import java.util.*;

/**
 * DimUserLoader: SCD Type 2 — mỗi thay đổi thông tin user tạo bản ghi mới.
 * Chạy hàng ngày 01:10. Incremental theo users.updated_at.
 *
 * FIX: Dùng batch UPDATE (IN clause) + batch INSERT thay vì N×2 SQL riêng lẻ
 *      → giảm từ 100.000 round-trips xuống còn vài chục batch calls.
 */
public class DimUserLoader implements ETLJob {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.dim_user (" +
        "  user_key       INT AUTO_INCREMENT PRIMARY KEY," +
        "  user_id        INT         NOT NULL COMMENT 'Natural key từ OLTP'," +
        "  full_name      VARCHAR(100) NOT NULL," +
        "  email          VARCHAR(100) NOT NULL," +
        "  phone          VARCHAR(20)  NULL," +
        "  role           VARCHAR(20)  NOT NULL," +
        "  status         VARCHAR(20)  NOT NULL," +
        "  effective_date DATE         NOT NULL," +
        "  expiry_date    DATE         NULL," +
        "  is_current     BOOLEAN      DEFAULT TRUE," +
        "  INDEX idx_user_id (user_id)," +
        "  INDEX idx_user_current (user_id, is_current)" +
        ") ENGINE=InnoDB";

    private static final int CHUNK = 500;   // chunk size cho IN()
    private static final int BATCH = 1000;  // batch size cho INSERT

    private final ETLContext ctx;
    private final WatermarkHelper watermark;
    private final List<Object[]> extracted = new ArrayList<>();
    private int rowsProcessed = 0;

    public DimUserLoader(ETLContext ctx) {
        this.ctx = ctx;
        this.watermark = new WatermarkHelper(ctx.getDwhConn());
    }

    @Override public String getJobName() { return "DimUserLoader"; }
    @Override public int getRowsProcessed() { return rowsProcessed; }

    @Override
    public void extract() throws Exception {
        ctx.getDwhConn().createStatement().execute(CREATE_TABLE);
        Timestamp lastRun = watermark.getLastRunAt(getJobName());

        String sql =
            "SELECT user_id, full_name, email, phone, role, status, updated_at " +
            "FROM apartment_rental.users " +
            "WHERE updated_at > ? OR created_at > ? " +
            "ORDER BY user_id ASC";
        try (PreparedStatement ps = ctx.getOltpConn().prepareStatement(sql)) {
            ps.setTimestamp(1, lastRun);
            ps.setTimestamp(2, lastRun);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                extracted.add(new Object[]{
                    rs.getInt("user_id"), rs.getString("full_name"),
                    rs.getString("email"), rs.getString("phone"),
                    rs.getString("role"), rs.getString("status")
                });
            }
        }
    }

    @Override public void transform() {}

    @Override
    public void load() throws Exception {
        if (extracted.isEmpty()) return;
        Connection dwh = ctx.getDwhConn();
        Timestamp now = Timestamp.from(Instant.now());

        // Bước 1: Expire theo chunk IN() — 1 UPDATE / 500 users thay vì N UPDATE riêng
        List<Integer> userIds = new ArrayList<>(extracted.size());
        for (Object[] r : extracted) userIds.add((int) r[0]);

        for (int i = 0; i < userIds.size(); i += CHUNK) {
            List<Integer> chunk = userIds.subList(i, Math.min(i + CHUNK, userIds.size()));
            String placeholders = String.join(",", Collections.nCopies(chunk.size(), "?"));
            try (PreparedStatement ps = dwh.prepareStatement(
                    "UPDATE cc_dwh.dim_user SET is_current=FALSE, expiry_date=CURDATE() " +
                    "WHERE user_id IN (" + placeholders + ") AND is_current=TRUE")) {
                for (int j = 0; j < chunk.size(); j++) ps.setInt(j + 1, chunk.get(j));
                ps.executeUpdate();
            }
        }

        // Bước 2: Batch INSERT — flush mỗi 1000 rows
        try (PreparedStatement ps = dwh.prepareStatement(
                "INSERT INTO cc_dwh.dim_user " +
                "(user_id,full_name,email,phone,role,status,effective_date,is_current) " +
                "VALUES (?,?,?,?,?,?,CURDATE(),TRUE)")) {
            int n = 0;
            for (Object[] row : extracted) {
                ps.setInt(1, (int) row[0]);
                ps.setString(2, (String) row[1]);
                ps.setString(3, (String) row[2]);
                ps.setString(4, (String) row[3]);
                ps.setString(5, (String) row[4]);
                ps.setString(6, (String) row[5]);
                ps.addBatch();
                if (++n % BATCH == 0) { ps.executeBatch(); ps.clearBatch(); }
            }
            ps.executeBatch();
            rowsProcessed = extracted.size();
        }

        watermark.updateSuccess(getJobName(), now, 0, rowsProcessed);
    }
}
