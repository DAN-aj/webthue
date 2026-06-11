package com.rental.dao;

import com.rental.model.Review;
import com.rental.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ReviewDAO {

    /** Sentinel: findEligibleContractId() trả về giá trị này khi không có hợp đồng hợp lệ. */
    public static final int NOT_ELIGIBLE = -1;

    /**
     * Kiểm tra user đã từng có hợp đồng ở trạng thái 'active' hoặc 'expired' / 'terminated'
     * cho apartment này chưa — điều kiện cần để được viết review.
     *
     * @return contract_id nếu có (luôn ≥ 1), NOT_ELIGIBLE (-1) nếu không có
     */
    public int findEligibleContractId(int aptId, int userId) {
        String sql = "SELECT contract_id FROM contracts " +
                     "WHERE apt_id = ? AND tenant_id = ? " +
                     "AND status IN ('active','expired','terminated') " +
                     "ORDER BY created_at DESC LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("contract_id") : NOT_ELIGIBLE;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return NOT_ELIGIBLE;
        }
    }

    /**
     * Kiểm tra user đã review căn hộ này chưa (UNIQUE KEY uq_user_apt).
     */
    public boolean hasReviewed(int aptId, int userId) {
        String sql = "SELECT 1 FROM reviews WHERE apt_id = ? AND user_id = ? LIMIT 1";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Chèn review mới. Status = 'approved' (hiển thị ngay, không cần duyệt).
     * @return review_id mới tạo, hoặc -1 nếu lỗi
     */
    public int insert(Review r) {
        String sql = "INSERT INTO reviews (apt_id, user_id, contract_id, rating, comment, status) " +
                     "VALUES (?, ?, ?, ?, ?, 'approved')";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, r.getAptId());
            ps.setInt(2, r.getUserId());
            ps.setInt(3, r.getContractId());
            ps.setInt(4, r.getRating());
            ps.setString(5, r.getComment());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : -1;
            }
        } catch (SQLIntegrityConstraintViolationException e) {
            // vi phạm UNIQUE(user_id, apt_id) — đã review rồi
            return -2;
        } catch (SQLException e) {
            e.printStackTrace();
            return -1;
        }
    }

    /**
     * Lấy danh sách review đã duyệt (approved) cho một căn hộ, mới nhất trước.
     */
    public List<Review> getApprovedByAptId(int aptId) {
        String sql = "SELECT r.*, u.full_name AS reviewer_name " +
                     "FROM reviews r JOIN users u ON r.user_id = u.user_id " +
                     "WHERE r.apt_id = ? " +
                     "ORDER BY r.created_at DESC";
        List<Review> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(map(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Tính điểm trung bình (chỉ approved) của một căn hộ.
     * @return 0.0 nếu chưa có review nào
     */
    public double avgRating(int aptId) {
        String sql = "SELECT AVG(rating) FROM reviews WHERE apt_id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getDouble(1) : 0.0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return 0.0;
        }
    }

    /** Tổng số review của căn hộ */
    public int countApproved(int aptId) {
        String sql = "SELECT COUNT(*) FROM reviews WHERE apt_id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return 0;
        }
    }

    // ── Admin helpers ───────────────────────────────────────────────

    public List<Review> getPending() {
        return getByStatus("pending");
    }

    public int countByStatus(String status) {
        String sql = "SELECT COUNT(*) FROM reviews WHERE status = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return 0;
        }
    }

    public Review findById(int reviewId) {
        String sql = "SELECT r.*, u.full_name AS reviewer_name, a.title AS apt_title " +
                     "FROM reviews r " +
                     "JOIN users u ON r.user_id = u.user_id " +
                     "JOIN apartments a ON r.apt_id = a.apt_id " +
                     "WHERE r.review_id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, reviewId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapFull(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateStatus(int reviewId, String status) {
        String sql = "UPDATE reviews SET status = ? WHERE review_id = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, reviewId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<Review> getByStatus(String status) {
        String sql = "SELECT r.*, u.full_name AS reviewer_name, a.title AS apt_title " +
                     "FROM reviews r " +
                     "JOIN users u ON r.user_id = u.user_id " +
                     "JOIN apartments a ON r.apt_id = a.apt_id " +
                     "WHERE r.status = ? ORDER BY r.created_at DESC";
        List<Review> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapFull(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    private Review mapFull(ResultSet rs) throws SQLException {
        Review r = map(rs);
        try { r.setAptTitle(rs.getString("apt_title")); } catch (SQLException ignored) {}
        return r;
    }

    private Review map(ResultSet rs) throws SQLException {
        Review r = new Review();
        r.setReviewId(rs.getInt("review_id"));
        r.setAptId(rs.getInt("apt_id"));
        r.setUserId(rs.getInt("user_id"));
        r.setContractId(rs.getInt("contract_id"));
        r.setRating(rs.getInt("rating"));
        r.setComment(rs.getString("comment"));
        r.setStatus(rs.getString("status"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        String name = rs.getString("reviewer_name");
        if (name == null) name = "Ẩn danh";
        r.setReviewerName(name);
        r.setReviewerFirstLetter(name.isEmpty() ? "?" : String.valueOf(name.charAt(0)).toUpperCase());
        return r;
    }
}
