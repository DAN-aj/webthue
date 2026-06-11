package com.rental.servlet.admin;

import com.google.gson.Gson;
import com.rental.dao.ApartmentEditRequestDAO;
import com.rental.dao.ReviewDAO;
import com.rental.util.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.*;

/**
 * AdminDashboardServlet v18
 *
 * PERF FIX v18 — PARALLEL QUERIES:
 *  - 7 nhóm query trước chạy tuần tự → tổng ~20s
 *  - Nay chạy song song bằng CompletableFuture + dedicated thread pool
 *  - Mỗi task tự lấy Connection riêng từ HikariCP pool
 *  - Tổng thời gian ≈ max(task chậm nhất) thay vì sum tất cả
 *  - Timeout toàn bộ: 5s, fallback về default nếu quá hạn
 *  - Logic SQL, index hints giữ nguyên từ v17
 */
public class AdminDashboardServlet extends HttpServlet {

    private final Gson gson = new Gson();
    private final ApartmentEditRequestDAO editRequestDAO = new ApartmentEditRequestDAO();
    private final ReviewDAO reviewDAO = new ReviewDAO();

    // Pool riêng cho dashboard queries — không block Tomcat request thread
    private static final ExecutorService DASH_POOL =
        new ThreadPoolExecutor(
            8, 16,
            30L, TimeUnit.SECONDS,
            new LinkedBlockingQueue<>(64),
            r -> { Thread t = new Thread(r, "dash-query"); t.setDaemon(true); return t; },
            new ThreadPoolExecutor.CallerRunsPolicy()
        );

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        long t0 = System.currentTimeMillis();

        String fromDate = req.getParameter("fromDate");
        String toDate   = req.getParameter("toDate");
        if (fromDate == null || fromDate.isEmpty())
            fromDate = LocalDate.now().minusMonths(11).withDayOfMonth(1).toString();
        if (toDate == null || toDate.isEmpty())
            toDate = LocalDate.now().toString();

        final String fd = fromDate, td = toDate;

        req.setAttribute("fromDate",   fromDate);
        req.setAttribute("toDate",     toDate);
        req.setAttribute("moveInRate", 0.0);

        // Defaults
        req.setAttribute("totalUsers", 0);           req.setAttribute("totalApartments", 0);
        req.setAttribute("approvedApartments", 0);   req.setAttribute("pendingApartments", 0);
        req.setAttribute("activeContracts", 0);      req.setAttribute("totalContracts", 0);
        req.setAttribute("totalRevenue",  java.math.BigDecimal.ZERO);
        req.setAttribute("periodRevenue", java.math.BigDecimal.ZERO);
        req.setAttribute("successPayments", 0);      req.setAttribute("pendingPayments", 0);
        req.setAttribute("avgDaysToRent", 0.0);      req.setAttribute("overdueContracts", 0);
        req.setAttribute("topApartments", new ArrayList<>());
        req.setAttribute("recentContractsJson",   "[]");
        req.setAttribute("revenueByMonthJson",    "{\"labels\":[],\"data\":[]}");
        req.setAttribute("revenueByDistrictJson", "{\"labels\":[],\"data\":[]}");
        req.setAttribute("contractsByMonthJson",  "{\"labels\":[],\"data\":[]}");
        req.setAttribute("occupancyJson",         "{\"labels\":[],\"data\":[]}");
        req.setAttribute("rentalTypeJson",        "{\"labels\":[],\"data\":[]}");
        req.setAttribute("contractStatusJson",    "{\"labels\":[],\"data\":[]}");
        req.setAttribute("avgAptPerOwnerJson",    "{\"labels\":[],\"data\":[]}");

