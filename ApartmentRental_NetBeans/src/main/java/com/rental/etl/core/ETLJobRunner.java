package com.rental.etl.core;

import com.rental.etl.aggregation.AggDailyRevenueJob;
import com.rental.etl.aggregation.AggOccupancyJob;
import com.rental.etl.dimension.*;
import com.rental.etl.fact.*;
import com.rental.util.DBConnection;

import java.sql.Connection;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Orchestrator: chạy tất cả ETL Jobs theo đúng thứ tự phụ thuộc.
 * Dimension → Fact → Aggregation
 *
 * THÊM MỚI v10:
 *  - Mỗi job có timeout cấu hình riêng (xem JOB_TIMEOUTS bên dưới).
 *  - cancelRequested: flag cho phép AdminETLServlet yêu cầu dừng pipeline giữa chừng.
 *  - runningJobName: track job hiện tại để hiển thị trên UI.
 *  - stopPipeline(): gọi từ servlet khi user bấm "Dừng pipeline".
 */
public class ETLJobRunner {

    // ── Timeout theo job (giây) ──────────────────────────────────────────────
    // Điều chỉnh theo kích thước data thực tế của bạn.
    private static final Map<String, Integer> JOB_TIMEOUTS = new LinkedHashMap<>();
    static {
        JOB_TIMEOUTS.put("DimTimeLoader",        60);   // 1 phút
        JOB_TIMEOUTS.put("DimLocationLoader",    60);
        JOB_TIMEOUTS.put("DimUserLoader",        120);  // 2 phút
        JOB_TIMEOUTS.put("DimApartmentLoader",   120);
        JOB_TIMEOUTS.put("FactContractLoader",   900);  // 15 phút
        JOB_TIMEOUTS.put("FactPaymentLoader",   1800);  // 30 phút — 1.86M rows streaming
        JOB_TIMEOUTS.put("AggDailyRevenueJob",   120);
        JOB_TIMEOUTS.put("AggOccupancyJob",      120);
    }

    // ── Trạng thái dừng (shared với AdminETLServlet) ─────────────────────────
    private static final AtomicBoolean cancelRequested  = new AtomicBoolean(false);
    private static final AtomicReference<String> runningJobName = new AtomicReference<>("");

    /** Gọi từ AdminETLServlet khi user bấm "Dừng pipeline". */
    public static void stopPipeline() {
        cancelRequested.set(true);
        System.out.println("[ETLJobRunner] Stop requested by user.");
    }

    /** Lấy tên job đang chạy (cho status API). */
    public static String getRunningJobName() {
        return runningJobName.get();
    }

    // ── Run toàn bộ pipeline ─────────────────────────────────────────────────
    public static ETLRunResult runAll() {
        cancelRequested.set(false); // reset flag mỗi lần run mới
        ETLRunResult result = new ETLRunResult();

        try {
            // FIX v13: tạo database cc_dwh TRƯỚC khi ETLContext() mở DWH pool.
            // ETLContext() kết nối pool vào JDBC URL /cc_dwh — nếu DB chưa tồn tại
            // thì pool init thất bại ngay, không bao giờ chạy đến ensureDwhSchema().
            // Dùng OLTP connection (luôn sẵn có) để tạo DB nếu cần.
            createDwhDatabaseIfAbsent();
        } catch (Exception e) {
            result.addFailure("ETLContext", "Không thể tạo cc_dwh: " + e.getMessage(), 0);
            return result;
        }

        try (ETLContext ctx = new ETLContext()) {
            ensureDwhSchema(ctx.getDwhConn());

            List<ETLJob> jobs = buildPipeline(ctx);
            for (ETLJob job : jobs) {

                // ── Check cancel trước khi bắt đầu job tiếp theo ──────────
                if (cancelRequested.get()) {
                    result.addCancelled(job.getJobName(), "Pipeline bị dừng bởi người dùng.");
                    System.out.printf("[ETL] ⛔ %s — bị bỏ qua (pipeline đã dừng)%n", job.getJobName());
                    continue;
                }

                runningJobName.set(job.getJobName());
                int timeout = JOB_TIMEOUTS.getOrDefault(job.getJobName(), ETLJob.DEFAULT_TIMEOUT_SECONDS);
                long t0 = System.currentTimeMillis();

                try {
                    job.runWithTimeout(ctx, timeout);
                    long ms = System.currentTimeMillis() - t0;
                    result.addSuccess(job.getJobName(), job.getRowsProcessed(), ms);
                    System.out.printf("[ETL] ✓ %s — %d rows — %dms%n",
                            job.getJobName(), job.getRowsProcessed(), ms);

                } catch (java.util.concurrent.TimeoutException e) {
                    long ms = System.currentTimeMillis() - t0;
                    result.addTimeout(job.getJobName(), e.getMessage(), ms);
                    System.err.printf("[ETL] ⏰ TIMEOUT %s — %dms — %s%n", job.getJobName(), ms, e.getMessage());
                    // Timeout → dừng pipeline ngay (không tiếp tục các job sau)
                    cancelRequested.set(true);

                } catch (Exception e) {
                    long ms = System.currentTimeMillis() - t0;
                    result.addFailure(job.getJobName(), e.getMessage(), ms);
                    System.err.printf("[ETL] ✗ %s — %s%n", job.getJobName(), e.getMessage());
                    // Dim job lỗi → dừng toàn bộ (Fact sẽ thiếu key)
                    if (job.getJobName().startsWith("Dim")) {
                        cancelRequested.set(true);
                    }
                }
            }
        } catch (Exception e) {
            result.addFailure("ETLContext", e.getMessage(), 0);
        } finally {
            runningJobName.set("");
        }
        return result;
    }

