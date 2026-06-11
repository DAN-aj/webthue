package com.rental.etl.core;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.Instant;

/**
 * Ghi kết quả mỗi ETL Job vào bảng cc_dwh.etl_audit_log.
 * Tạo bảng nếu chưa tồn tại.
 */
public class ETLAuditLog {

    private static final String CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS cc_dwh.etl_audit_log (" +
        "  log_id        INT AUTO_INCREMENT PRIMARY KEY," +
        "  job_name      VARCHAR(100) NOT NULL," +
        "  started_at    TIMESTAMP NOT NULL," +
        "  finished_at   TIMESTAMP NULL," +
        "  rows_processed INT DEFAULT 0," +
        "  status        ENUM('running','success','failed') DEFAULT 'running'," +
        "  error_message TEXT" +
        ") ENGINE=InnoDB";

    private final Connection dwhConn;
    private final String jobName;
    private Timestamp startedAt;
    private int logId;

    public ETLAuditLog(Connection dwhConn, String jobName) {
        this.dwhConn = dwhConn;
        this.jobName = jobName;
        ensureTable();
    }

    private void ensureTable() {
        try (PreparedStatement ps = dwhConn.prepareStatement(CREATE_TABLE)) {
            ps.execute();
        } catch (Exception e) {
            System.err.println("[ETLAuditLog] Cannot create audit table: " + e.getMessage());
        }
    }

    public void start() {
        startedAt = Timestamp.from(Instant.now());
        // FIX: Thêm "cc_dwh." prefix để đảm bảo đúng schema bất kể DB context của connection
        try (PreparedStatement ps = dwhConn.prepareStatement(
                "INSERT INTO cc_dwh.etl_audit_log (job_name, started_at, status) VALUES (?,?,'running')",
                PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, jobName);
            ps.setTimestamp(2, startedAt);
            ps.executeUpdate();
            var rs = ps.getGeneratedKeys();
            if (rs.next()) {
                logId = rs.getInt(1);
            } else {
                // FIX: Nếu RETURN_GENERATED_KEYS không trả về gì, fallback query lại
                System.err.println("[ETLAuditLog] WARN: getGeneratedKeys() trả về rỗng, thử fallback query");
                try (PreparedStatement fallback = dwhConn.prepareStatement(
                        "SELECT log_id FROM cc_dwh.etl_audit_log WHERE job_name=? ORDER BY log_id DESC LIMIT 1")) {
                    fallback.setString(1, jobName);
                    ResultSet fr = fallback.executeQuery();
                    if (fr.next()) logId = fr.getInt(1);
                }
            }
            System.out.printf("[ETLAuditLog] Started job '%s' → log_id=%d%n", jobName, logId);
        } catch (Exception e) {
            System.err.println("[ETLAuditLog] Cannot log start: " + e.getMessage());
        }
    }

    public void success(int rows) {
        update("success", rows, null);
    }

    public void fail(String error) {
        update("failed", 0, error);
    }

    private void update(String status, int rows, String error) {
        // FIX: Guard logId=0 → tránh UPDATE không tìm được row nào
        if (logId <= 0) {
            System.err.printf("[ETLAuditLog] WARN: logId=%d (<=0), skip update for job '%s' status=%s%n",
                    logId, jobName, status);
            return;
        }
        // FIX: Thêm "cc_dwh." prefix
        try (PreparedStatement ps = dwhConn.prepareStatement(
                "UPDATE cc_dwh.etl_audit_log SET finished_at=?, rows_processed=?, status=?, error_message=? WHERE log_id=?")) {
            ps.setTimestamp(1, Timestamp.from(Instant.now()));
            ps.setInt(2, rows);
            ps.setString(3, status);
            ps.setString(4, error);
            ps.setInt(5, logId);
            int updated = ps.executeUpdate();
            if (updated == 0) {
                System.err.printf("[ETLAuditLog] WARN: UPDATE 0 rows — log_id=%d không tồn tại trong cc_dwh.etl_audit_log%n", logId);
            }
        } catch (Exception e) {
            System.err.println("[ETLAuditLog] Cannot update log: " + e.getMessage());
        }
    }
}
