package com.rental.model;

import java.sql.Timestamp;

public class User {
    private int userId;
    private String fullName;
    private String email;
    private String password;
    private String phone;
    private String cccd;
    private String avatar;
    private String role; // user, admin
    private String status; // active, locked
    private Timestamp createdAt;

    public User() {}

    public User(int userId, String fullName, String email, String phone, String role, String status) {
        this.userId = userId;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.role = role;
        this.status = status;
    }

    // Getters & Setters
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getCccd() { return cccd; }
    public void setCccd(String cccd) { this.cccd = cccd; }

    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public boolean isAdmin() { return "admin".equals(this.role); }
    public boolean isActive() { return "active".equals(this.status); }

    public String getAvatarUrl() {
        return (avatar != null && !avatar.isEmpty()) ? avatar :
                "https://ui-avatars.com/api/?name=" + fullName.replace(" ", "+") + "&background=2563eb&color=fff";
    }

    /** Safe first letter for avatar display */
    public String getFirstLetter() {
        if (fullName != null && !fullName.isEmpty()) return fullName.substring(0, 1).toUpperCase();
        return "?";
    }

}