package com.rental.etl.core;

import java.util.concurrent.*;

/**
 * ETLJob interface – mỗi job implement 3 bước extract/transform/load.
 *
 * THÊM MỚI v10:
 *  - runWithTimeout(ctx, timeoutSeconds): chạy job trong FutureTask với timeout cứng.
 *    Nếu job chạy quá timeoutSeconds → ném TimeoutException → pipeline dừng.
 *  - DEFAULT_TIMEOUT_SECONDS: timeout mặc định 5 phút/job.
 */
public interface ETLJob {

    int DEFAULT_TIMEOUT_SECONDS = 300; // 5 phút mặc định

    String getJobName();
    void extract() throws Exception;
    void transform() throws Exception;
    void load() throws Exception;
    int getRowsProcessed();

    /**
     * Chạy job với timeout (giây). Nếu quá hạn → interrupt + ném TimeoutException.
     * Gọi bởi ETLJobRunner để đảm bảo không có job nào treo vô hạn.
     */
    default void runWithTimeout(ETLContext ctx, int timeoutSeconds) throws Exception {
        ETLAuditLog audit = new ETLAuditLog(ctx.getDwhConn(), getJobName());
        audit.start();

        ExecutorService svc = Executors.newSingleThreadExecutor(r -> {
            Thread t = new Thread(r, "ETL-" + getJobName());
            t.setDaemon(true);
            return t;
        });

        Future<?> future = svc.submit(() -> {
            try {
                extract();
                transform();
                load();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });

        try {
            future.get(timeoutSeconds, TimeUnit.SECONDS);
            audit.success(getRowsProcessed());
        } catch (TimeoutException e) {
            future.cancel(true);
            String msg = String.format("TIMEOUT: job '%s' chạy quá %ds — đã bị dừng.", getJobName(), timeoutSeconds);
            audit.fail(msg);
            throw new TimeoutException(msg);
        } catch (ExecutionException e) {
            Throwable cause = e.getCause() != null ? e.getCause() : e;
            String msg = cause.getMessage() != null ? cause.getMessage() : cause.toString();
            audit.fail(msg);
            throw new Exception(msg, cause);
        } catch (InterruptedException e) {
            future.cancel(true);
            String msg = "INTERRUPTED: job '" + getJobName() + "' bị dừng từ bên ngoài.";
            audit.fail(msg);
            Thread.currentThread().interrupt();
            throw new InterruptedException(msg);
        } finally {
            svc.shutdownNow();
        }
    }

    /** Backward-compat: run không timeout (dùng mặc định 5 phút) */
    default void run(ETLContext ctx) throws Exception {
        runWithTimeout(ctx, DEFAULT_TIMEOUT_SECONDS);
    }
}