    // ── Run 1 job đơn lẻ ─────────────────────────────────────────────────────
    public static ETLRunResult runJob(String jobName) {
        cancelRequested.set(false);
        ETLRunResult result = new ETLRunResult();

        try {
            // FIX v13: cùng guard như runAll() — tạo cc_dwh trước khi mở DWH pool
            createDwhDatabaseIfAbsent();
        } catch (Exception e) {
            result.addFailure(jobName, "Không thể tạo cc_dwh: " + e.getMessage(), 0);
            return result;
        }

        try (ETLContext ctx = new ETLContext()) {
            ensureDwhSchema(ctx.getDwhConn());
            ETLJob job = findJob(ctx, jobName);
            if (job == null) {
                result.addFailure(jobName, "Job not found: " + jobName, 0);
                return result;
            }
            runningJobName.set(job.getJobName());
            int timeout = JOB_TIMEOUTS.getOrDefault(job.getJobName(), ETLJob.DEFAULT_TIMEOUT_SECONDS);
            long t0 = System.currentTimeMillis();

            try {
                job.runWithTimeout(ctx, timeout);
                result.addSuccess(job.getJobName(), job.getRowsProcessed(), System.currentTimeMillis() - t0);
            } catch (java.util.concurrent.TimeoutException e) {
                result.addTimeout(job.getJobName(), e.getMessage(), System.currentTimeMillis() - t0);
            } catch (Exception e) {
                result.addFailure(job.getJobName(), e.getMessage(), System.currentTimeMillis() - t0);
            }

        } catch (Exception e) {
            result.addFailure(jobName, e.getMessage(), 0);
        } finally {
            runningJobName.set("");
        }
        return result;
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    private static List<ETLJob> buildPipeline(ETLContext ctx) {
        List<ETLJob> jobs = new ArrayList<>();
        jobs.add(new DimTimeLoader(ctx));
        jobs.add(new DimLocationLoader(ctx));
        jobs.add(new DimUserLoader(ctx));
        jobs.add(new DimApartmentLoader(ctx));
        jobs.add(new FactContractLoader(ctx));
        jobs.add(new FactPaymentLoader(ctx));
        jobs.add(new AggDailyRevenueJob(ctx));
        jobs.add(new AggOccupancyJob(ctx));
        return jobs;
    }

    private static ETLJob findJob(ETLContext ctx, String name) {
        return buildPipeline(ctx).stream()
                .filter(j -> j.getJobName().equalsIgnoreCase(name))
                .findFirst().orElse(null);
    }

    /**
     * FIX v13: Tạo database cc_dwh nếu chưa tồn tại, dùng OLTP connection.
     * Phải gọi TRƯỚC khi new ETLContext() vì ETLContext pool bind vào URL /cc_dwh —
     * nếu DB chưa có thì HikariCP không thể open connection và ném exception ngay.
     */
    private static void createDwhDatabaseIfAbsent() throws Exception {
        try (Connection oltpConn = DBConnection.getConnection()) {
            oltpConn.createStatement().execute(
                "CREATE DATABASE IF NOT EXISTS cc_dwh CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
        }
    }

    private static void ensureDwhSchema(Connection dwhConn) throws Exception {
        dwhConn.createStatement().execute(
            "CREATE DATABASE IF NOT EXISTS cc_dwh CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    }

    // ── Result ───────────────────────────────────────────────────────────────
    public static class ETLRunResult {
        public final List<JobResult> results = new ArrayList<>();

        public boolean hasErrors() {
            return results.stream().anyMatch(r -> !r.success() && r.state() != JobState.CANCELLED);
        }

        void addSuccess(String name, int rows, long ms) {
            results.add(new JobResult(name, true, rows, ms, null, JobState.SUCCESS));
        }
        void addFailure(String name, String error, long ms) {
            results.add(new JobResult(name, false, 0, ms, error, JobState.FAILED));
        }
        void addTimeout(String name, String error, long ms) {
            results.add(new JobResult(name, false, 0, ms, error, JobState.TIMEOUT));
        }
        void addCancelled(String name, String reason) {
            results.add(new JobResult(name, false, 0, 0, reason, JobState.CANCELLED));
        }
    }

    public enum JobState { SUCCESS, FAILED, TIMEOUT, CANCELLED }

    public record JobResult(
        String jobName, boolean success, int rows, long durationMs, String error, JobState state
    ) {}
}
