package com.rental.model;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class Apartment {
    private int aptId;
    private int ownerId;
    private String ownerName, ownerPhone, ownerEmail;
    private String title, address, district, city;
    private String type; // studio, 1br, 2br, 3br
    private float area;
    private int floor, totalFloors, bedrooms, bathrooms;
    private String furniture;   // nội thất
    private String direction;   // hướng
    private String view;        // view
    // Giá linh hoạt
    private BigDecimal rentPrice;
    private BigDecimal rentPriceMonth;
    private BigDecimal rentPriceDay;
    private int depositMonths;
    private String rentalType; // short, long, both
    private int paymentPeriod;
    private String amenities;
    private String description; // mô tả chi tiết căn hộ
    private String status; // pending, approved, rejected, rented, unavailable
    private int viewCount;
    private Timestamp createdAt, updatedAt;
    private List<String> images;
    private String primaryImage;

    public Apartment() {}

    public int    getAptId()    { return aptId; }
    public void   setAptId(int v) { aptId = v; }
    public int    getOwnerId()  { return ownerId; }
    public void   setOwnerId(int v) { ownerId = v; }
    public String getOwnerName()  { return ownerName; }
    public void   setOwnerName(String v)  { ownerName = v; }
    public String getOwnerPhone() { return ownerPhone; }
    public void   setOwnerPhone(String v) { ownerPhone = v; }
    public String getOwnerEmail() { return ownerEmail; }
    public void   setOwnerEmail(String v) { ownerEmail = v; }
    public String getTitle()    { return title; }
    public void   setTitle(String v) { title = v; }
    public String getAddress()  { return address; }
    public void   setAddress(String v) { address = v; }
    public String getDistrict() { return district; }
    public void   setDistrict(String v) { district = v; }
    public String getCity()     { return city; }
    public void   setCity(String v) { city = v; }
    public String getType()     { return type; }
    public void   setType(String v) { type = v; }
    public float  getArea()     { return area; }
    public void   setArea(float v) { area = v; }
    public int    getFloor()    { return floor; }
    public void   setFloor(int v) { floor = v; }
    public int    getTotalFloors() { return totalFloors; }
    public void   setTotalFloors(int v) { totalFloors = v; }
    public int    getBedrooms() { return bedrooms; }
    public void   setBedrooms(int v) { bedrooms = v; }
    public int    getBathrooms(){ return bathrooms; }
    public void   setBathrooms(int v) { bathrooms = v; }
    public String getFurniture() { return furniture; }
    public void   setFurniture(String v) { furniture = v; }
    public String getDirection() { return direction; }
    public void   setDirection(String v) { direction = v; }
    public String getView()     { return view; }
    public void   setView(String v) { view = v; }

    public BigDecimal getRentPrice()      { return rentPrice; }
    public void       setRentPrice(BigDecimal v) { rentPrice = v; }
    public BigDecimal getRentPriceMonth() { return rentPriceMonth; }
    public void       setRentPriceMonth(BigDecimal v) { rentPriceMonth = v; }
    public BigDecimal getRentPriceDay()   { return rentPriceDay; }
    public void       setRentPriceDay(BigDecimal v)   { rentPriceDay = v; }

    public int    getDepositMonths()    { return depositMonths; }
    public void   setDepositMonths(int v) { depositMonths = v; }
    public String getRentalType()       { return rentalType; }
    public void   setRentalType(String v) { rentalType = v; }
    public int    getPaymentPeriod()    { return paymentPeriod; }
    public void   setPaymentPeriod(int v) { paymentPeriod = v; }
    public String getAmenities()        { return amenities; }
    public void   setAmenities(String v) { amenities = v; }
    public String getDescription()      { return description; }
    public void   setDescription(String v) { description = v; }
    public String getStatus()           { return status; }
    public void   setStatus(String v)   { status = v; }
    public int    getViewCount()        { return viewCount; }
    public void   setViewCount(int v)   { viewCount = v; }
    public Timestamp getCreatedAt()     { return createdAt; }
    public void   setCreatedAt(Timestamp v) { createdAt = v; }
    public Timestamp getUpdatedAt()     { return updatedAt; }
    public void   setUpdatedAt(Timestamp v) { updatedAt = v; }
    public List<String> getImages()     { return images; }
    public void   setImages(List<String> v) { images = v; }
    public String getPrimaryImage()     { return primaryImage; }
    public void   setPrimaryImage(String v) { primaryImage = v; }

    // ── Computed Helpers ──────────────────────────────────────────
    public String getFirstLetter() {
        return (ownerName != null && !ownerName.isEmpty())
            ? ownerName.substring(0, 1).toUpperCase() : "?";
    }

    public BigDecimal getDepositTotal() {
        BigDecimal base = (rentPriceMonth != null) ? rentPriceMonth
                        : (rentPrice != null)      ? rentPrice : BigDecimal.ZERO;
        return base.multiply(BigDecimal.valueOf(depositMonths));
    }

    public String getFormattedPrice() {
        BigDecimal price = (rentPriceMonth != null) ? rentPriceMonth : rentPrice;
        if (price == null) return "Liên hệ";
        long val = price.longValue();
        if (val >= 1_000_000) {
            double m = val / 1_000_000.0;
            return (m == Math.floor(m))
                ? String.format("%,.0f triệu/tháng", m)
                : String.format("%.1f triệu/tháng", m);
        }
        return String.format("%,d ₫/tháng", val);
    }

    public String getFormattedDayPrice() {
        if (rentPriceDay == null) return null;
        long val = rentPriceDay.longValue();
        if (val >= 1_000_000) return String.format("%.1f triệu/ngày", val / 1_000_000.0);
        return String.format("%,d ₫/ngày", val);
    }

    /**
     * Số tháng thuê tối thiểu:
     * - Ngắn hạn (short): không áp dụng → 0
     * - Dài hạn (long/both): bằng paymentPeriod, tối thiểu 1 tháng
     */
    public int getMinRentalMonths() {
        if ("short".equals(rentalType)) return 0;
        return paymentPeriod > 0 ? paymentPeriod : 1;
    }

    public boolean isShortTermAvailable() {
        return "short".equals(rentalType) || "both".equals(rentalType);
    }

    public boolean isLongTermAvailable() {
        return "long".equals(rentalType) || "both".equals(rentalType);
    }

    /** Amenities là chuỗi text CSV thường (VD: "Wifi, Máy giặt, Điều hòa") */
    public List<String> getAmenitiesList() {
        List<String> list = new ArrayList<>();
        if (amenities == null || amenities.isBlank()) return list;
        for (String token : amenities.split(",")) {
            String item = token.trim();
            if (!item.isEmpty()) list.add(item);
        }
        return list;
    }

    public String getTypeLabel() {
        if (type == null) return "";
        switch (type) {
            case "studio":    return "Studio";
            case "1br":       return "1 Phòng ngủ";
            case "2br":       return "2 Phòng ngủ";
            case "3br":       return "3 Phòng ngủ";
            default:          return type;
        }
    }

    public String getRentalTypeLabel() {
        if (rentalType == null) return "";
        switch (rentalType) {
            case "short": return "Ngắn hạn";
            case "long":  return "Dài hạn";
            case "both":  return "Ngắn & Dài hạn";
            default:      return rentalType;
        }
    }

    public String getStatusLabel() {
        if (status == null) return "";
        switch (status) {
            case "pending":     return "Chờ duyệt";
            case "approved":    return "Đang cho thuê";
            case "rejected":    return "Bị từ chối";
            case "rented":      return "Đã cho thuê";
            case "unavailable": return "Không khả dụng";
            default:            return status;
        }
    }
}
