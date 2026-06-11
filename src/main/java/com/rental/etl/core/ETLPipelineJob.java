package com.rental.etl.core;

import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;

/**
 * ETLPipelineJob — standalone class (không phải inner class của ETLScheduler).
 *
 * Quartz dùng reflection để instantiate Job qua no-arg constructor.
 * Inner static class trong Tomcat có thể bị classloader load sai
 * → job đăng ký thành công nhưng không bao giờ chạy khi đến giờ.
 *
 * Fix: tách ra file riêng để Quartz load class chắc chắn.
 */
public class ETLPipelineJob implements Job {

    // Quartz yêu cầu public no-arg constructor
    public ETLPipelineJob() {}

    @Override
    public void execute(JobExecutionContext context) throws JobExecutionException {
        System.out.println("[ETLPipelineJob] ===== Scheduled run started =====");
        try {
            ETLJobRunner.ETLRunResult result = ETLJobRunner.runAll();
            if (result.hasErrors()) {
                System.err.println("[ETLPipelineJob] Completed WITH errors. Check etl_audit_log.");
            } else {
                System.out.println("[ETLPipelineJob] Completed successfully.");
            }
        } catch (Exception e) {
            System.err.println("[ETLPipelineJob] Unexpected error: " + e.getMessage());
            throw new JobExecutionException(e);
        }
        System.out.println("[ETLPipelineJob] ===== Scheduled run finished =====");
    }
}
