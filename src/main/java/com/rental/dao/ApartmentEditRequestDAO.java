package com.rental.dao;

import com.rental.model.ApartmentEditRequest;
import com.rental.util.DBConnection;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ApartmentEditRequestDAO {

    public int insert(ApartmentEditRequest r) {
        String sql = "INSERT INTO apartment_edit_requests " +
            "(apt_id, owner_id, new_title, new_description, new_rent_price_month, new_rent_price_day, " +
            "new_deposit_months, new_payment_period, new_amenities, new_bedrooms, new_bathrooms, new_area) " +
            "VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, r.getAptId());
            ps.setInt(2, r.getOwnerId());
            ps.setString(3, r.getNewTitle());
            ps.setString(4, r.getNewDescription()); // giữ trong edit_requests table nếu có
            ps.setBigDecimal(5, r.getNewRentPriceMonth());
            ps.setBigDecimal(6, r.getNewRentPriceDay());
            ps.setInt(7, r.getNewDepositMonths());
            ps.setInt(8, r.getNewPaymentPeriod());
            ps.setString(9, r.getNewAmenities());
            ps.setInt(10, r.getNewBedrooms());
            ps.setInt(11, r.getNewBathrooms());
            ps.setFloat(12, r.getNewArea());
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            if (keys.next()) return keys.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return -1;
    }

    public List<ApartmentEditRequest> getPending() {
        return query("WHERE r.status='pending' ORDER BY r.created_at DESC");
    }

    public List<ApartmentEditRequest> getByOwner(int ownerId) {
        List<ApartmentEditRequest> list = new ArrayList<>();
        String sql = "SELECT r.*, a.title apt_title, u.full_name owner_name " +
            "FROM apartment_edit_requests r " +
            "JOIN apartments a ON r.apt_id=a.apt_id " +
            "JOIN users u ON r.owner_id=u.user_id " +
            "WHERE r.owner_id=? ORDER BY r.created_at DESC";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, ownerId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(map(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public ApartmentEditRequest findById(int requestId) {
        String sql = "SELECT r.*, a.title apt_title, u.full_name owner_name " +
            "FROM apartment_edit_requests r " +
            "JOIN apartments a ON r.apt_id=a.apt_id " +
            "JOIN users u ON r.owner_id=u.user_id " +
            "WHERE r.request_id=?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, requestId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return map(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    /** Admin duyệt: cập nhật apartment (không update description vì bảng apartments không có cột này) */
    public boolean approve(int requestId, ApartmentEditRequest r) {
        String sqlApt = "UPDATE apartments SET " +
            "title=?, rent_price=?, rent_price_month=?, rent_price_day=?, " +
            "deposit_months=?, payment_period=?, amenities=?, bedrooms=?, bathrooms=?, area=? " +
            "WHERE apt_id=?";
        String sqlReq = "UPDATE apartment_edit_requests SET status='approved', reviewed_at=NOW() WHERE request_id=?";
        try (Connection c = DBConnection.getConnection()) {
            c.setAutoCommit(false);
            try (PreparedStatement ps = c.prepareStatement(sqlApt)) {
                ps.setString(1, r.getNewTitle());
                ps.setBigDecimal(2, r.getNewRentPriceMonth()); // backward-compat
                ps.setBigDecimal(3, r.getNewRentPriceMonth());
                ps.setBigDecimal(4, r.getNewRentPriceDay());
                ps.setInt(5, r.getNewDepositMonths());
                ps.setInt(6, r.getNewPaymentPeriod());
                ps.setString(7, r.getNewAmenities());
                ps.setInt(8, r.getNewBedrooms());
                ps.setInt(9, r.getNewBathrooms());
                ps.setFloat(10, r.getNewArea());
                ps.setInt(11, r.getAptId());
                ps.executeUpdate();
            }
            try (PreparedStatement ps = c.prepareStatement(sqlReq)) {
                ps.setInt(1, requestId); ps.executeUpdate();
            }
            c.commit(); return true;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean reject(int requestId, String reason) {
        String sql = "UPDATE apartment_edit_requests SET status='rejected', reject_reason=?, reviewed_at=NOW() WHERE request_id=?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, reason); ps.setInt(2, requestId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    private List<ApartmentEditRequest> query(String where) {
        List<ApartmentEditRequest> list = new ArrayList<>();
        String sql = "SELECT r.*, a.title apt_title, u.full_name owner_name " +
            "FROM apartment_edit_requests r " +
            "JOIN apartments a ON r.apt_id=a.apt_id " +
            "JOIN users u ON r.owner_id=u.user_id " + where;
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) list.add(map(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    private ApartmentEditRequest map(ResultSet rs) throws SQLException {
        ApartmentEditRequest r = new ApartmentEditRequest();
        r.setRequestId(rs.getInt("request_id"));
        r.setAptId(rs.getInt("apt_id"));
        r.setOwnerId(rs.getInt("owner_id"));
        r.setAptTitle(rs.getString("apt_title"));
        r.setOwnerName(rs.getString("owner_name"));
        r.setNewTitle(rs.getString("new_title"));
        r.setNewDescription(rs.getString("new_description"));
        r.setNewRentPriceMonth(rs.getBigDecimal("new_rent_price_month"));
        r.setNewRentPriceDay(rs.getBigDecimal("new_rent_price_day"));
        r.setNewDepositMonths(rs.getInt("new_deposit_months"));
        r.setNewPaymentPeriod(rs.getInt("new_payment_period"));
        r.setNewAmenities(rs.getString("new_amenities"));
        r.setNewBedrooms(rs.getInt("new_bedrooms"));
        r.setNewBathrooms(rs.getInt("new_bathrooms"));
        r.setNewArea(rs.getFloat("new_area"));
        r.setStatus(rs.getString("status"));
        r.setRejectReason(rs.getString("reject_reason"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        r.setReviewedAt(rs.getTimestamp("reviewed_at"));
        return r;
    }

    public int countPending() {
        try (Connection c = DBConnection.getConnection();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM apartment_edit_requests WHERE status='pending'")) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }
}
