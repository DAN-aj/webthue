package com.rental.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class ApartmentEditRequest {
    private int requestId;
    private int aptId;
    private int ownerId;
    private String aptTitle;      // tên hiện tại (để hiển thị)
    private String ownerName;

    // Dữ liệu mới đề xuất
    private String  newTitle;
    private String  newDescription;
    private BigDecimal newRentPriceMonth;
    private BigDecimal newRentPriceDay;
    private int     newDepositMonths;
    private int     newPaymentPeriod;
    private String  newAmenities;
    private int     newBedrooms;
    private int     newBathrooms;
    private float   newArea;

    private String  status; // pending, approved, rejected
    private String  rejectReason;
    private Timestamp createdAt;
    private Timestamp reviewedAt;

    public ApartmentEditRequest() {}

    // ── Getters & Setters ──────────────────────────────────────────
    public int getRequestId()  { return requestId; }
    public void setRequestId(int v) { requestId = v; }
    public int getAptId()      { return aptId; }
    public void setAptId(int v) { aptId = v; }
    public int getOwnerId()    { return ownerId; }
    public void setOwnerId(int v) { ownerId = v; }
    public String getAptTitle() { return aptTitle; }
    public void setAptTitle(String v) { aptTitle = v; }
    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String v) { ownerName = v; }

    public String  getNewTitle()       { return newTitle; }
    public void    setNewTitle(String v) { newTitle = v; }
    public String  getNewDescription() { return newDescription; }
    public void    setNewDescription(String v) { newDescription = v; }
    public BigDecimal getNewRentPriceMonth() { return newRentPriceMonth; }
    public void    setNewRentPriceMonth(BigDecimal v) { newRentPriceMonth = v; }
    public BigDecimal getNewRentPriceDay()   { return newRentPriceDay; }
    public void    setNewRentPriceDay(BigDecimal v)   { newRentPriceDay = v; }
    public int     getNewDepositMonths()  { return newDepositMonths; }
    public void    setNewDepositMonths(int v) { newDepositMonths = v; }
    public int     getNewPaymentPeriod()  { return newPaymentPeriod; }
    public void    setNewPaymentPeriod(int v) { newPaymentPeriod = v; }
    public String  getNewAmenities()  { return newAmenities; }
    public void    setNewAmenities(String v) { newAmenities = v; }
    public int     getNewBedrooms()   { return newBedrooms; }
    public void    setNewBedrooms(int v) { newBedrooms = v; }
    public int     getNewBathrooms()  { return newBathrooms; }
    public void    setNewBathrooms(int v) { newBathrooms = v; }
    public float   getNewArea()       { return newArea; }
    public void    setNewArea(float v)  { newArea = v; }

    public String getStatus()       { return status; }
    public void   setStatus(String v) { status = v; }
    public String getRejectReason() { return rejectReason; }
    public void   setRejectReason(String v) { rejectReason = v; }
    public Timestamp getCreatedAt()  { return createdAt; }
    public void setCreatedAt(Timestamp v) { createdAt = v; }
    public Timestamp getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(Timestamp v) { reviewedAt = v; }

    public String getStatusLabel() {
        if (status == null) return "";
        switch (status) {
            case "pending":  return "Chờ duyệt";
            case "approved": return "Đã duyệt";
            case "rejected": return "Bị từ chối";
            default: return status;
        }
    }
}