package com.rental.servlet.admin;

import com.google.gson.Gson;
import com.rental.etl.core.ETLContext;
import com.rental.etl.core.ETLJobRunner;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.quartz.*;
import org.quartz.impl.matchers.GroupMatcher;
import com.rental.etl.core.ETLScheduler;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicReference;

/**
 * AdminETLServlet v17
 *
 * GET  /admin/etl          → Trang dashboard ETL
 * GET  /admin/etl?action=status → JSON trạng thái pipeline (polling)
 * POST /admin/etl          → Chạy thủ công (runAll / runJob / stop)
 */
public class AdminETLServlet extends HttpServlet {

    // Executor riêng — ETL chạy nền, không block HTTP thread
    private static final ExecutorService etlExecutor =
        Executors.newSingleThreadExecutor(r -> {
            Thread t = new Thread(r, "ETL-Manual");
            t.setDaemon(true);
            return t;
        });

    private static final AtomicReference<String> etlState =
        new AtomicReference<>("IDLE"); // IDLE | RUNNING | DONE | FAILED | STOPPED

    private static volatile long etlStartMs = 0;
    private static volatile List<Map<String,Object>> lastRunDetail = new ArrayList<>();

    // ── GET ───────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");

        if ("status".equals(action)) {
            // Polling endpoint — trả JSON
            resp.setContentType("application/json;charset=UTF-8");
            resp.setHeader("Cache-Control", "no-cache");
            PrintWriter out = resp.getWriter();
            out.print(buildStatusJson());
            return;
        }

        renderPage(req, resp);
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String act = req.getParameter("etlAction");

        if ("runAll".equals(act) && !"RUNNING".equals(etlState.get())) {
            etlState.set("RUNNING");
            etlStartMs = System.currentTimeMillis();
            lastRunDetail = new ArrayList<>();

            etlExecutor.submit(() -> {
                try {
                    ETLJobRunner.ETLRunResult result = ETLJobRunner.runAll();
                    List<Map<String,Object>> detail = new ArrayList<>();
                    for (ETLJobRunner.JobResult jr : result.results) {
                        Map<String,Object> m = new LinkedHashMap<>();
                        m.put("job",   jr.jobName());
                        m.put("state", jr.state().name());
                        m.put("rows",  jr.rows());
                        m.put("ms",    jr.durationMs());
                        m.put("error", jr.error() != null ? jr.error() : "");
                        detail.add(m);
                    }
                    lastRunDetail = detail;
                    etlState.set(result.hasErrors() ? "FAILED" : "DONE");
                } catch (Exception e) {
                    etlState.set("FAILED");
                    System.err.println("[ETLServlet] runAll error: " + e.getMessage());
                }
            });

        } else if ("runJob".equals(act) && !"RUNNING".equals(etlState.get())) {
            String job = req.getParameter("etlJob");
            if (job != null && !job.isEmpty()) {
                etlState.set("RUNNING");
                etlStartMs = System.currentTimeMillis();
                lastRunDetail = new ArrayList<>();
                final String jobName = job;

                etlExecutor.submit(() -> {
                    try {
                        ETLJobRunner.ETLRunResult result = ETLJobRunner.runJob(jobName);
                        List<Map<String,Object>> detail = new ArrayList<>();
                        for (ETLJobRunner.JobResult jr : result.results) {
                            Map<String,Object> m = new LinkedHashMap<>();
                            m.put("job",   jr.jobName());
                            m.put("state", jr.state().name());
                            m.put("rows",  jr.rows());
                            m.put("ms",    jr.durationMs());
                            m.put("error", jr.error() != null ? jr.error() : "");
                            detail.add(m);
                        }
                        lastRunDetail = detail;
                        etlState.set(result.hasErrors() ? "FAILED" : "DONE");
                    } catch (Exception e) {
                        etlState.set("FAILED");
                    }
                });
            }

        } else if ("stop".equals(act)) {
            ETLJobRunner.stopPipeline();
            etlState.set("STOPPED");
        }

