package com.rental.etl.core;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import org.quartz.*;
import org.quartz.impl.StdSchedulerFactory;

import java.util.Properties;

import static org.quartz.CronScheduleBuilder.cronSchedule;
import static org.quartz.JobBuilder.newJob;
import static org.quartz.TriggerBuilder.newTrigger;

/**
 * ETLScheduler v17 — Fix Quartz inner-class + thread leak.
 *
 * Thay đổi so với v16:
 *  1. Dùng ETLPipelineJob (class riêng, file riêng) thay vì inner static class
 *     → Quartz classloader trong Tomcat load đúng → job chạy đúng giờ đã hẹn
 *  2. Log "Next scheduled run" sau khi đăng ký để dễ verify trong Tomcat log
 *  3. Giữ nguyên: threadCount=1, RAMJobStore, shutdown(true)
 */
public class ETLScheduler implements ServletContextListener {

    /** Static reference — dùng bởi AdminETLServlet.getNextFireTime() */
    private static volatile Scheduler INSTANCE;

    public static Scheduler getInstance() { return INSTANCE; }

    private Scheduler scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        // Reset stuck jobs ASYNC — không block startup
        Thread resetThread = new Thread(() -> {
            try {
                Thread.sleep(3000);
                resetStuckJobs();
            } catch (InterruptedException ignored) {}
        }, "ETL-StartupReset");
        resetThread.setDaemon(true);
        resetThread.start();

        try {
            // Dùng 1 thread thay vì 10 mặc định — tránh memory leak
            Properties props = new Properties();
            props.setProperty("org.quartz.scheduler.instanceName", "ETLScheduler");
            props.setProperty("org.quartz.threadPool.threadCount", "1");
            props.setProperty("org.quartz.scheduler.skipUpdateCheck", "true");
            props.setProperty("org.quartz.jobStore.class", "org.quartz.simpl.RAMJobStore");

            StdSchedulerFactory factory = new StdSchedulerFactory(props);
            scheduler = factory.getScheduler();
            INSTANCE  = scheduler;   // expose cho AdminETLServlet
            scheduler.start();

            // FIX v17: dùng ETLPipelineJob (class độc lập, file riêng).
            // Trước đây dùng inner static class ETLScheduler$ETLPipelineJob —
            // Quartz trong Tomcat classloader đôi khi không load được inner class
            // → scheduler đăng ký OK nhưng job không bao giờ thực thi khi đến giờ.
            JobDetail job = newJob(ETLPipelineJob.class)
                .withIdentity("etl-pipeline", "cc-dwh")
                .build();

            Trigger trigger = newTrigger()
                .withIdentity("etl-daily", "cc-dwh")
                .withSchedule(cronSchedule("0 0 2 * * ?")
                    .inTimeZone(java.util.TimeZone.getTimeZone("Asia/Ho_Chi_Minh")))
                .build();

            scheduler.scheduleJob(job, trigger);

            // Log giờ chạy kế tiếp — kiểm tra trong catalina.out để verify
            java.util.Date nextFire = trigger.getNextFireTime();
            System.out.println("[ETLScheduler] Scheduled: daily 02:00 ICT (1 thread)");
            System.out.println("[ETLScheduler] Next scheduled run: " + nextFire);

        } catch (SchedulerException e) {
            System.err.println("[ETLScheduler] FAILED to start scheduler: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        INSTANCE = null;
        try {
            if (scheduler != null && !scheduler.isShutdown()) {
                scheduler.shutdown(true); // true = chờ job đang chạy xong
                System.out.println("[ETLScheduler] Stopped cleanly.");
            }
        } catch (SchedulerException e) {
            System.err.println("[ETLScheduler] Shutdown error: " + e.getMessage());
        }
        // Đóng ETLContext pools
        try { ETLContext.shutdownPools(); } catch (Exception ignored) {}
        // Đóng HikariCP pool chính của app (DBConnection)
        // Không có dòng này → Tomcat log "HikariPool-1 housekeeper" thread leak
        try { com.rental.util.DBConnection.shutdown(); } catch (Exception ignored) {}
        // Dọn MySQL abandoned connection thread
        try {
            com.mysql.cj.jdbc.AbandonedConnectionCleanupThread.uncheckedShutdown();
        } catch (Exception ignored) {}
    }

    private void resetStuckJobs() {
        try (ETLContext ctx = new ETLContext()) {
            new WatermarkHelper(ctx.getDwhConn()).resetStuckRunning();
            try (java.sql.PreparedStatement ps = ctx.getDwhConn().prepareStatement(
                    "UPDATE cc_dwh.etl_audit_log " +
                    "SET status='failed', finished_at=NOW(), " +
                    "error_message='Server restarted' WHERE status='running'")) {
                ps.executeUpdate();
            }
            System.out.println("[ETLScheduler] Startup cleanup done.");
        } catch (Exception e) {
            System.err.println("[ETLScheduler] Cleanup error: " + e.getMessage());
        }
    }
}
