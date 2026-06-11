package com.rental.etl.fact;

import com.rental.etl.core.*;

import java.sql.*;
import java.time.Instant;
import java.util.*;

/**
 * FactContractLoader: Incremental load hợp đồng từ OLTP → fact_contracts DWH.
 * Chạy hàng ngày 02:00.
 *
 * FIX 1: Kiểm tra cột move_in_confirmed tồn tại trước khi query (tương thích DB cũ).
 * FIX 2: Preload lookup maps vào memory thay vì gọi SQL cho từng row.
 */
public class FactContractLoader implements ETLJob {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.fact_contracts (" +
        "  contract_key     INT AUTO_INCREMENT PRIMARY KEY," +
        "  contract_id      INT           NOT NULL UNIQUE COMMENT 'NK từ OLTP'," +
        "  date_key         INT           NOT NULL," +
        "  apt_key          INT           NOT NULL," +
        "  tenant_key       INT           NOT NULL," +
        "  owner_key        INT           NOT NULL," +
        "  location_key     INT           NOT NULL," +
        "  rental_type      VARCHAR(20)   NOT NULL," +
        "  status           VARCHAR(20)   NOT NULL," +
        "  monthly_rent     DECIMAL(15,0) NOT NULL," +
        "  deposit_amount   DECIMAL(15,0) DEFAULT 0," +
        "  platform_fee     DECIMAL(15,0) NOT NULL," +
        "  contract_days    INT           NOT NULL," +
        "  move_in_confirmed BOOLEAN      DEFAULT FALSE," +
        "  days_to_rent     INT           NULL," +
        "  etl_loaded_at    TIMESTAMP     NOT NULL," +
        "  INDEX idx_fc_date (date_key)," +
        "  INDEX idx_fc_apt (apt_key)," +
        "  INDEX idx_fc_status (status)" +
        ") ENGINE=InnoDB";

    private static final int BATCH = 1000;

    private final ETLContext ctx;
    private final WatermarkHelper watermark;
    private final List<Object[]> extracted = new ArrayList<>();
    private int rowsProcessed = 0;

    public FactContractLoader(ETLContext ctx) {
        this.ctx = ctx;
        this.watermark = new WatermarkHelper(ctx.getDwhConn());
    }

    @Override public String getJobName() { return "FactContractLoader"; }
    @Override public int getRowsProcessed() { return rowsProcessed; }

    @Override
    public void extract() throws Exception {
        ctx.getDwhConn().createStatement().execute(CREATE_TABLE);
        watermark.markRunning(getJobName()); // v10: đánh dấu running trước khi extract
        int lastMaxId  = watermark.getLastMaxId(getJobName());
        Timestamp lastRunAt = watermark.getLastRunAt(getJobName());

        // Kiểm tra cột move_in_confirmed tồn tại trong DB thực (tương thích schema cũ)
        boolean hasMoveIn = columnExists(ctx.getOltpConn(),
                                         "apartment_rental", "contracts", "move_in_confirmed");

        String sql =
            "SELECT c.contract_id, c.apt_id, c.tenant_id, c.owner_id, " +
            "       c.rental_type, c.status, c.monthly_rent, c.deposit_amount, " +
            "       c.platform_fee, c.total_days, " +
            (hasMoveIn ? "c.move_in_confirmed, " : "FALSE AS move_in_confirmed, ") +
            "       c.created_at, " +
            "       DATEDIFF(c.created_at, a.created_at) AS days_to_rent, " +
            "       a.district, a.city " +
            "FROM apartment_rental.contracts c " +
            "JOIN apartment_rental.apartments a ON c.apt_id = a.apt_id " +
            "WHERE c.contract_id > ? OR c.updated_at > ? " +
            "ORDER BY c.contract_id ASC";
        try (PreparedStatement ps = ctx.getOltpConn().prepareStatement(sql)) {
            ps.setInt(1, lastMaxId);
            ps.setTimestamp(2, lastRunAt);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                extracted.add(new Object[]{
                    rs.getInt("contract_id"),       // 0
                    rs.getInt("apt_id"),             // 1
                    rs.getInt("tenant_id"),          // 2
                    rs.getInt("owner_id"),           // 3
                    rs.getString("rental_type"),     // 4
                    rs.getString("status"),          // 5
                    rs.getLong("monthly_rent"),      // 6
                    rs.getLong("deposit_amount"),    // 7
                    rs.getLong("platform_fee"),      // 8
                    rs.getInt("total_days"),         // 9
                    rs.getBoolean("move_in_confirmed"), // 10
                    rs.getTimestamp("created_at"),   // 11
                    rs.getObject("days_to_rent"),    // 12
                    rs.getString("district"),        // 13
                    rs.getString("city")             // 14
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

        // FIX v13: bọc toàn bộ load() trong try-finally để đảm bảo:
        // 1. foreign_key_checks luôn được bật lại kể cả khi exception
        // 2. watermark không mãi mãi ở trạng thái "running" khi load() thất bại
        dwh.createStatement().execute("SET SESSION foreign_key_checks = 0");
        try {
            // ── Preload toàn bộ lookup maps vào memory (3 queries thay vì N×3) ──
            Map<Integer, Integer> aptKeyMap = new HashMap<>();
            try (Statement st = dwh.createStatement();
                 ResultSet rs = st.executeQuery(
                    "SELECT apt_id, apt_key FROM cc_dwh.dim_apartment WHERE is_current=TRUE")) {
                while (rs.next()) aptKeyMap.put(rs.getInt(1), rs.getInt(2));
            }
            Map<Integer, Integer> userKeyMap = new HashMap<>();
            try (Statement st = dwh.createStatement();
                 ResultSet rs = st.executeQuery(
                    "SELECT user_id, user_key FROM cc_dwh.dim_user WHERE is_current=TRUE")) {
                while (rs.next()) userKeyMap.put(rs.getInt(1), rs.getInt(2));
            }
            Map<String, Integer> locationMap = new HashMap<>();
            try (Statement st = dwh.createStatement();
                 ResultSet rs = st.executeQuery(
                    "SELECT location_key, COALESCE(district,'Không xác định'), COALESCE(city,'Hà Nội') " +
                    "FROM cc_dwh.dim_location")) {
                while (rs.next()) locationMap.put(rs.getString(2) + "|" + rs.getString(3), rs.getInt(1));
            }

            // ── Batch INSERT / UPSERT ────────────────────────────────────────────
            String sql =
                "INSERT INTO cc_dwh.fact_contracts " +
                "(contract_id,date_key,apt_key,tenant_key,owner_key,location_key," +
                " rental_type,status,monthly_rent,deposit_amount,platform_fee," +
                " contract_days,move_in_confirmed,days_to_rent,etl_loaded_at) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) " +
                "ON DUPLICATE KEY UPDATE status=VALUES(status), etl_loaded_at=VALUES(etl_loaded_at)";

            int maxId = 0;
            try (PreparedStatement ps = dwh.prepareStatement(sql)) {
                int n = 0;
                for (Object[] row : extracted) {
                    int contractId  = (int) row[0];
                    int aptKey      = aptKeyMap.getOrDefault((int) row[1], 1);
                    int tenantKey   = userKeyMap.getOrDefault((int) row[2], 1);
                    int ownerKey    = userKeyMap.getOrDefault((int) row[3], 1);
                    String locKey   = nvl((String) row[13], "Không xác định") + "|" + nvl((String) row[14], "Hà Nội");
                    int locationKey = locationMap.getOrDefault(locKey, 1);
                    int dateKey     = toDateKey((Timestamp) row[11]);

                    ps.setInt(1, contractId);
                    ps.setInt(2, dateKey);
                    ps.setInt(3, aptKey);
                    ps.setInt(4, tenantKey);
                    ps.setInt(5, ownerKey);
                    ps.setInt(6, locationKey);
                    ps.setString(7,  (String) row[4]);
                    ps.setString(8,  (String) row[5]);
                    ps.setLong(9,    (long)   row[6]);
                    ps.setLong(10,   (long)   row[7]);
                    ps.setLong(11,   (long)   row[8]);
                    ps.setInt(12,    (int)    row[9]);
                    ps.setBoolean(13, (boolean) row[10]);
                    if (row[12] != null) ps.setInt(14, ((Number) row[12]).intValue());
                    else                 ps.setNull(14, Types.INTEGER);
                    ps.setTimestamp(15, now);
                    ps.addBatch();
                    if (contractId > maxId) maxId = contractId;
                    if (++n % BATCH == 0) { ps.executeBatch(); ps.clearBatch(); }
                }
                ps.executeBatch();
                rowsProcessed = extracted.size();
            }
            watermark.updateSuccess(getJobName(), now, maxId, rowsProcessed);
        } finally {
            // FIX v13: luôn bật lại FK dù load() thành công hay thất bại
            try { dwh.createStatement().execute("SET SESSION foreign_key_checks = 1"); } catch (Exception ignored) {}
        }
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private int toDateKey(Timestamp ts) {
        if (ts == null) return 20200101;
        java.util.Calendar c = java.util.Calendar.getInstance();
        c.setTime(ts);
        return c.get(java.util.Calendar.YEAR) * 10000
             + (c.get(java.util.Calendar.MONTH) + 1) * 100
             + c.get(java.util.Calendar.DAY_OF_MONTH);
    }

    private String nvl(String v, String def) { return v != null ? v : def; }

    /** Kiểm tra cột có tồn tại trong DB không (tương thích schema cũ). */
    private boolean columnExists(Connection conn, String schema, String table, String column) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM information_schema.COLUMNS " +
                "WHERE TABLE_SCHEMA=? AND TABLE_NAME=? AND COLUMN_NAME=?")) {
            ps.setString(1, schema);
            ps.setString(2, table);
            ps.setString(3, column);
            ResultSet rs = ps.executeQuery();
            return rs.next() && rs.getInt(1) > 0;
        } catch (Exception e) { return false; }
    }
}
