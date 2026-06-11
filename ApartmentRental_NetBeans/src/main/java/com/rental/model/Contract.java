package com.rental.model;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Date;
import java.sql.Timestamp;

public class Contract {
    private int contractId;
    private int aptId;
    private String aptTitle;
    private String aptAddress;
    private String aptPrimaryImage;
    private int tenantId;
    private String tenantName;
    private String tenantEmail;
    private String tenantPhone;
    private String tenantCccd;
    private int ownerId;
    private String ownerName;
    private String ownerPhone;
    private String rentalType;
    private Date startDate;
    private Date endDate;
    private int totalDays;
    private BigDecimal monthlyRent;
    private BigDecimal depositAmount;
    private BigDecimal platformFee;
    private int paymentPeriod;
    private String status;
    private String notes;
    private Timestamp createdAt;

    public Contract() {}

    // ── Getters & Setters ─────────────────────────────────────────
    public int getContractId() { return contractId; }
    public void setContractId(int v) { contractId = v; }
    public int getAptId() { return aptId; }
    public void setAptId(int v) { aptId = v; }
    public String getAptTitle() { return aptTitle; }
    public void setAptTitle(String v) { aptTitle = v; }
    public String getAptAddress() { return aptAddress; }
    public void setAptAddress(String v) { aptAddress = v; }
    public String getAptPrimaryImage() { return aptPrimaryImage; }
    public void setAptPrimaryImage(String v) { aptPrimaryImage = v; }
    public int getTenantId() { return tenantId; }
    public void setTenantId(int v) { tenantId = v; }
    public String getTenantName() { return tenantName; }
    public void setTenantName(String v) { tenantName = v; }
    public String getTenantEmail() { return tenantEmail; }
    public void setTenantEmail(String v) { tenantEmail = v; }
    public String getTenantPhone() { return tenantPhone; }
    public void setTenantPhone(String v) { tenantPhone = v; }
    public String getTenantCccd() { return tenantCccd; }
    public void setTenantCccd(String v) { tenantCccd = v; }
    public int getOwnerId() { return ownerId; }
    public void setOwnerId(int v) { ownerId = v; }
    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String v) { ownerName = v; }
    public String getOwnerPhone() { return ownerPhone; }
    public void setOwnerPhone(String v) { ownerPhone = v; }
    public String getRentalType() { return rentalType; }
    public void setRentalType(String v) { rentalType = v; }
    public Date getStartDate() { return startDate; }
    public void setStartDate(Date v) { startDate = v; }
    public Date getEndDate() { return endDate; }
    public void setEndDate(Date v) { endDate = v; }
    public int getTotalDays() { return totalDays; }
    public void setTotalDays(int v) { totalDays = v; }
    public BigDecimal getMonthlyRent() { return monthlyRent; }
    public void setMonthlyRent(BigDecimal v) { monthlyRent = v; }
    public BigDecimal getDepositAmount() { return depositAmount; }
    public void setDepositAmount(BigDecimal v) { depositAmount = v; }
    public BigDecimal getPlatformFee() { return platformFee; }
    public void setPlatformFee(BigDecimal v) { platformFee = v; }
    public int getPaymentPeriod() { return paymentPeriod; }
    public void setPaymentPeriod(int v) { paymentPeriod = v; }
    public String getStatus() { return status; }
    public void setStatus(String v) { status = v; }
    public String getNotes() { return notes; }
    public void setNotes(String v) { notes = v; }
    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp v) { createdAt = v; }
    private boolean moveInConfirmed;
    private Timestamp moveInConfirmedAt;

    public boolean isMoveInConfirmed() { return moveInConfirmed; }
    public void setMoveInConfirmed(boolean v) { moveInConfirmed = v; }
    public Timestamp getMoveInConfirmedAt() { return moveInConfirmedAt; }
    public void setMoveInConfirmedAt(Timestamp v) { moveInConfirmedAt = v; }

    // ── Computed helpers ──────────────────────────────────────────

    /** Tổng tiền thuê cả hợp đồng (chưa tính phí, cọc)
     *  Ngắn hạn: đơn giá/ngày × số ngày
     *  Dài hạn:  đơn giá/tháng × số tháng */
    public BigDecimal getTotalRent() {
        if (monthlyRent == null || totalDays <= 0) return BigDecimal.ZERO;
        if ("short".equals(rentalType)) {
            // Ngắn hạn: đơn giá/ngày × số ngày
            return monthlyRent.multiply(BigDecimal.valueOf(totalDays));
        } else {
            // Dài hạn: tính theo tháng đầy đủ + ngày lẻ
            if (startDate == null || endDate == null) {
                // Fallback khi không có ngày
                double months = totalDays / 30.0;
                return monthlyRent.multiply(BigDecimal.valueOf(months))
                                  .setScale(0, RoundingMode.HALF_UP);
            }
            java.time.LocalDate start = startDate.toLocalDate();
            java.time.LocalDate end   = endDate.toLocalDate();
            java.time.LocalDate cur   = start;
            int fullMonths = 0;
            while (true) {
                java.time.LocalDate next = cur.plusMonths(1);
                if (next.isAfter(end)) break;
                fullMonths++;
                cur = next;
            }
            long remainDays = java.time.temporal.ChronoUnit.DAYS.between(cur, end);
            BigDecimal rentFull   = monthlyRent.multiply(BigDecimal.valueOf(fullMonths));
            BigDecimal rentRemain = remainDays > 0
                ? monthlyRent.multiply(BigDecimal.valueOf(remainDays))
                             .divide(BigDecimal.valueOf(30), 0, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;
            return rentFull.add(rentRemain);
        }
    }

    /** Thanh toán ban đầu:
     *  Ngắn hạn: tổng tiền thuê + phí nền tảng
     *  Dài hạn:  tháng đầu + tiền cọc */
    public BigDecimal getInitialPayment() {
        BigDecimal r = (monthlyRent   != null) ? monthlyRent   : BigDecimal.ZERO;
        BigDecimal d = (depositAmount != null) ? depositAmount : BigDecimal.ZERO;
        BigDecimal f = (platformFee   != null) ? platformFee   : BigDecimal.ZERO;
        if ("short".equals(rentalType) && totalDays > 0) {
            return getTotalRent().add(f);
        }
        return r.add(d);
    }

    /** Chữ cái đầu tên chủ nhà cho avatar */
    public String getFirstLetter() {
        if (ownerName != null && !ownerName.isEmpty())
            return ownerName.substring(0, 1).toUpperCase();
        return "?";
    }

    // ── Label helpers ─────────────────────────────────────────────
    public String getStatusLabel() {
        if (status == null) return "";
        switch (status) {
            case "pending":    return "Chờ chủ nhà xác nhận";
            case "approved":   return "Đã xác nhận — Chờ thanh toán";
            case "rejected":   return "Bị từ chối";
            case "active":     return "Đang có hiệu lực";
            case "expired":    return "Đã hết hạn";
            case "terminated": return "Đã chấm dứt";
            default:           return status;
        }
    }

    public String getRentalTypeLabel() {
        if (rentalType == null) return "";
        return "short".equals(rentalType) ? "Ngắn hạn" : "Dài hạn";
    }

    public String getStatusBadgeClass() {
        if (status == null) return "badge-dark";
        switch (status) {
            case "pending":    return "badge-amber";
            case "approved":   return "badge-accent";
            case "active":     return "badge-green";
            case "rejected":
            case "terminated": return "badge-red";
            case "expired":    return "badge-dark";
            default:           return "badge-dark";
        }
    }
}