package com.rental.model;

import java.sql.Timestamp;

public class Notification {
    private int notiId;
    private int userId;
    private String title;
    private String message;
    private String type; // info, success, warning, payment, contract
    private boolean isRead;
    private Integer relatedId;
    private String relatedType;
    private Timestamp createdAt;

    public Notification() {}

    public int getNotiId() { return notiId; }
    public void setNotiId(int notiId) { this.notiId = notiId; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public boolean isRead() { return isRead; }
    public void setRead(boolean read) { isRead = read; }

    public Integer getRelatedId() { return relatedId; }
    public void setRelatedId(Integer relatedId) { this.relatedId = relatedId; }

    public String getRelatedType() { return relatedType; }
    public void setRelatedType(String relatedType) { this.relatedType = relatedType; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public String getIcon() {
        if (type == null) return "ℹ️";
        switch (type) {
            case "success":  return "✅";
            case "warning":  return "⚠️";
            case "payment":  return "💰";
            case "contract": return "📋";
            default:         return "ℹ️";
        }
    }
}
