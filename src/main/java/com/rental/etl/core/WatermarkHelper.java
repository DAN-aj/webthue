package com.rental.etl.core;

import java.sql.*;
import java.time.Instant;

/**
 * Quản lý bảng cc_dwh.etl_watermark để track tiến độ Incremental Load.
 *
 * FIXES:
 *  - Thêm schema prefix "cc_dwh." vào tất cả query (tránh query sai DB)
 *  - Thêm markRunning() / markFailed() để handle "stuck running" khi server restart
 */
public class WatermarkHelper {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.etl_watermark (" +
        "  job_name       VARCHAR(50) PRIMARY KEY," +
        "  last_run_at    TIMESTAMP   NOT NULL DEFAULT '2000-01-01 00:00:00'," +
        "  last_max_id    INT         DEFAULT 0," +
        "  rows_processed INT         DEFAULT 0," +
        "  status         ENUM('success','failed','running') DEFAULT 'success'" +
        ") ENGINE=InnoDB";

    private final Connection dwhConn;

    public WatermarkHelper(Connection dwhConn) {
        this.dwhConn = dwhConn;
        ensureTable();
    }

    private void ensureTable() {
        try (PreparedStatement ps = dwhConn.prepareStatement(CREATE_TABLE)) {
            ps.execute();
        } catch (Exception e) {
            System.err.println("[Watermark] Cannot create watermark table: " + e.getMessage());
        }
    }

    /** Trả về timestamp lần chạy cuối (dùng cho incremental by updated_at) */
    public Timestamp getLastRunAt(String jobName) {
        // FIX: Thêm cc_dwh. prefix
        try (PreparedStatement ps = dwhConn.prepareStatement(
                "SELECT last_run_at FROM cc_dwh.etl_watermark WHERE job_name=?")) {
            ps.setString(1, jobName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getTimestamp("last_run_at");
        } catch (Exception e) {
            System.err.println("[Watermark] Cannot read last_run_at: " + e.getMessage());
        }
        return Timestamp.from(Instant.parse("2000-01-01T00:00:00Z"));
    }

    /** Trả về max ID đã xử lý (dùng cho incremental by ID) */
    public int getLastMaxId(String jobName) {
        // FIX: Thêm cc_dwh. prefix
        try (PreparedStatement ps = dwhConn.prepareStatement(
                "SELECT last_max_id FROM cc_dwh.etl_watermark WHERE job_name=?")) {
            ps.setString(1, jobName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt("last_max_id");
        } catch (Exception e) {
            System.err.println("[Watermark] Cannot read last_max_id: " + e.getMessage());
        }
        return 0;
    }

    /**
     * FIX MỚI: Đánh dấu job đang chạy (ghi trước khi extract)
     * → nếu server crash giữa chừng, DB vẫn biết job đang running
     */
    public void markRunning(String jobName) {
        try (PreparedStatement ps = dwhConn.prepareStatement(
                "INSERT INTO cc_dwh.etl_watermark (job_name, status) VALUES (?, 'running') " +
                "ON DUPLICATE KEY UPDATE status='running'")) {
            ps.setString(1, jobName);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("[Watermark] Cannot mark running: " + e.getMessage());
        }
    }

    /**
     * FIX MỚI: Đánh dấu job failed (gọi trong catch block)
     * → tránh stuck ở trạng thái 'running' khi server restart
     */
    public void markFailed(String jobName) {
        try (PreparedStatement ps = dwhConn.prepareStatement(
                "UPDATE cc_dwh.etl_watermark SET status='failed' WHERE job_name=? AND status='running'")) {
            ps.setString(1, jobName);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("[Watermark] Cannot mark failed: " + e.getMessage());
        }
    }

    /**
     * FIX MỚI: Khi server khởi động, reset tất cả record stuck ở 'running' → 'failed'
     * Gọi 1 lần trong ETLContext static block hoặc ETLScheduler.contextInitialized()
     */
    public void resetStuckRunning() {
        try (PreparedStatement ps = dwhConn.prepareStatement(
                "UPDATE cc_dwh.etl_watermark SET status='failed' WHERE status='running'")) {
            int rows = ps.executeUpdate();
            if (rows > 0) {
                System.out.printf("[Watermark] Reset %d stuck 'running' watermark entries to 'failed'%n", rows);
            }
        } catch (Exception e) {
            System.err.println("[Watermark] Cannot reset stuck running: " + e.getMessage());
        }
    }

    /** Cập nhật watermark sau khi job thành công */
    public void updateSuccess(String jobName, Timestamp runAt, int maxId, int rows) {
        // FIX: Thêm cc_dwh. prefix
        try (PreparedStatement ps = dwhConn.prepareStatement(
                "INSERT INTO cc_dwh.etl_watermark (job_name, last_run_at, last_max_id, rows_processed, status) " +
                "VALUES (?,?,?,?,'success') " +
                "ON DUPLICATE KEY UPDATE last_run_at=VALUES(last_run_at), last_max_id=VALUES(last_max_id), " +
                "rows_processed=VALUES(rows_processed), status='success'")) {
            ps.setString(1, jobName);
            ps.setTimestamp(2, runAt);
            ps.setInt(3, maxId);
            ps.setInt(4, rows);
            ps.executeUpdate();
        } catch (Exception e) {
            System.err.println("[Watermark] Cannot update: " + e.getMessage());
        }
    }
}
