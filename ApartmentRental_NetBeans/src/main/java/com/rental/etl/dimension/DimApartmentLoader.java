package com.rental.etl.dimension;

import com.rental.etl.core.*;

import java.sql.*;
import java.time.Instant;
import java.util.*;

/**
 * DimApartmentLoader: SCD Type 2 — lưu lịch sử thay đổi giá thuê, trạng thái căn hộ.
 * Chạy hàng ngày 01:20. Incremental theo apartments.updated_at.
 *
 * FIX: Thay vì 4 SQL riêng mỗi apartment (expire + lookup location + lookup user + insert),
 *      dùng batch IN() expire + preload lookup maps vào memory + batch INSERT.
 *      → giảm từ 160.000 round-trips xuống ~200 calls cho 40k apartments.
 */
public class DimApartmentLoader implements ETLJob {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.dim_apartment (" +
        "  apt_key        INT AUTO_INCREMENT PRIMARY KEY," +
        "  apt_id         INT             NOT NULL COMMENT 'Natural key từ OLTP'," +
        "  title          VARCHAR(255)    NOT NULL," +
        "  type           VARCHAR(20)     NOT NULL," +
        "  area           FLOAT           NOT NULL," +
        "  rental_type    VARCHAR(20)     NOT NULL," +
        "  price_month    DECIMAL(15,0)   NULL," +
        "  price_day      DECIMAL(15,0)   NULL," +
        "  location_key   INT             NOT NULL," +
        "  owner_key      INT             NOT NULL," +
        "  effective_date DATE            NOT NULL," +
        "  expiry_date    DATE            NULL," +
        "  is_current     BOOLEAN         DEFAULT TRUE," +
        "  INDEX idx_apt_id (apt_id)," +
        "  INDEX idx_apt_current (apt_id, is_current)" +
        ") ENGINE=InnoDB";

    private static final int CHUNK = 500;
    private static final int BATCH = 1000;

    private final ETLContext ctx;
    private final WatermarkHelper watermark;
    private final List<Object[]> extracted = new ArrayList<>();
    private int rowsProcessed = 0;

    public DimApartmentLoader(ETLContext ctx) {
        this.ctx = ctx;
        this.watermark = new WatermarkHelper(ctx.getDwhConn());
    }

    @Override public String getJobName() { return "DimApartmentLoader"; }
    @Override public int getRowsProcessed() { return rowsProcessed; }

    @Override
    public void extract() throws Exception {
        ctx.getDwhConn().createStatement().execute(CREATE_TABLE);
        Timestamp lastRun = watermark.getLastRunAt(getJobName());

        String sql =
            "SELECT a.apt_id, a.title, a.type, a.area, a.rental_type, " +
            "       a.rent_price_month, a.rent_price_day, a.district, a.city, " +
            "       a.owner_id " +
            "FROM apartment_rental.apartments a " +
            "WHERE a.updated_at > ? OR a.created_at > ? " +
            "ORDER BY a.apt_id ASC";
        try (PreparedStatement ps = ctx.getOltpConn().prepareStatement(sql)) {
            ps.setTimestamp(1, lastRun);
            ps.setTimestamp(2, lastRun);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                extracted.add(new Object[]{
                    rs.getInt("apt_id"),       rs.getString("title"),
                    rs.getString("type"),       rs.getFloat("area"),
                    rs.getString("rental_type"),
                    rs.getLong("rent_price_month"), rs.getLong("rent_price_day"),
                    rs.getString("district"),   rs.getString("city"),
                    rs.getInt("owner_id")
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

        // ── Bước 1: Preload toàn bộ dim_location vào Map (1 query duy nhất) ──
        Map<String, Integer> locationMap = new HashMap<>();
        try (Statement st = dwh.createStatement();
             ResultSet rs = st.executeQuery(
                "SELECT location_key, COALESCE(district,'Không xác định'), COALESCE(city,'Hà Nội') " +
                "FROM cc_dwh.dim_location")) {
            while (rs.next()) locationMap.put(rs.getString(2) + "|" + rs.getString(3), rs.getInt(1));
        }

        // ── Bước 2: Preload user_key hiện tại vào Map (1 query duy nhất) ──
        Map<Integer, Integer> userKeyMap = new HashMap<>();
        try (Statement st = dwh.createStatement();
             ResultSet rs = st.executeQuery(
                "SELECT user_id, user_key FROM cc_dwh.dim_user WHERE is_current=TRUE")) {
            while (rs.next()) userKeyMap.put(rs.getInt(1), rs.getInt(2));
        }

        // ── Bước 3: Expire theo chunk IN() ────────────────────────────────────
        List<Integer> aptIds = new ArrayList<>(extracted.size());
        for (Object[] r : extracted) aptIds.add((int) r[0]);

        for (int i = 0; i < aptIds.size(); i += CHUNK) {
            List<Integer> chunk = aptIds.subList(i, Math.min(i + CHUNK, aptIds.size()));
            String placeholders = String.join(",", Collections.nCopies(chunk.size(), "?"));
            try (PreparedStatement ps = dwh.prepareStatement(
                    "UPDATE cc_dwh.dim_apartment SET is_current=FALSE, expiry_date=CURDATE() " +
                    "WHERE apt_id IN (" + placeholders + ") AND is_current=TRUE")) {
                for (int j = 0; j < chunk.size(); j++) ps.setInt(j + 1, chunk.get(j));
                ps.executeUpdate();
            }
        }

        // ── Bước 4: Batch INSERT ───────────────────────────────────────────────
        try (PreparedStatement ps = dwh.prepareStatement(
                "INSERT INTO cc_dwh.dim_apartment " +
                "(apt_id,title,type,area,rental_type,price_month,price_day," +
                " location_key,owner_key,effective_date,is_current) " +
                "VALUES (?,?,?,?,?,?,?,?,?,CURDATE(),TRUE)")) {
            int n = 0;
            for (Object[] row : extracted) {
                String districtCity = nvl((String) row[7], "Không xác định") + "|" + nvl((String) row[8], "Hà Nội");
                int locationKey = locationMap.getOrDefault(districtCity, 1);
                int ownerKey    = userKeyMap.getOrDefault((int) row[9], 1);

                ps.setInt(1,    (int)   row[0]);
                ps.setString(2, (String) row[1]);
                ps.setString(3, (String) row[2]);
                ps.setFloat(4,  (float)  row[3]);
                ps.setString(5, (String) row[4]);
                ps.setLong(6,   row[5] != null ? (long) row[5] : 0L);
                ps.setLong(7,   row[6] != null ? (long) row[6] : 0L);
                ps.setInt(8,    locationKey);
                ps.setInt(9,    ownerKey);
                ps.addBatch();
                if (++n % BATCH == 0) { ps.executeBatch(); ps.clearBatch(); }
            }
            ps.executeBatch();
            rowsProcessed = extracted.size();
        }

        watermark.updateSuccess(getJobName(), now, 0, rowsProcessed);
    }

    private String nvl(String v, String def) { return v != null ? v : def; }
}
