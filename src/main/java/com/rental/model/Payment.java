package com.rental.model;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;

public class Payment {
    private int       paymentId;
    private int       contractId;
    private String    aptTitle;
    private int       payerId;
    private String    payerName;
    private BigDecimal amount;
    private String    paymentType;    // initial | periodic | deposit | penalty
    private Integer   periodMonth;
    private String    paymentMethod;  // bank_qr | card
    private String    transactionCode; // mã GD thật từ ngân hàng (SePay trả về)
    private String    txRef;           // mã nội dung CK của ta: HD{id}T{ts}
    private String    status;          // pending | success | failed
    private Date      dueDate;
    private Timestamp paidDate;
    private String    note;
    private Timestamp createdAt;

    public Payment() {}

    public int getPaymentId()                { return paymentId; }
    public void setPaymentId(int v)          { this.paymentId = v; }
    public int getContractId()               { return contractId; }
    public void setContractId(int v)         { this.contractId = v; }
    public String getAptTitle()              { return aptTitle; }
    public void setAptTitle(String v)        { this.aptTitle = v; }
    public int getPayerId()                  { return payerId; }
    public void setPayerId(int v)            { this.payerId = v; }
    public String getPayerName()             { return payerName; }
    public void setPayerName(String v)       { this.payerName = v; }
    public BigDecimal getAmount()            { return amount; }
    public void setAmount(BigDecimal v)      { this.amount = v; }
    public String getPaymentType()           { return paymentType; }
    public void setPaymentType(String v)     { this.paymentType = v; }
    public Integer getPeriodMonth()          { return periodMonth; }
    public void setPeriodMonth(Integer v)    { this.periodMonth = v; }
    public String getPaymentMethod()         { return paymentMethod; }
    public void setPaymentMethod(String v)   { this.paymentMethod = v; }
    public String getTransactionCode()       { return transactionCode; }
    public void setTransactionCode(String v) { this.transactionCode = v; }
    public String getTxRef()                 { return txRef; }
    public void setTxRef(String v)           { this.txRef = v; }
    public String getStatus()               { return status; }
    public void setStatus(String v)         { this.status = v; }
    public Date getDueDate()                { return dueDate; }
    public void setDueDate(Date v)          { this.dueDate = v; }
    public Timestamp getPaidDate()          { return paidDate; }
    public void setPaidDate(Timestamp v)    { this.paidDate = v; }
    public String getNote()                 { return note; }
    public void setNote(String v)           { this.note = v; }
    public Timestamp getCreatedAt()         { return createdAt; }
    public void setCreatedAt(Timestamp v)   { this.createdAt = v; }

    public String getPaymentTypeLabel() {
        if (paymentType == null) return "";
        switch (paymentType) {
            case "initial":  return "Thanh toán ban đầu";
            case "periodic": return "Thanh toán định kỳ";
            case "deposit":  return "Tiền cọc";
            case "penalty":  return "Phí phạt";
            default:         return paymentType;
        }
    }
    public String getStatusLabel() {
        if (status == null) return "";
        switch (status) {
            case "pending": return "Chờ thanh toán";
            case "success": return "Đã thanh toán";
            case "failed":  return "Thất bại";
            default:        return status;
        }
    }
}
