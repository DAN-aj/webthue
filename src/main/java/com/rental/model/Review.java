package com.rental.model;

import java.sql.Timestamp;

public class Review {
    private int       reviewId;
    private int       aptId;
    private int       userId;
    private int       contractId;
    private int       rating;        // 1–5
    private String    comment;
    private String    status;        // pending | approved | rejected
    private Timestamp createdAt;

    /* transient — JOIN từ users */
    private String    reviewerName;
    private String    reviewerFirstLetter;
    /* transient — JOIN từ apartments */
    private String    aptTitle;

    public int    getReviewId()            { return reviewId; }
    public void   setReviewId(int v)       { reviewId = v; }
    public int    getAptId()               { return aptId; }
    public void   setAptId(int v)          { aptId = v; }
    public int    getUserId()              { return userId; }
    public void   setUserId(int v)         { userId = v; }
    public int    getContractId()          { return contractId; }
    public void   setContractId(int v)     { contractId = v; }
    public int    getRating()              { return rating; }
    public void   setRating(int v)         { rating = v; }
    public String getComment()             { return comment; }
    public void   setComment(String v)     { comment = v; }
    public String getStatus()              { return status; }
    public void   setStatus(String v)      { status = v; }
    public Timestamp getCreatedAt()        { return createdAt; }
    public void   setCreatedAt(Timestamp v){ createdAt = v; }
    public String getReviewerName()        { return reviewerName; }
    public void   setReviewerName(String v){ reviewerName = v; }
    public String getReviewerFirstLetter() { return reviewerFirstLetter; }
    public void   setReviewerFirstLetter(String v){ reviewerFirstLetter = v; }
    public String getAptTitle()            { return aptTitle; }
    public void   setAptTitle(String v)    { aptTitle = v; }

    /** Trả về chuỗi ★★★★☆ tuỳ rating */
    public String getStars() {
        StringBuilder sb = new StringBuilder();
        for (int i = 1; i <= 5; i++) sb.append(i <= rating ? "★" : "☆");
        return sb.toString();
    }
}