        try {
            // ── Bước 1: DWH check (nhanh ~5ms, chạy trước để quyết định data source) ──
            long t1 = System.currentTimeMillis();
            boolean dwhFresh;
            String  lastRun;
            try (Connection conn = DBConnection.getConnection()) {
                try (Statement s = conn.createStatement()) {
                    s.execute("SET SESSION MAX_EXECUTION_TIME=8000");
                } catch (Exception ignored) {}
                dwhFresh = isDwhFresh(conn);
                lastRun  = getLastEtlRun(conn);
            }
            req.setAttribute("dataSource", dwhFresh ? "DWH" : "OLTP");
            req.setAttribute("lastEtlRun", lastRun);
            log("[DASH] dwhCheck: " + (System.currentTimeMillis() - t1) + "ms | fresh=" + dwhFresh);

            // ── Bước 2: Tất cả queries còn lại chạy SONG SONG ─────────────────────
            final boolean useDwh = dwhFresh;

            // Task 1: Counts
            CompletableFuture<Void> fCounts = CompletableFuture.runAsync(() -> {
                try (Connection conn = DBConnection.getConnection()) {
                    loadCounts(conn, req);
                } catch (Exception e) { log("[DASH] counts err: " + e.getMessage()); }
            }, DASH_POOL);

            // Task 2: Revenue
            CompletableFuture<Void> fRevenue = CompletableFuture.runAsync(() -> {
                try (Connection conn = DBConnection.getConnection()) {
                    if (useDwh) loadRevenueDwh(conn, req, fd, td);
                    else        loadRevenueOltp(conn, req, fd, td);
                } catch (Exception e) { log("[DASH] revenue err: " + e.getMessage()); }
            }, DASH_POOL);

            // Task 3: Overdue
            CompletableFuture<Void> fOverdue = CompletableFuture.runAsync(() -> {
                try (Connection conn = DBConnection.getConnection()) {
                    loadOverdue(conn, req);
                } catch (Exception e) { log("[DASH] overdue err: " + e.getMessage()); }
            }, DASH_POOL);

            // Task 4: Heavy charts (revenue/district/occupancy — query nặng nhất)
            CompletableFuture<Void> fCharts = CompletableFuture.runAsync(() -> {
                try (Connection conn = DBConnection.getConnection()) {
                    if (useDwh) loadChartsDwh(conn, req);
                    else        loadChartsOltp(conn, req);
                } catch (Exception e) { log("[DASH] charts err: " + e.getMessage()); }
            }, DASH_POOL);

            // Task 5: Top apartments + avgDaysToRent
            CompletableFuture<Void> fTop = CompletableFuture.runAsync(() -> {
                try (Connection conn = DBConnection.getConnection()) {
                    if (useDwh) loadTopDwh(conn, req);
                    else        loadTopOltp(conn, req);
                } catch (Exception e) { log("[DASH] top err: " + e.getMessage()); }
            }, DASH_POOL);

            // Task 6: Recent contracts (PK DESC scan, rất nhanh)
            CompletableFuture<Void> fRecent = CompletableFuture.runAsync(() -> {
                try (Connection conn = DBConnection.getConnection()) {
                    loadRecentContracts(conn, req);
                } catch (Exception e) { log("[DASH] recent err: " + e.getMessage()); }
            }, DASH_POOL);

            // Task 7: Small charts (bảng nhỏ)
            CompletableFuture<Void> fSmall = CompletableFuture.runAsync(() -> {
                try (Connection conn = DBConnection.getConnection()) {
                    loadChartsOltpSmall(conn, req);
                } catch (Exception e) { log("[DASH] small err: " + e.getMessage()); }
            }, DASH_POOL);

            // Chờ tất cả — timeout 5s, sau đó serve dữ liệu partial
            CompletableFuture.allOf(fCounts, fRevenue, fOverdue, fCharts, fTop, fRecent, fSmall)
                .get(5, TimeUnit.SECONDS);

        } catch (TimeoutException e) {
            log("[DASH] WARN: timeout 5s — serving partial data");
        } catch (Exception e) {
            log("[DASH] ERROR: " + e.getMessage());
        }

