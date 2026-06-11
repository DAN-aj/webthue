package com.rental.etl.fact;

import com.rental.etl.core.*;

import java.sql.*;
import java.time.Instant;
import java.util.*;

/**
 * FactPaymentLoader v13
 * Fix streaming thực sự trên MySQL:
 *  - Tạo connection OLTP riêng với useCursorFetch=true + defaultFetchSize=500
 *    → driver thực sự stream từng cursor, không buffer toàn bộ vào RAM
 *  - DWH connection tắt autoCommit, commit mỗi COMMIT_EVERY rows
 *    → tránh transaction quá lớn làm InnoDB chậm
 *  - BATCH_SIZE=1000, COMMIT_EVERY=10000 — cân bằng tốc độ và bộ nhớ
 */
public class FactPaymentLoader implements ETLJob {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.fact_payments (" +
        "  payment_key    INT AUTO_INCREMENT PRIMARY KEY," +
        "  payment_id     INT           NOT NULL UNIQUE COMMENT 'NK từ OLTP'," +
        "  date_key       INT           NOT NULL," +
        "  contract_key   INT           NULL," +
        "  apt_key        INT           NOT NULL," +
        "  payer_key      INT           NOT NULL," +
        "  location_key   INT           NOT NULL," +
        "  payment_type   VARCHAR(20)   NOT NULL," +
        "  payment_method VARCHAR(20)   NOT NULL," +
        "  status         VARCHAR(20)   NOT NULL," +
        "  amount         DECIMAL(15,0) NOT NULL," +
        "  platform_share DECIMAL(15,0) NOT NULL," +
        "  etl_loaded_at  TIMESTAMP     NOT NULL," +
        "  INDEX idx_fp_date   (date_key)," +
        "  INDEX idx_fp_status (status)" +
        ") ENGINE=InnoDB";

    private static final int BATCH_SIZE   = 1000;
    private static final int COMMIT_EVERY = 10_000;

    private final ETLContext ctx;
    private final WatermarkHelper watermark;
    private int rowsProcessed = 0;

    public FactPaymentLoader(ETLContext ctx) {
        this.ctx       = ctx;
        this.watermark = new WatermarkHelper(ctx.getDwhConn());
    }

    @Override public String getJobName()      { return "FactPaymentLoader"; }
    @Override public int    getRowsProcessed(){ return rowsProcessed; }
    @Override public void   transform()       {}

    @Override
    public void extract() throws Exception {
        ctx.getDwhConn().createStatement().execute(CREATE_TABLE);
        watermark.markRunning(getJobName());
    }

    @Override
    public void load() throws Exception {
        Connection dwh  = ctx.getDwhConn();
        Timestamp  now  = Timestamp.from(Instant.now());

        int       lastMaxId  = watermark.getLastMaxId(getJobName());
        Timestamp lastRunAt  = watermark.getLastRunAt(getJobName());
        System.out.printf("[FactPaymentLoader] Watermark: lastMaxId=%d, lastRunAt=%s%n",
                lastMaxId, lastRunAt);

        // ── Preload lookup maps ────────────────────────────────────────────
        dwh.createStatement().execute("SET SESSION foreign_key_checks = 0");
        Map<Integer, Integer> contractKeyMap = loadIntMap(dwh,
                "SELECT contract_id, contract_key FROM cc_dwh.fact_contracts");
        Map<Integer, Integer> aptKeyMap      = loadIntMap(dwh,
                "SELECT apt_id, apt_key FROM cc_dwh.dim_apartment WHERE is_current=TRUE");
        Map<Integer, Integer> userKeyMap     = loadIntMap(dwh,
                "SELECT user_id, user_key FROM cc_dwh.dim_user WHERE is_current=TRUE");
        Map<String,  Integer> locationKeyMap = loadLocMap(dwh);
        System.out.printf("[FactPaymentLoader] Maps: contracts=%d, apts=%d, users=%d, locations=%d%n",
                contractKeyMap.size(), aptKeyMap.size(), userKeyMap.size(), locationKeyMap.size());

        // ── ensureDateKeys (pass riêng, nhỏ) ──────────────────────────────
        Set<Integer> neededDates = collectDistinctDates(ctx.getOltpConn(), lastMaxId, lastRunAt);
        ensureDateKeys(dwh, neededDates);
        System.out.printf("[FactPaymentLoader] ensureDateKeys: %d dates%n", neededDates.size());

        // ── Streaming connection riêng cho OLTP ───────────────────────────
        // useCursorFetch=true + defaultFetchSize → MySQL server-side cursor thực sự
        String streamUrl = buildStreamUrl();
        System.out.println("[FactPaymentLoader] Streaming URL: " + streamUrl);

        // ── DWH: tắt autoCommit để manual commit theo batch ───────────────
        // FIX v13: bọc toàn bộ block trong try-finally để đảm bảo autoCommit=true
        // và foreign_key_checks=1 luôn được khôi phục, kể cả khi exception xảy ra.
        // Nếu không có finally, connection trả về pool ở trạng thái sai →
        // mọi job sau đó chạy trên connection này sẽ hoạt động không đúng.
        dwh.setAutoCommit(false);

        String selectSql =
            "SELECT p.payment_id, p.contract_id, p.payer_id, p.amount," +
            "  p.payment_type, p.payment_method, p.status," +
            "  COALESCE(p.paid_date, p.created_at) AS effective_date," +
            "  c.apt_id, a.district, a.city " +
            "FROM apartment_rental.payments p " +
            "LEFT JOIN apartment_rental.contracts  c ON p.contract_id = c.contract_id " +
            "LEFT JOIN apartment_rental.apartments a ON c.apt_id = a.apt_id " +
            "WHERE (p.payment_id > ? OR p.created_at > ?) " +
            "ORDER BY p.payment_id ASC";

        String insertSql =
            "INSERT INTO cc_dwh.fact_payments " +
            "(payment_id,date_key,contract_key,apt_key,payer_key,location_key," +
            " payment_type,payment_method,status,amount,platform_share,etl_loaded_at) " +
            "VALUES (?,?,?,?,?,?,?,?,?,?,?,?) " +
            "ON DUPLICATE KEY UPDATE status=VALUES(status), etl_loaded_at=VALUES(etl_loaded_at)";

        int maxId   = lastMaxId;
        int batched = 0;
        int skipped = 0;

        try {
            try (Connection streamConn = DriverManager.getConnection(streamUrl, getDbUser(), getDbPass());
                 PreparedStatement sel = streamConn.prepareStatement(
                         selectSql, ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
                 PreparedStatement ins = dwh.prepareStatement(insertSql)) {

                sel.setFetchSize(BATCH_SIZE); // cursor fetch size
                sel.setInt(1, lastMaxId);
                sel.setTimestamp(2, lastRunAt);

                ResultSet rs = sel.executeQuery();
                while (rs.next()) {
                    int paymentId = rs.getInt("payment_id");
                    int payerId   = rs.getInt("payer_id");

                    if (!userKeyMap.containsKey(payerId)) { skipped++; continue; }

                    Integer contractId  = (Integer) rs.getObject("contract_id");
                    Integer contractKey = contractId != null ? contractKeyMap.get(contractId) : null;
                    Integer aptId       = (Integer) rs.getObject("apt_id");
                    int aptKey          = aptId != null ? aptKeyMap.getOrDefault(aptId, 1) : 1;
                    int payerKey        = userKeyMap.getOrDefault(payerId, 1);

                    String district = rs.getString("district");
                    String city     = rs.getString("city");
                    String locKey   = (district != null ? district : "Không xác định")
                                    + "|" + (city != null ? city : "Hà Nội");
                    int locationKey = locationKeyMap.getOrDefault(locKey, 1);

                    Timestamp effDate = rs.getTimestamp("effective_date");
                    int dateKey       = toDateKey(effDate);
                    long amount       = rs.getLong("amount");

                    ins.setInt(1, paymentId);
                    ins.setInt(2, dateKey);
                    if (contractKey != null) ins.setInt(3, contractKey); else ins.setNull(3, Types.INTEGER);
                    ins.setInt(4, aptKey);
                    ins.setInt(5, payerKey);
                    ins.setInt(6, locationKey);
                    ins.setString(7,  rs.getString("payment_type"));
                    ins.setString(8,  rs.getString("payment_method"));
                    ins.setString(9,  rs.getString("status"));
                    ins.setLong(10,   amount);
                    ins.setLong(11,   Math.round(amount * 0.05));
                    ins.setTimestamp(12, now);
                    ins.addBatch();

                    if (paymentId > maxId) maxId = paymentId;
                    batched++;

                    if (batched % BATCH_SIZE == 0) {
                        ins.executeBatch();
                        ins.clearBatch();
                    }
                    if (batched % COMMIT_EVERY == 0) {
                        dwh.commit();
                        System.out.printf("[FactPaymentLoader] %,d rows committed...%n", batched);
                    }
                }
                // FIX v13: flush phần còn lại trong batch — kể cả khi batched là bội số chính xác
                // của BATCH_SIZE (batch vừa được executeBatch() nhưng chưa commit lần cuối).
                // Điều kiện cũ `if (batched % BATCH_SIZE != 0)` bỏ sót trường hợp này.
                // Cách an toàn nhất: luôn gọi executeBatch() + commit() sau vòng lặp.
                // executeBatch() trên batch rỗng là no-op với JDBC, không gây lỗi.
                ins.executeBatch();
                dwh.commit();
            }
        } finally {
            // FIX v13: luôn khôi phục trạng thái connection, kể cả khi exception
            try { dwh.setAutoCommit(true); } catch (Exception ignored) {}
            try { dwh.createStatement().execute("SET SESSION foreign_key_checks = 1"); } catch (Exception ignored) {}
        }

        watermark.updateSuccess(getJobName(), now, maxId, batched);
        rowsProcessed = batched;
        System.out.printf("[FactPaymentLoader] Xong: %,d inserted, %d skipped%n", batched, skipped);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private String buildStreamUrl() {
        String host = System.getenv().getOrDefault("DB_HOST", "localhost");
        String port = System.getenv().getOrDefault("DB_PORT", "3306");
        return "jdbc:mysql://" + host + ":" + port + "/apartment_rental"
             + "?useSSL=false&serverTimezone=Asia/Ho_Chi_Minh"
             + "&characterEncoding=UTF-8&allowPublicKeyRetrieval=true"
             + "&useCursorFetch=true"          // server-side cursor
             + "&defaultFetchSize=" + BATCH_SIZE
             + "&socketTimeout=1800000";       // 30 phút
    }

    private String getDbUser() { return System.getenv().getOrDefault("DB_USER", "root"); }
    private String getDbPass() { return System.getenv().getOrDefault("DB_PASS", "1234"); }

    private int toDateKey(Timestamp ts) {
        if (ts == null) return 20200101;
        Calendar c = Calendar.getInstance();
        c.setTime(ts);
        return c.get(Calendar.YEAR) * 10000
             + (c.get(Calendar.MONTH) + 1) * 100
             + c.get(Calendar.DAY_OF_MONTH);
    }

    private Set<Integer> collectDistinctDates(Connection oltp, int lastMaxId, Timestamp lastRunAt)
            throws SQLException {
        Set<Integer> set = new HashSet<>();
        String sql = "SELECT DISTINCT DATE_FORMAT(COALESCE(paid_date,created_at),'%Y%m%d') " +
                     "FROM apartment_rental.payments WHERE payment_id > ? OR created_at > ?";
        try (PreparedStatement ps = oltp.prepareStatement(sql)) {
            ps.setInt(1, lastMaxId); ps.setTimestamp(2, lastRunAt);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) { String s = rs.getString(1); if (s != null) set.add(Integer.parseInt(s)); }
        }
        return set;
    }

    private void ensureDateKeys(Connection dwh, Set<Integer> dateKeys) throws SQLException {
        if (dateKeys.isEmpty()) return;
        Set<Integer> existing = new HashSet<>();
        String inClause = String.join(",", Collections.nCopies(dateKeys.size(), "?"));
        try (PreparedStatement ps = dwh.prepareStatement(
                "SELECT date_key FROM cc_dwh.dim_time WHERE date_key IN (" + inClause + ")")) {
            int i = 1; for (int dk : dateKeys) ps.setInt(i++, dk);
            ResultSet rs = ps.executeQuery(); while (rs.next()) existing.add(rs.getInt(1));
        }
        Set<Integer> missing = new HashSet<>(dateKeys); missing.removeAll(existing);
        if (missing.isEmpty()) return;
        String ins = "INSERT IGNORE INTO cc_dwh.dim_time " +
            "(date_key,full_date,day_of_week,day_name,week_of_year,month_num,month_name,quarter,year_num,is_weekend,is_holiday) " +
            "VALUES (?,?,?,?,?,?,?,?,?,?,?)";
        String[] dn = {"","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"};
        String[] mn = {"","January","February","March","April","May","June","July","August","September","October","November","December"};
        try (PreparedStatement ps = dwh.prepareStatement(ins)) {
            for (int dk : missing) {
                int y=dk/10000, m=(dk/100)%100, d=dk%100;
                Calendar cal=Calendar.getInstance(); cal.set(y,m-1,d);
                int dow=cal.get(Calendar.DAY_OF_WEEK); int sdow=(dow==1)?7:(dow-1);
                ps.setInt(1,dk); ps.setString(2,String.format("%04d-%02d-%02d",y,m,d));
                ps.setInt(3,sdow); ps.setString(4,dn[sdow]);
                ps.setInt(5,cal.get(Calendar.WEEK_OF_YEAR)); ps.setInt(6,m);
                ps.setString(7,mn[m]); ps.setInt(8,(m-1)/3+1); ps.setInt(9,y);
                ps.setBoolean(10,sdow>=6); ps.setBoolean(11,false); ps.addBatch();
            }
            ps.executeBatch();
        }
        dwh.commit();
    }

    private Map<Integer,Integer> loadIntMap(Connection dwh, String sql) throws SQLException {
        Map<Integer,Integer> map = new HashMap<>();
        try (Statement st = dwh.createStatement(); ResultSet rs = st.executeQuery(sql))
        { while (rs.next()) map.put(rs.getInt(1), rs.getInt(2)); }
        return map;
    }

    private Map<String,Integer> loadLocMap(Connection dwh) throws SQLException {
        Map<String,Integer> map = new HashMap<>();
        try (Statement st = dwh.createStatement();
             ResultSet rs = st.executeQuery("SELECT district,city,location_key FROM cc_dwh.dim_location"))
        { while (rs.next()) map.put(rs.getString(1)+"|"+rs.getString(2), rs.getInt(3)); }
        return map;
    }
}
