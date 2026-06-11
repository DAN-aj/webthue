package com.rental.dao;

import com.rental.model.Contract;
import com.rental.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ContractDAO {

    public int insert(Contract c) {
        String sql = "INSERT INTO contracts (apt_id, tenant_id, owner_id, rental_type, start_date, end_date, " +
                     "total_days, monthly_rent, deposit_amount, platform_fee, payment_period, tenant_cccd, status, notes) " +
                     "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'pending',?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, c.getAptId());
            ps.setInt(2, c.getTenantId());
            ps.setInt(3, c.getOwnerId());
            ps.setString(4, c.getRentalType());
            ps.setDate(5, c.getStartDate());
            ps.setDate(6, c.getEndDate());
            ps.setInt(7, c.getTotalDays());
            ps.setBigDecimal(8, c.getMonthlyRent());
            ps.setBigDecimal(9, c.getDepositAmount());
            ps.setBigDecimal(10, c.getPlatformFee());
            ps.setInt(11, c.getPaymentPeriod());
            ps.setString(12, c.getTenantCccd());
            ps.setString(13, c.getNotes());
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            if (keys.next()) return keys.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return -1;
    }

    public Contract findById(int contractId) {
        String sql = "SELECT c.*, a.title apt_title, a.address apt_address, " +
                     "(SELECT image_url FROM apartment_images WHERE apt_id=a.apt_id AND is_primary=TRUE LIMIT 1) apt_img, " +
                     "t.full_name tenant_name, t.email tenant_email, t.phone tenant_phone, " +
                     "o.full_name owner_name, o.phone owner_phone " +
                     "FROM contracts c JOIN apartments a ON c.apt_id=a.apt_id " +
                     "JOIN users t ON c.tenant_id=t.user_id " +
                     "JOIN users o ON c.owner_id=o.user_id " +
                     "WHERE c.contract_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contractId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapContract(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public List<Contract> getByTenantId(int tenantId) {
        return getByUserAndRole(tenantId, "tenant");
    }

    public List<Contract> getByOwnerId(int ownerId) {
        return getByUserAndRole(ownerId, "owner");
    }

    private List<Contract> getByUserAndRole(int userId, String role) {
        List<Contract> list = new ArrayList<>();
        String col = role.equals("tenant") ? "c.tenant_id" : "c.owner_id";
        String sql = "SELECT c.*, a.title apt_title, a.address apt_address, " +
                     "(SELECT image_url FROM apartment_images WHERE apt_id=a.apt_id AND is_primary=TRUE LIMIT 1) apt_img, " +
                     "t.full_name tenant_name, t.email tenant_email, t.phone tenant_phone, " +
                     "o.full_name owner_name, o.phone owner_phone " +
                     "FROM contracts c JOIN apartments a ON c.apt_id=a.apt_id " +
                     "JOIN users t ON c.tenant_id=t.user_id " +
                     "JOIN users o ON c.owner_id=o.user_id " +
                     "WHERE " + col + "=? ORDER BY c.created_at DESC";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapContract(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public boolean updateStatus(int contractId, String status) {
        String sql = "UPDATE contracts SET status=? WHERE contract_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, contractId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean hasActiveContract(int aptId) {
        String sql = "SELECT 1 FROM contracts WHERE apt_id=? AND status IN ('pending','approved','active')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            return ps.executeQuery().next();
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public int countAll() {
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM contracts")) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public int countActive() {
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM contracts WHERE status='active'")) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    private Contract mapContract(ResultSet rs) throws SQLException {
        Contract c = new Contract();
        c.setContractId(rs.getInt("contract_id"));
        c.setAptId(rs.getInt("apt_id"));
        c.setAptTitle(rs.getString("apt_title"));
        c.setAptAddress(rs.getString("apt_address"));
        c.setAptPrimaryImage(rs.getString("apt_img"));
        c.setTenantId(rs.getInt("tenant_id"));
        c.setTenantName(rs.getString("tenant_name"));
        c.setTenantEmail(rs.getString("tenant_email"));
        c.setTenantPhone(rs.getString("tenant_phone"));
        c.setTenantCccd(rs.getString("tenant_cccd"));
        c.setOwnerId(rs.getInt("owner_id"));
        c.setOwnerName(rs.getString("owner_name"));
        c.setOwnerPhone(rs.getString("owner_phone"));
        c.setRentalType(rs.getString("rental_type"));
        c.setStartDate(rs.getDate("start_date"));
        c.setEndDate(rs.getDate("end_date"));
        // Fallback: nếu total_days chưa có trong DB cũ, tính từ start/end date
        int totalDays = 0;
        try { totalDays = rs.getInt("total_days"); } catch (Exception ignored) {}
        if (totalDays <= 0 && c.getStartDate() != null && c.getEndDate() != null) {
            long diff = c.getEndDate().getTime() - c.getStartDate().getTime();
            totalDays = (int)(diff / 86400000L);
        }
        c.setTotalDays(totalDays);
        c.setMonthlyRent(rs.getBigDecimal("monthly_rent"));
        c.setDepositAmount(rs.getBigDecimal("deposit_amount"));
        c.setPlatformFee(rs.getBigDecimal("platform_fee"));
        c.setPaymentPeriod(rs.getInt("payment_period"));
        c.setStatus(rs.getString("status"));
        c.setNotes(rs.getString("notes"));
        c.setCreatedAt(rs.getTimestamp("created_at"));
        try { 
            c.setMoveInConfirmed(rs.getBoolean("move_in_confirmed")); 
            c.setMoveInConfirmedAt(rs.getTimestamp("move_in_confirmed_at"));
        } catch (Exception ignored) {}
        return c;
    }
    /** Thống kê hợp đồng mới theo tháng (12 tháng gần nhất) */
    public java.util.Map<String,Integer> getContractsByMonth() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT DATE_FORMAT(created_at,'%Y-%m') AS mon, COUNT(*) AS cnt " +
            "FROM contracts WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH) " +
            "GROUP BY mon ORDER BY mon";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) map.put(rs.getString("mon"), rs.getInt("cnt"));
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

    /** Thống kê hợp đồng theo loại: short vs long */
    public java.util.Map<String,Integer> getContractsByType() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT rental_type, COUNT(*) AS cnt FROM contracts GROUP BY rental_type";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) map.put(rs.getString("rental_type"), rs.getInt("cnt"));
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

    /** Thống kê hợp đồng theo status */
    public java.util.Map<String,Integer> getContractsByStatus() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT status, COUNT(*) AS cnt FROM contracts GROUP BY status ORDER BY cnt DESC";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) map.put(rs.getString("status"), rs.getInt("cnt"));
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

    /** Doanh thu phí nền tảng theo tháng */
    public java.util.Map<String,java.math.BigDecimal> getRevenueByMonth() {
        java.util.Map<String,java.math.BigDecimal> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT DATE_FORMAT(created_at,'%Y-%m') AS mon, " +
            "SUM(platform_fee) AS rev FROM contracts " +
            "WHERE status IN ('active','expired') AND created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH) " +
            "GROUP BY mon ORDER BY mon";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                java.math.BigDecimal v = rs.getBigDecimal("rev");
                map.put(rs.getString("mon"), v != null ? v : java.math.BigDecimal.ZERO);
            }
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

    /** Top căn hộ được thuê nhiều nhất */
    public java.util.List<String[]> getTopApartments(int limit) {
        java.util.List<String[]> list = new java.util.ArrayList<>();
        String sql = "SELECT a.title, COUNT(c.contract_id) AS cnt, a.district " +
            "FROM contracts c JOIN apartments a ON c.apt_id=a.apt_id " +
            "GROUP BY c.apt_id ORDER BY cnt DESC LIMIT " + limit;
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next())
                list.add(new String[]{rs.getString("title"), String.valueOf(rs.getInt("cnt")), rs.getString("district")});
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return list;
    }

    /** Thời gian cho thuê trung bình (ngày từ đăng → active) */
    public double getAvgDaysToRent() {
        String sql = "SELECT AVG(DATEDIFF(updated_at, created_at)) AS avg_days " +
            "FROM contracts WHERE status IN ('active','expired')";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getDouble("avg_days");
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return 0;
    }
    
    /** Đánh dấu khách đã xác nhận nhận nhà (không đổi status hợp đồng) */
    public boolean markMoveInConfirmed(int contractId) {
        String sql = "UPDATE contracts SET move_in_confirmed = TRUE, " +
                     "move_in_confirmed_at = NOW() WHERE contract_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, contractId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    /** Tỷ lệ hoàn thành theo tháng (expired / total) */
    public java.util.Map<String,Double> getCompletionRateByMonth() {
        java.util.Map<String,Double> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT DATE_FORMAT(created_at,'%Y-%m') AS mon, " +
            "COUNT(*) AS total, " +
            "SUM(CASE WHEN status='expired' THEN 1 ELSE 0 END) AS completed " +
            "FROM contracts WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH) " +
            "GROUP BY mon ORDER BY mon";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                int total = rs.getInt("total");
                int comp  = rs.getInt("completed");
                double rate = total > 0 ? Math.round(comp * 1000.0 / total) / 10.0 : 0;
                map.put(rs.getString("mon"), rate);
            }
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

    /** Doanh thu phí nền tảng theo tháng — logic 3 bậc mới */
    public java.util.Map<String,java.math.BigDecimal> getRevenueByMonthNew() {
        java.util.Map<String,java.math.BigDecimal> map = new java.util.LinkedHashMap<>();
        String sql =
            "SELECT DATE_FORMAT(created_at,'%Y-%m') AS mon, " +
            "SUM(CASE " +
            "  WHEN total_days <= 30 THEN monthly_rent * (total_days/30.0) * 0.10 " +
            "  WHEN total_days < 365 THEN monthly_rent * (total_days/30.0) / 12.0 " +
            "  ELSE monthly_rent " +
            "END) AS rev " +
            "FROM contracts WHERE status IN ('active','expired') " +
            "AND created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH) " +
            "GROUP BY mon ORDER BY mon";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                java.math.BigDecimal v = rs.getBigDecimal("rev");
                map.put(rs.getString("mon"), v != null ? v : java.math.BigDecimal.ZERO);
            }
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

    /** Tổng doanh thu nền tảng — logic 3 bậc mới */
    public java.math.BigDecimal getTotalRevenueNew() {
        String sql =
            "SELECT SUM(CASE " +
            "  WHEN total_days <= 30 THEN monthly_rent * (total_days/30.0) * 0.10 " +
            "  WHEN total_days < 365 THEN monthly_rent * (total_days/30.0) / 12.0 " +
            "  ELSE monthly_rent " +
            "END) FROM contracts WHERE status IN ('active','expired')";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                java.math.BigDecimal v = rs.getBigDecimal(1);
                return v != null ? v : java.math.BigDecimal.ZERO;
            }
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return java.math.BigDecimal.ZERO;
    }

    /** Hợp đồng pending > N ngày (pending delay) */
    public int countPendingOverDays(int days) {
        String sql = "SELECT COUNT(*) FROM contracts WHERE status='pending' " +
                     "AND DATEDIFF(NOW(), created_at) > " + days;
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return 0;
    }

    /** Doanh thu theo loại hợp đồng (short/long) — logic phí mới */
    public java.util.Map<String,java.math.BigDecimal> getRevenueByType() {
        java.util.Map<String,java.math.BigDecimal> map = new java.util.LinkedHashMap<>();
        String sql =
            "SELECT rental_type, SUM(CASE " +
            "  WHEN total_days <= 30 THEN monthly_rent * (total_days/30.0) * 0.10 " +
            "  WHEN total_days < 365 THEN monthly_rent * (total_days/30.0) / 12.0 " +
            "  ELSE monthly_rent " +
            "END) AS rev " +
            "FROM contracts WHERE status IN ('active','expired') GROUP BY rental_type";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                java.math.BigDecimal v = rs.getBigDecimal("rev");
                map.put(rs.getString("rental_type"), v != null ? v : java.math.BigDecimal.ZERO);
            }
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

}