        log("[DASH] TOTAL: " + (System.currentTimeMillis() - t0) + "ms");
        req.setAttribute("pendingEditCount",   editRequestDAO.countPending());
        req.setAttribute("pendingReviewCount", reviewDAO.countByStatus("pending"));
        req.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(req, resp);
    }

    // ── DWH fresh check: ngưỡng 48h ──────────────────────────────────────────
    private boolean isDwhFresh(Connection conn) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT last_run_at FROM cc_dwh.etl_watermark " +
                "WHERE job_name='AggDailyRevenueJob'");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next() && rs.getTimestamp(1) != null) {
                long hoursAgo = (System.currentTimeMillis() - rs.getTimestamp(1).getTime()) / 3_600_000;
                return hoursAgo < 48;
            }
        } catch (Exception e) { log("[DASH] isDwhFresh err: " + e.getMessage()); }
        return false;
    }

    private String getLastEtlRun(Connection conn) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT MAX(last_run_at) FROM cc_dwh.etl_watermark");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next() && rs.getString(1) != null) return rs.getString(1);
        } catch (Exception ignored) {}
        return "Chưa chạy";
    }

    // ── Counts ───────────────────────────────────────────────────────────────
    private void loadCounts(Connection conn, HttpServletRequest req) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM users WHERE role='user'");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) req.setAttribute("totalUsers", rs.getInt(1));
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT status, COUNT(*) AS c FROM apartments GROUP BY status");
             ResultSet rs = ps.executeQuery()) {
            int total = 0, approved = 0, pending = 0;
            while (rs.next()) {
                int c = rs.getInt("c"); total += c;
                String s = rs.getString("status");
                if ("approved".equals(s)) approved = c;
                if ("pending".equals(s))  pending  = c;
            }
            req.setAttribute("totalApartments",    total);
            req.setAttribute("approvedApartments", approved);
            req.setAttribute("pendingApartments",  pending);
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT status, COUNT(*) AS c FROM contracts GROUP BY status");
             ResultSet rs = ps.executeQuery()) {
            int total = 0, active = 0;
            while (rs.next()) {
                int c = rs.getInt("c"); total += c;
                if ("active".equals(rs.getString("status"))) active = c;
            }
            req.setAttribute("totalContracts",  total);
            req.setAttribute("activeContracts", active);
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT status, COUNT(*) AS c FROM payments GROUP BY status");
             ResultSet rs = ps.executeQuery()) {
            int success = 0, pending = 0;
            while (rs.next()) {
                String s = rs.getString("status");
                if ("success".equals(s)) success = rs.getInt("c");
                if ("pending".equals(s)) pending  = rs.getInt("c");
            }
            req.setAttribute("successPayments", success);
            req.setAttribute("pendingPayments",  pending);
        }
    }

    // ── Revenue DWH ──────────────────────────────────────────────────────────
    private void loadRevenueDwh(Connection conn, HttpServletRequest req,
                                String fromDate, String toDate) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT SUM(total_platform_fee) AS total, " +
                "SUM(CASE WHEN revenue_date BETWEEN ? AND ? THEN total_platform_fee ELSE 0 END) AS period " +
                "FROM cc_dwh.agg_daily_revenue")) {
            ps.setString(1, fromDate); ps.setString(2, toDate);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                req.setAttribute("totalRevenue",  rs.getBigDecimal("total"));
                req.setAttribute("periodRevenue", rs.getBigDecimal("period"));
            }
        } catch (Exception e) {
            log("[DASH] revenueDwh err: " + e.getMessage());
            try { loadRevenueOltp(conn, req, fromDate, toDate); } catch (Exception ignored) {}
        }
    }

    // ── Revenue OLTP ─────────────────────────────────────────────────────────
    private void loadRevenueOltp(Connection conn, HttpServletRequest req,
                                 String fromDate, String toDate) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COALESCE(SUM(platform_fee),0) FROM contracts " +
                "WHERE status IN ('active','expired')");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) req.setAttribute("totalRevenue", rs.getBigDecimal(1));
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COALESCE(SUM(platform_fee),0) FROM contracts " +
                "WHERE status IN ('active','expired') " +
                "AND created_at BETWEEN ? AND ?")) {
            ps.setString(1, fromDate + " 00:00:00");
            ps.setString(2, toDate   + " 23:59:59");
            ResultSet rs = ps.executeQuery();
            if (rs.next()) req.setAttribute("periodRevenue", rs.getBigDecimal(1));
        }
    }

    // ── Overdue ───────────────────────────────────────────────────────────────
    private void loadOverdue(Connection conn, HttpServletRequest req) {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM contracts " +
                "WHERE status='pending' AND created_at < DATE_SUB(NOW(), INTERVAL 7 DAY)");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) req.setAttribute("overdueContracts", rs.getInt(1));
        } catch (Exception e) { log("[DASH] overdue err: " + e.getMessage()); }
    }

    // ── Charts DWH ───────────────────────────────────────────────────────────
    private void loadChartsDwh(Connection conn, HttpServletRequest req) {
        req.setAttribute("revenueByMonthJson", toJson(conn,
            "SELECT DATE_FORMAT(revenue_date,'%Y-%m'), SUM(total_platform_fee) " +
            "FROM cc_dwh.agg_daily_revenue " +
            "WHERE revenue_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) " +
            "GROUP BY 1 ORDER BY 1"));

        req.setAttribute("revenueByDistrictJson", toJson(conn,
            "SELECT district, SUM(total_platform_fee) " +
            "FROM cc_dwh.agg_daily_revenue " +
            "GROUP BY district ORDER BY 2 DESC LIMIT 8"));

        req.setAttribute("contractsByMonthJson", toJson(conn,
            "SELECT DATE_FORMAT(revenue_date,'%Y-%m'), SUM(contract_count) " +
            "FROM cc_dwh.agg_daily_revenue " +
            "WHERE revenue_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) " +
            "GROUP BY 1 ORDER BY 1"));

        req.setAttribute("occupancyJson", toJson(conn,
            "SELECT district, occupancy_rate " +
            "FROM cc_dwh.agg_occupancy_rate " +
            "WHERE calc_date=(SELECT MAX(calc_date) FROM cc_dwh.agg_occupancy_rate) " +
            "ORDER BY 2 DESC LIMIT 10"));
    }

    // ── Charts OLTP ──────────────────────────────────────────────────────────
    private void loadChartsOltp(Connection conn, HttpServletRequest req) {
        req.setAttribute("revenueByMonthJson", toJson(conn,
            "SELECT DATE_FORMAT(created_at,'%Y-%m'), ROUND(SUM(platform_fee),0) " +
            "FROM contracts " +
            "WHERE status IN ('active','expired') " +
            "AND created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) " +
            "GROUP BY 1 ORDER BY 1"));

        req.setAttribute("revenueByDistrictJson", toJson(conn,
            "SELECT COALESCE(a.district,'Khác'), ROUND(SUM(c.platform_fee),0) " +
            "FROM apartments a " +
            "JOIN contracts c ON c.apt_id = a.apt_id " +
            "  AND c.status IN ('active','expired') " +
            "GROUP BY a.district ORDER BY 2 DESC LIMIT 8"));

        req.setAttribute("contractsByMonthJson", toJson(conn,
            "SELECT DATE_FORMAT(created_at,'%Y-%m'), COUNT(*) " +
            "FROM contracts " +
            "WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) " +
            "GROUP BY 1 ORDER BY 1"));

        req.setAttribute("occupancyJson", toJson(conn,
            "SELECT COALESCE(a.district,'Khác'), " +
            "ROUND(COUNT(DISTINCT c.contract_id)*100.0/NULLIF(COUNT(DISTINCT a.apt_id),0),1) " +
            "FROM apartments a " +
            "LEFT JOIN contracts c ON a.apt_id=c.apt_id AND c.status='active' " +
            "WHERE a.status='approved' " +
            "GROUP BY a.district ORDER BY 2 DESC LIMIT 10"));
    }

    // ── Small charts ─────────────────────────────────────────────────────────
    private void loadChartsOltpSmall(Connection conn, HttpServletRequest req) {
        req.setAttribute("rentalTypeJson", toJson(conn,
            "SELECT COALESCE(rental_type,'Khác'), COUNT(*) " +
            "FROM contracts GROUP BY 1"));

        req.setAttribute("contractStatusJson", toJson(conn,
            "SELECT status, COUNT(*) FROM contracts GROUP BY 1"));

        req.setAttribute("avgAptPerOwnerJson", toJson(conn,
            "SELECT COALESCE(district,'Khác'), " +
            "ROUND(COUNT(*)/NULLIF(COUNT(DISTINCT owner_id),0),1) " +
            "FROM apartments WHERE status='approved' " +
            "GROUP BY district ORDER BY 2 DESC LIMIT 8"));
    }

    // ── Top DWH ──────────────────────────────────────────────────────────────
    private void loadTopDwh(Connection conn, HttpServletRequest req) {
        List<String[]> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT da.title, COUNT(fc.contract_key) AS cnt, dl.district " +
                "FROM cc_dwh.fact_contracts fc " +
                "JOIN cc_dwh.dim_apartment da ON fc.apt_key=da.apt_key AND da.is_current=1 " +
                "JOIN cc_dwh.dim_location  dl ON fc.location_key=dl.location_key " +
                "GROUP BY fc.apt_key, da.title, dl.district ORDER BY cnt DESC LIMIT 5");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                list.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3)});
        } catch (Exception e) {
            log("[DASH] topDwh err: " + e.getMessage());
            try { loadTopOltp(conn, req); return; } catch (Exception ignored) {}
        }
        req.setAttribute("topApartments", list);
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT AVG(days_to_rent) FROM cc_dwh.fact_contracts WHERE days_to_rent>0");
             ResultSet rs = ps.executeQuery()) {
            req.setAttribute("avgDaysToRent", rs.next() ? rs.getDouble(1) : 0.0);
        } catch (Exception ignored) {}
    }

    // ── Top OLTP ─────────────────────────────────────────────────────────────
    private void loadTopOltp(Connection conn, HttpServletRequest req) throws SQLException {
        List<String[]> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT a.title, t.cnt, a.district " +
                "FROM ( " +
                "  SELECT apt_id, COUNT(*) AS cnt FROM contracts " +
                "  GROUP BY apt_id ORDER BY cnt DESC LIMIT 5 " +
                ") t JOIN apartments a ON a.apt_id = t.apt_id " +
                "ORDER BY t.cnt DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                list.add(new String[]{rs.getString(1), rs.getString(2), rs.getString(3)});
        }
        req.setAttribute("topApartments", list);
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT AVG(DATEDIFF(updated_at,created_at)) FROM contracts " +
                "WHERE status IN ('active','expired') LIMIT 5000");
             ResultSet rs = ps.executeQuery()) {
            req.setAttribute("avgDaysToRent", rs.next() ? rs.getDouble(1) : 0.0);
        }
    }

    // ── Recent contracts ─────────────────────────────────────────────────────
    private void loadRecentContracts(Connection conn, HttpServletRequest req) {
        List<Map<String,Object>> list = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT c.contract_id, a.title, a.district, " +
                "c.rental_type, c.monthly_rent, c.created_at, c.status " +
                "FROM contracts c JOIN apartments a ON c.apt_id=a.apt_id " +
                "ORDER BY c.contract_id DESC LIMIT 10");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> r = new LinkedHashMap<>();
                r.put("id",       rs.getInt(1));    r.put("apt",      rs.getString(2));
                r.put("district", rs.getString(3)); r.put("type",     rs.getString(4));
                r.put("rent",     rs.getBigDecimal(5));
                r.put("date",     rs.getString(6)); r.put("status",   rs.getString(7));
                list.add(r);
            }
        } catch (Exception e) { log("[DASH] recent err: " + e.getMessage()); }
        req.setAttribute("recentContractsJson", gson.toJson(list));
    }

    private String toJson(Connection conn, String sql) {
        List<String> labels = new ArrayList<>();
        List<Double>  data  = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) { labels.add(rs.getString(1)); data.add(rs.getDouble(2)); }
        } catch (Exception e) {
            log("[DASH] toJson: " + e.getMessage() +
                " | SQL: " + sql.substring(0, Math.min(80, sql.length())));
        }
        Map<String,Object> m = new LinkedHashMap<>();
        m.put("labels", labels); m.put("data", data);
        return gson.toJson(m);
    }

    /**
     * Shutdown DASH_POOL khi Tomcat undeploy app.
     * Không có method này → các dash-query thread bị leak mỗi lần redeploy
     * → Tomcat log "started a thread... failed to stop it".
     */
    @Override
    public void destroy() {
        DASH_POOL.shutdown();
        try {
            if (!DASH_POOL.awaitTermination(5, TimeUnit.SECONDS)) {
                DASH_POOL.shutdownNow();
            }
        } catch (InterruptedException e) {
            DASH_POOL.shutdownNow();
            Thread.currentThread().interrupt();
        }
        log("[AdminDashboardServlet] DASH_POOL shutdown complete.");
        super.destroy();
    }
}
