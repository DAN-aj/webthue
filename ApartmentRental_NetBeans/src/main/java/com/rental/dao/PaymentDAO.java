package com.rental.dao;

import com.rental.model.Payment;
import com.rental.util.DBConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PaymentDAO {

    // INSERT — lưu payment mới với status=pending và tx_ref
    public int insert(Payment p) {
        String sql = "INSERT INTO payments (contract_id, payer_id, amount, payment_type, period_month, " +
                     "payment_method, status, due_date, note, tx_ref) VALUES (?,?,?,?,?,?,?,?,?,?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, p.getContractId());
            ps.setInt(2, p.getPayerId());
            ps.setBigDecimal(3, p.getAmount());
            ps.setString(4, p.getPaymentType());
            ps.setObject(5, p.getPeriodMonth());
            ps.setString(6, p.getPaymentMethod());
            ps.setString(7, "pending");
            ps.setDate(8, p.getDueDate());
            ps.setString(9, p.getNote());
            ps.setString(10, p.getTxRef());
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            if (keys.next()) return keys.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return -1;
    }

    // Tìm payment theo mã tham chiếu VietQR — dùng bởi SepayWebhookServlet
    public Payment findByTxRef(String txRef) {
        String sql = "SELECT p.*, a.title apt_title, u.full_name payer_name " +
                     "FROM payments p " +
                     "JOIN contracts c ON p.contract_id=c.contract_id " +
                     "JOIN apartments a ON c.apt_id=a.apt_id " +
                     "JOIN users u ON p.payer_id=u.user_id " +
                     "WHERE p.tx_ref=? LIMIT 1";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, txRef);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapPayment(rs);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    // Xác nhận thành công qua tx_ref — dùng bởi webhook SePay
    public boolean confirmPaymentByTxRef(String txRef, String bankTxCode) {
        String sql = "UPDATE payments SET status='success', transaction_code=?, paid_date=NOW() " +
                     "WHERE tx_ref=? AND status='pending'";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bankTxCode);
            ps.setString(2, txRef);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // Xác nhận thành công theo paymentId — dùng cho thẻ tín dụng
    public boolean confirmPayment(int paymentId, String txCode) {
        String sql = "UPDATE payments SET status='success', transaction_code=?, paid_date=NOW() WHERE payment_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, txCode);
            ps.setInt(2, paymentId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean failPayment(int paymentId) {
        String sql = "UPDATE payments SET status='failed' WHERE payment_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, paymentId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // Hết hạn các QR pending quá X phút — gọi bởi scheduler hoặc cron
    public int expireOldPendingPayments(int minutes) {
        String sql = "UPDATE payments SET status='failed' WHERE status='pending' " +
                     "AND payment_method='bank_qr' AND created_at < NOW() - INTERVAL ? MINUTE";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, minutes);
            return ps.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public Payment findById(int paymentId) {
        String sql = "SELECT p.*, a.title apt_title, u.full_name payer_name " +
                     "FROM payments p JOIN contracts c ON p.contract_id=c.contract_id " +
                     "JOIN apartments a ON c.apt_id=a.apt_id " +
                     "JOIN users u ON p.payer_id=u.user_id WHERE p.payment_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, paymentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapPayment(rs);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public List<Payment> getByContractId(int contractId) {
        List<Payment> list = new ArrayList<>();
        String sql = "SELECT p.*, a.title apt_title, u.full_name payer_name " +
                     "FROM payments p JOIN contracts c ON p.contract_id=c.contract_id " +
                     "JOIN apartments a ON c.apt_id=a.apt_id " +
                     "JOIN users u ON p.payer_id=u.user_id " +
                     "WHERE p.contract_id=? ORDER BY p.created_at DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contractId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapPayment(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<Payment> getByPayerId(int payerId) {
        List<Payment> list = new ArrayList<>();
        String sql = "SELECT p.*, a.title apt_title, u.full_name payer_name " +
                     "FROM payments p JOIN contracts c ON p.contract_id=c.contract_id " +
                     "JOIN apartments a ON c.apt_id=a.apt_id " +
                     "JOIN users u ON p.payer_id=u.user_id " +
                     "WHERE p.payer_id=? ORDER BY p.created_at DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, payerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapPayment(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public int countPaidPeriods(int contractId) {
        String sql = "SELECT COUNT(*) FROM payments WHERE contract_id=? AND payment_type='periodic' AND status='success'";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contractId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public boolean hasInitialPayment(int contractId) {
        String sql = "SELECT 1 FROM payments WHERE contract_id=? AND payment_type='initial' AND status='success'";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contractId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public BigDecimal getTotalRevenue() {
        String sql = "SELECT COALESCE(SUM(platform_fee),0) FROM contracts WHERE status IN ('active','expired')";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getBigDecimal(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return BigDecimal.ZERO;
    }

    public BigDecimal getRevenueByPeriod(String fromDate, String toDate) {
        String sql = "SELECT COALESCE(SUM(platform_fee),0) FROM contracts WHERE status IN ('active','expired') " +
                     "AND created_at BETWEEN ? AND ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fromDate + " 00:00:00");
            ps.setString(2, toDate + " 23:59:59");
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return BigDecimal.ZERO;
    }

    private Payment mapPayment(ResultSet rs) throws SQLException {
        Payment p = new Payment();
        p.setPaymentId(rs.getInt("payment_id"));
        p.setContractId(rs.getInt("contract_id"));
        p.setAptTitle(rs.getString("apt_title"));
        p.setPayerId(rs.getInt("payer_id"));
        p.setPayerName(rs.getString("payer_name"));
        p.setAmount(rs.getBigDecimal("amount"));
        p.setPaymentType(rs.getString("payment_type"));
        p.setPeriodMonth((Integer) rs.getObject("period_month"));
        p.setPaymentMethod(rs.getString("payment_method"));
        p.setTransactionCode(rs.getString("transaction_code"));
        p.setStatus(rs.getString("status"));
        p.setDueDate(rs.getDate("due_date"));
        p.setPaidDate(rs.getTimestamp("paid_date"));
        p.setNote(rs.getString("note"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        try { p.setTxRef(rs.getString("tx_ref")); } catch (SQLException ignored) {}
        return p;
    }
}