        resp.sendRedirect(req.getContextPath() + "/admin/etl");
    }

    // ── Status JSON (polling) ─────────────────────────────────────────────────
    // FIX v13: dùng Gson thay vì StringBuilder thủ công.
    // String concat cũ chỉ replace " thành ' trong error message —
    // nếu error chứa newline, tab, hoặc backslash thì JSON output invalid → UI crash.
    private static final Gson GSON = new Gson();

    private String buildStatusJson() {
        String state   = etlState.get();
        long elapsed   = etlStartMs > 0 ? System.currentTimeMillis() - etlStartMs : 0;
        String running = ETLJobRunner.getRunningJobName();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("state",      state);
        payload.put("elapsedMs",  elapsed);
        payload.put("runningJob", running != null ? running : "");
        payload.put("jobs",       lastRunDetail);
        return GSON.toJson(payload);
    }

    // ── Render trang ETL — forward sang etl.jsp ─────────────────────────────
    private void renderPage(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {

        // Dữ liệu từ DB
        boolean dwhFresh = false;
        String  lastRun  = "Chưa chạy";
        List<Map<String,Object>> auditLog = new ArrayList<>();
        long successCount = 0, failCount = 0, totalRows = 0;

        // FIX v13: dùng ETLContext (DWH pool) thay vì DBConnection (OLTP pool)
        // để query cc_dwh.etl_watermark và cc_dwh.etl_audit_log.
        // DBConnection kết nối tới apartment_rental — nếu MySQL user không có
        // quyền cross-schema thì toàn bộ dashboard bị lỗi trong môi trường production.
        try (ETLContext etlCtx = new ETLContext();
             Connection conn   = etlCtx.getDwhConn()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT last_run_at FROM cc_dwh.etl_watermark WHERE job_name='AggDailyRevenueJob'");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getTimestamp(1) != null) {
                    long h = (System.currentTimeMillis() - rs.getTimestamp(1).getTime()) / 3_600_000;
                    dwhFresh = h < 48;
                }
            } catch (Exception ignored) {}

            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT MAX(last_run_at) FROM cc_dwh.etl_watermark");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getString(1) != null) lastRun = rs.getString(1);
            } catch (Exception ignored) {}

            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT job_name, started_at, finished_at, rows_processed, status, error_message " +
                    "FROM cc_dwh.etl_audit_log ORDER BY log_id DESC LIMIT 40");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String,Object> row = new LinkedHashMap<>();
                    long rowCount = rs.getLong("rows_processed");
                    String st = rs.getString("status");
                    String errRaw = rs.getString("error_message");
                    row.put("job",         rs.getString("job_name"));
                    row.put("start",       rs.getString("started_at") != null ? rs.getString("started_at") : "—");
                    row.put("end",         rs.getString("finished_at") != null ? rs.getString("finished_at") : "—");
                    row.put("rows",        rowCount);
                    row.put("rowsFmt",     fmtNum(rowCount));
                    row.put("status",      st != null ? st : "");
                    row.put("statusLabel", st != null ? st.toUpperCase() : "");
                    row.put("error",       (errRaw != null && !errRaw.isEmpty())
                                           ? errRaw.substring(0, Math.min(errRaw.length(), 80)) : "");
                    auditLog.add(row);
                    if ("success".equals(st)) successCount++;
                    else if ("failed".equals(st)) failCount++;
                    totalRows += rowCount;
                }
            } catch (Exception ignored) {}
        } catch (Exception ignored) {}

        String nextFireTime = getNextFireTime();

        // Set attributes cho JSP
        req.setAttribute("dwhFresh",     dwhFresh);
        req.setAttribute("lastRun",      lastRun);
        req.setAttribute("nextFireTime", nextFireTime);
        req.setAttribute("auditLog",     auditLog);
        req.setAttribute("successCount", successCount);
        req.setAttribute("failCount",    failCount);
        req.setAttribute("totalRowsFmt", fmtNum(totalRows));

        req.getRequestDispatcher("/WEB-INF/views/admin/etl.jsp").forward(req, resp);
    }

    // ── Lấy thời gian chạy tiếp theo từ Quartz ───────────────────────────────
    private String getNextFireTime() {
        try {
            Scheduler sched = ETLScheduler.getInstance();  // FIX: dùng instance đúng thay vì getDefaultScheduler()
            if (sched == null) return "02:00 ICT ngày mai";
            for (TriggerKey tk : sched.getTriggerKeys(GroupMatcher.anyTriggerGroup())) {
                Trigger t = sched.getTrigger(tk);
                if (t != null && t.getNextFireTime() != null) {
                    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
                    sdf.setTimeZone(java.util.TimeZone.getTimeZone("Asia/Ho_Chi_Minh"));
                    return sdf.format(t.getNextFireTime()) + " ICT";
                }
            }
        } catch (Exception ignored) {}
        return "02:00 ICT ngày mai";
    }

    private String fmtNum(long n){
        if(n>=1_000_000) return String.format("%.1fM",n/1_000_000.0);
        if(n>=1_000)     return String.format("%.0fK",n/1_000.0);
        return String.valueOf(n);
    }
}
