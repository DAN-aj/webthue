package com.rental.dao;

import com.rental.model.User;
import com.rental.util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * UserDAO - Không dùng mã hóa mật khẩu (plain text)
 * Phù hợp cho môi trường demo/development
 */
public class UserDAO {

    public User findByEmail(String email) {
        String sql = "SELECT * FROM users WHERE email = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapUser(rs);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public User findById(int userId) {
        String sql = "SELECT * FROM users WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapUser(rs);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public boolean register(User user) {
        String sql = "INSERT INTO users (full_name, email, password, phone, role, status) VALUES (?,?,?,?,'user','active')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, user.getFullName());
            ps.setString(2, user.getEmail());
            ps.setString(3, user.getPassword()); // plain text
            ps.setString(4, user.getPhone());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    /**
     * Xác thực đăng nhập - so sánh plain text trực tiếp
     */
    public User authenticate(String email, String password) {
        User user = findByEmail(email);
        if (user == null || password == null) return null;

        String stored = user.getPassword();
        if (stored == null) return null;

        // So sánh plain text trực tiếp
        if (stored.equals(password)) {
            return user;
        }

        return null;
    }

    public boolean emailExists(String email) {
        String sql = "SELECT 1 FROM users WHERE email = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public List<User> getAllCustomers() {
        List<User> users = new ArrayList<>();
        String sql = "SELECT * FROM users WHERE role = 'user' ORDER BY created_at DESC LIMIT 200";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) users.add(mapUser(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return users;
    }

    public List<User> searchCustomers(String keyword, String status, int page, int pageSize) {
        StringBuilder sql = new StringBuilder(
            "SELECT * FROM users WHERE role='user' ");
        List<Object> params = new ArrayList<>();
        if (keyword != null && !keyword.isBlank()) {
            sql.append("AND (full_name LIKE ? OR email LIKE ? OR phone LIKE ?) ");
            String kw = "%" + keyword.trim() + "%";
            params.add(kw); params.add(kw); params.add(kw);
        }
        if (status != null && !status.isBlank()) {
            sql.append("AND status=? "); params.add(status);
        }
        sql.append("ORDER BY created_at DESC LIMIT ? OFFSET ?");
        params.add(pageSize); params.add((page - 1) * pageSize);
        List<User> users = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) users.add(mapUser(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return users;
    }

    public int countSearchCustomers(String keyword, String status) {
        StringBuilder sql = new StringBuilder(
            "SELECT COUNT(*) FROM users WHERE role='user' ");
        List<Object> params = new ArrayList<>();
        if (keyword != null && !keyword.isBlank()) {
            sql.append("AND (full_name LIKE ? OR email LIKE ? OR phone LIKE ?) ");
            String kw = "%" + keyword.trim() + "%";
            params.add(kw); params.add(kw); params.add(kw);
        }
        if (status != null && !status.isBlank()) {
            sql.append("AND status=? "); params.add(status);
        }
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public boolean updateStatus(int userId, String status) {
        String sql = "UPDATE users SET status = ? WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean deleteUser(int userId) {
        String sql = "DELETE FROM users WHERE user_id = ? AND role != 'admin'";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean updateProfile(User user) {
        String sql = "UPDATE users SET full_name=?, phone=?, cccd=? WHERE user_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, user.getFullName());
            ps.setString(2, user.getPhone());
            ps.setString(3, user.getCccd());
            ps.setInt(4, user.getUserId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public int countAll() {
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM users WHERE role='user'")) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    private User mapUser(ResultSet rs) throws SQLException {
        User u = new User();
        u.setUserId(rs.getInt("user_id"));
        u.setFullName(rs.getString("full_name"));
        u.setEmail(rs.getString("email"));
        u.setPassword(rs.getString("password"));
        u.setPhone(rs.getString("phone"));
        u.setCccd(rs.getString("cccd"));
        u.setRole(rs.getString("role"));
        u.setStatus(rs.getString("status"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        return u;
    }
    /** Người dùng mới đăng ký theo tháng */
    public java.util.Map<String,Integer> getNewUsersByMonth() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT DATE_FORMAT(created_at,'%Y-%m') AS mon, COUNT(*) AS cnt " +
            "FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH) " +
            "GROUP BY mon ORDER BY mon";
        try (Connection conn = DBConnection.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(sql);
             java.sql.ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getString("mon"), rs.getInt("cnt"));
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

    /** Đếm user theo role */
    public java.util.Map<String,Integer> getUsersByRole() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT role, COUNT(*) AS cnt FROM users GROUP BY role";
        try (Connection conn = DBConnection.getConnection();
             java.sql.Statement st = conn.createStatement();
             java.sql.ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) map.put(rs.getString("role"), rs.getInt("cnt"));
        } catch (java.sql.SQLException e) { e.printStackTrace(); }
        return map;
    }

}