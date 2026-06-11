package com.rental.dao;

import com.rental.model.Apartment;
import com.rental.util.DBConnection;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ApartmentDAO {

    // PERF v13: Thay correlated subquery bằng LEFT JOIN — tránh N+1 queries
    // Correlated subquery chạy 1 lần/row → 50 rows = 51 queries
    // LEFT JOIN chạy 1 lần cho toàn bộ result set
    private static final String BASE_SELECT =
        "SELECT a.*, u.full_name owner_name, u.phone owner_phone, u.email owner_email, " +
        "img.image_url primary_image ";

    private static final String BASE_FROM =
        "FROM apartments a " +
        "JOIN users u ON a.owner_id=u.user_id " +
        "LEFT JOIN apartment_images img ON img.apt_id=a.apt_id AND img.is_primary=TRUE ";

    // ── SEARCH ───────────────────────────────────────────────────
    public List<Apartment> search(String keyword, String district, String rentalType,
                                  BigDecimal minPrice, BigDecimal maxPrice,
                                  Float minArea, Float maxArea, String type) {
        return search(keyword, district, rentalType, minPrice, maxPrice, minArea, maxArea, type, 1, 20);
    }

    public List<Apartment> search(String keyword, String district, String rentalType,
                                  BigDecimal minPrice, BigDecimal maxPrice,
                                  Float minArea, Float maxArea, String type,
                                  int page, int pageSize) {
        List<Apartment> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(BASE_SELECT).append(BASE_FROM)
            .append("WHERE a.status='approved' ");
        List<Object> params = new ArrayList<>();

        if (keyword != null && !keyword.isBlank()) {
            sql.append("AND (a.title LIKE ? OR a.district LIKE ? OR a.city LIKE ? OR a.amenities LIKE ?) ");
            params.add("%" + keyword + "%"); params.add("%" + keyword + "%");
            params.add("%" + keyword + "%"); params.add("%" + keyword + "%");
        }
        if (district != null && !district.isBlank()) {
            sql.append("AND a.district LIKE ? "); params.add("%" + district + "%");
        }
        if (rentalType != null && !rentalType.isBlank() && !"all".equals(rentalType)) {
            sql.append("AND (a.rental_type=? OR a.rental_type='both') ");
            params.add(rentalType);
        }
        if (minPrice != null) {
            sql.append("AND COALESCE(a.rent_price_month, a.rent_price) >= ? "); params.add(minPrice);
        }
        if (maxPrice != null) {
            sql.append("AND COALESCE(a.rent_price_month, a.rent_price) <= ? "); params.add(maxPrice);
        }
        if (minArea != null) { sql.append("AND a.area >= ? "); params.add(minArea); }
        if (maxArea != null) { sql.append("AND a.area <= ? "); params.add(maxArea); }
        if (type != null && !type.isBlank() && !"all".equals(type)) {
            sql.append("AND a.type=? "); params.add(type);
        }
        sql.append("ORDER BY a.created_at DESC LIMIT ? OFFSET ?");
        params.add(pageSize);
        params.add((page - 1) * pageSize);

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapApartment(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public int countSearch(String keyword, String district, String rentalType,
                           BigDecimal minPrice, BigDecimal maxPrice,
                           Float minArea, Float maxArea, String type) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM apartments a WHERE a.status='approved' ");
        List<Object> params = new ArrayList<>();

        if (keyword != null && !keyword.isBlank()) {
            sql.append("AND (a.title LIKE ? OR a.district LIKE ? OR a.city LIKE ? OR a.amenities LIKE ?) ");
            params.add("%" + keyword + "%"); params.add("%" + keyword + "%");
            params.add("%" + keyword + "%"); params.add("%" + keyword + "%");
        }
        if (district != null && !district.isBlank()) {
            sql.append("AND a.district LIKE ? "); params.add("%" + district + "%");
        }
        if (rentalType != null && !rentalType.isBlank() && !"all".equals(rentalType)) {
            sql.append("AND (a.rental_type=? OR a.rental_type='both') ");
            params.add(rentalType);
        }
        if (minPrice != null) {
            sql.append("AND COALESCE(a.rent_price_month, a.rent_price) >= ? "); params.add(minPrice);
        }
        if (maxPrice != null) {
            sql.append("AND COALESCE(a.rent_price_month, a.rent_price) <= ? "); params.add(maxPrice);
        }
        if (minArea != null) { sql.append("AND a.area >= ? "); params.add(minArea); }
        if (maxArea != null) { sql.append("AND a.area <= ? "); params.add(maxArea); }
        if (type != null && !type.isBlank() && !"all".equals(type)) {
            sql.append("AND a.type=? "); params.add(type);
        }

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    // ── FIND BY ID ────────────────────────────────────────────────
    public Apartment findById(int aptId) {
        String sql = BASE_SELECT + BASE_FROM + "WHERE a.apt_id=?";
        // FIX: Dung 1 connection duy nhat cho ca apartment + images
        // Tranh tao 2 connection rieng co the gay pool timeout -> ERR_INCOMPLETE_CHUNKED_ENCODING
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Apartment apt = mapApartment(rs);
                apt.setImages(getImagesWithConn(conn, aptId)); // dung conn san co
                return apt;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    /** Dung khi da co connection (tranh mo them connection moi) */
    private List<String> getImagesWithConn(Connection conn, int aptId) {
        List<String> images = new ArrayList<>();
        String sql = "SELECT image_url FROM apartment_images WHERE apt_id=? ORDER BY is_primary DESC, image_id";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) images.add(rs.getString("image_url"));
        } catch (SQLException e) { e.printStackTrace(); }
        return images;
    }

    /** Public overload - dung khi can load images doc lap (khong co conn san) */
    public List<String> getImages(int aptId) {
        List<String> images = new ArrayList<>();
        String sql = "SELECT image_url FROM apartment_images WHERE apt_id=? ORDER BY is_primary DESC, image_id";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, aptId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) images.add(rs.getString("image_url"));
        } catch (SQLException e) { e.printStackTrace(); }
        return images;
    }

    // ── INSERT ────────────────────────────────────────────────────
    public int insert(Apartment apt) {
        String sql = "INSERT INTO apartments " +
            "(owner_id,title,address,district,city,type,area,floor,total_floors,bedrooms,bathrooms," +
            "furniture,direction,view,amenities," +
            "rent_price,rent_price_month,rent_price_day,deposit_months,rental_type," +
            "payment_period,status) " +
            "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'pending')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, apt.getOwnerId());
            ps.setString(2, apt.getTitle());
            ps.setString(3, apt.getAddress());
            ps.setString(4, apt.getDistrict());
            ps.setString(5, apt.getCity() != null ? apt.getCity() : "Hà Nội");
            ps.setString(6, apt.getType());
            ps.setFloat(7, apt.getArea());
            ps.setInt(8, apt.getFloor());
            ps.setInt(9, apt.getTotalFloors());
            ps.setInt(10, apt.getBedrooms());
            ps.setInt(11, apt.getBathrooms());
            ps.setString(12, apt.getFurniture());
            ps.setString(13, apt.getDirection());
            ps.setString(14, apt.getView());
            ps.setString(15, apt.getAmenities() != null ? apt.getAmenities() : "");
            BigDecimal pm = apt.getRentPriceMonth() != null ? apt.getRentPriceMonth() : apt.getRentPrice();
            ps.setBigDecimal(16, pm);
            ps.setBigDecimal(17, apt.getRentPriceMonth());
            ps.setBigDecimal(18, apt.getRentPriceDay());
            ps.setInt(19, apt.getDepositMonths());
            ps.setString(20, apt.getRentalType());
            ps.setInt(21, apt.getPaymentPeriod());
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            if (keys.next()) return keys.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return -1;
    }

    public boolean addImage(int aptId, String imageUrl, boolean isPrimary) {
        String sql = "INSERT INTO apartment_images (apt_id, image_url, is_primary) VALUES (?,?,?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, aptId); ps.setString(2, imageUrl); ps.setBoolean(3, isPrimary);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ── LIST QUERIES ──────────────────────────────────────────────
    public List<Apartment> getByOwnerId(int ownerId) {
        return getByOwnerId(ownerId, 1, 50);
    }

    public List<Apartment> getByOwnerId(int ownerId, int page, int pageSize) {
        List<Apartment> list = new ArrayList<>();
        String sql = BASE_SELECT + BASE_FROM +
            "WHERE a.owner_id=? ORDER BY a.created_at DESC LIMIT ? OFFSET ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, ownerId);
            ps.setInt(2, pageSize);
            ps.setInt(3, (page - 1) * pageSize);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapApartment(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public int countByOwnerId(int ownerId) {
        String sql = "SELECT COUNT(*) FROM apartments WHERE owner_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, ownerId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public List<Apartment> getPending() {
        return getPending(1, 50);
    }

    public List<Apartment> getPending(int page, int pageSize) {
        List<Apartment> list = new ArrayList<>();
        String sql = BASE_SELECT + BASE_FROM +
            "WHERE a.status='pending' ORDER BY a.created_at DESC LIMIT ? OFFSET ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, pageSize);
            ps.setInt(2, (page - 1) * pageSize);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapApartment(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<Apartment> getAll() {
        return getAll(1, 50);
    }

    public List<Apartment> getAll(int page, int pageSize) {
        List<Apartment> list = new ArrayList<>();
        String sql = BASE_SELECT + BASE_FROM +
            "ORDER BY a.created_at DESC LIMIT ? OFFSET ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, pageSize);
            ps.setInt(2, (page - 1) * pageSize);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapApartment(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // ── UPDATE ────────────────────────────────────────────────────
    public boolean updateStatus(int aptId, String status, String reason) {
        // reason bị bỏ qua vì DB không có cột reject_reason
        String sql = "UPDATE apartments SET status=? WHERE apt_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status); ps.setInt(2, aptId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean incrementView(int aptId) {
        String sql = "UPDATE apartments SET view_count=view_count+1 WHERE apt_id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, aptId); return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ── COUNT ─────────────────────────────────────────────────────
    public int countByStatus(String status) {
        String sql = "SELECT COUNT(*) FROM apartments WHERE status=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status); ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public int countAll() {
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM apartments")) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    /**
     * Admin search: lọc theo keyword (title, district, city, tên chủ nhà, email)
     * và/hoặc status, có phân trang.
     */
    public List<Apartment> adminSearch(String keyword, String status, int page, int pageSize) {
        StringBuilder sql = new StringBuilder(BASE_SELECT).append(BASE_FROM).append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (keyword != null && !keyword.isBlank()) {
            sql.append("AND (a.title LIKE ? OR a.district LIKE ? OR a.city LIKE ? " +
                       "OR u.full_name LIKE ? OR u.email LIKE ? OR u.phone LIKE ?) ");
            String kw = "%" + keyword.trim() + "%";
            params.add(kw); params.add(kw); params.add(kw);
            params.add(kw); params.add(kw); params.add(kw);
        }
        if (status != null && !status.isBlank() && !"all".equals(status)) {
            sql.append("AND a.status=? "); params.add(status);
        }
        sql.append("ORDER BY a.created_at DESC LIMIT ? OFFSET ?");
        params.add(pageSize); params.add((page - 1) * pageSize);
        List<Apartment> list = new ArrayList<>();
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapApartment(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public int countAdminSearch(String keyword, String status) {
        StringBuilder sql = new StringBuilder(
            "FROM apartments a JOIN users u ON a.owner_id=u.user_id WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (keyword != null && !keyword.isBlank()) {
            sql.append("AND (a.title LIKE ? OR a.district LIKE ? OR a.city LIKE ? " +
                       "OR u.full_name LIKE ? OR u.email LIKE ? OR u.phone LIKE ?) ");
            String kw = "%" + keyword.trim() + "%";
            params.add(kw); params.add(kw); params.add(kw);
            params.add(kw); params.add(kw); params.add(kw);
        }
        if (status != null && !status.isBlank() && !"all".equals(status)) {
            sql.append("AND a.status=? "); params.add(status);
        }
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) " + sql)) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    // ── ACTIVE CONTRACT CHECK ─────────────────────────────────────
    public boolean hasActiveContract(int aptId, int userId) {
        String sql = "SELECT 1 FROM contracts WHERE apt_id=? AND tenant_id=? AND status IN ('active','approved')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, aptId); ps.setInt(2, userId);
            return ps.executeQuery().next();
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean hasActiveContractForApt(int aptId) {
        String sql = "SELECT 1 FROM contracts WHERE apt_id=? AND status IN ('pending','approved','active')";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, aptId); return ps.executeQuery().next();
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ── DISTRICTS FOR FILTER ──────────────────────────────────────
    public List<String> getDistincts() {
        List<String> list = new ArrayList<>();
        String sql = "SELECT DISTINCT district FROM apartments WHERE status='approved' AND district IS NOT NULL ORDER BY district";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) { String d = rs.getString(1); if (d != null && !d.isBlank()) list.add(d); }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // ── FEATURED (trang chủ) ──────────────────────────────────────
    public List<Apartment> getFeatured(int limit) {
        List<Apartment> list = new ArrayList<>();
        String sql = BASE_SELECT + BASE_FROM + "WHERE a.status='approved' ORDER BY a.view_count DESC, a.created_at DESC LIMIT ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapApartment(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // ── MAPPER ────────────────────────────────────────────────────
    private Apartment mapApartment(ResultSet rs) throws SQLException {
        Apartment a = new Apartment();
        a.setAptId(rs.getInt("apt_id"));
        a.setOwnerId(rs.getInt("owner_id"));
        a.setOwnerName(rs.getString("owner_name"));
        a.setOwnerPhone(rs.getString("owner_phone"));
        a.setOwnerEmail(rs.getString("owner_email"));
        a.setTitle(rs.getString("title"));
        a.setAddress(rs.getString("address"));
        a.setDistrict(rs.getString("district"));
        a.setCity(rs.getString("city"));
        a.setType(rs.getString("type"));
        a.setArea(rs.getFloat("area"));
        a.setFloor(rs.getInt("floor"));
        a.setTotalFloors(rs.getInt("total_floors"));
        a.setBedrooms(rs.getInt("bedrooms"));
        a.setBathrooms(rs.getInt("bathrooms"));
        a.setFurniture(rs.getString("furniture"));
        a.setDirection(rs.getString("direction"));
        a.setView(rs.getString("view"));

        BigDecimal priceMonth = rs.getBigDecimal("rent_price_month");
        BigDecimal priceDay   = rs.getBigDecimal("rent_price_day");
        BigDecimal priceBase  = rs.getBigDecimal("rent_price");
        a.setRentPrice(priceMonth != null ? priceMonth : priceBase);
        a.setRentPriceMonth(priceMonth != null ? priceMonth : priceBase);
        a.setRentPriceDay(priceDay);

        a.setDepositMonths(rs.getInt("deposit_months"));
        a.setRentalType(rs.getString("rental_type"));
        a.setPaymentPeriod(rs.getInt("payment_period"));
        a.setAmenities(rs.getString("amenities"));
        try { a.setDescription(rs.getString("description")); } catch (Exception ignored) {}
        a.setStatus(rs.getString("status"));
        a.setViewCount(rs.getInt("view_count"));
        a.setCreatedAt(rs.getTimestamp("created_at"));
        // updated_at optional
        try { a.setUpdatedAt(rs.getTimestamp("updated_at")); } catch (Exception ignored) {}
        a.setPrimaryImage(rs.getString("primary_image"));
        return a;
    }

    // ── STATISTICS ────────────────────────────────────────────────
    public java.util.Map<String,Integer> getApartmentsByCity() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT city, COUNT(*) AS cnt FROM apartments WHERE status='approved' GROUP BY city ORDER BY cnt DESC LIMIT 8";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) map.put(rs.getString("city"), rs.getInt("cnt"));
        } catch (SQLException e) { e.printStackTrace(); }
        return map;
    }

    public java.util.Map<String,Integer> getApartmentsByType() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT type, COUNT(*) AS cnt FROM apartments WHERE status='approved' GROUP BY type ORDER BY cnt DESC";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) map.put(rs.getString("type"), rs.getInt("cnt"));
        } catch (SQLException e) { e.printStackTrace(); }
        return map;
    }

    public java.util.Map<String,Integer> getPriceDistribution() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT " +
            "SUM(CASE WHEN rent_price_month < 5000000  THEN 1 ELSE 0 END) AS lt5, " +
            "SUM(CASE WHEN rent_price_month BETWEEN 5000000  AND 9999999  THEN 1 ELSE 0 END) AS r5_10, " +
            "SUM(CASE WHEN rent_price_month BETWEEN 10000000 AND 19999999 THEN 1 ELSE 0 END) AS r10_20, " +
            "SUM(CASE WHEN rent_price_month BETWEEN 20000000 AND 49999999 THEN 1 ELSE 0 END) AS r20_50, " +
            "SUM(CASE WHEN rent_price_month >= 50000000 THEN 1 ELSE 0 END) AS gte50 " +
            "FROM apartments WHERE status='approved'";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                map.put("Dưới 5 triệu",  rs.getInt("lt5"));
                map.put("5 - 10 triệu",  rs.getInt("r5_10"));
                map.put("10 - 20 triệu", rs.getInt("r10_20"));
                map.put("20 - 50 triệu", rs.getInt("r20_50"));
                map.put("Trên 50 triệu", rs.getInt("gte50"));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return map;
    }

    public java.util.Map<String,Integer> getNewListingsByMonth() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        String sql = "SELECT DATE_FORMAT(created_at,'%Y-%m') AS mon, COUNT(*) AS cnt " +
            "FROM apartments WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH) " +
            "GROUP BY mon ORDER BY mon";
        try (Connection conn = DBConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) map.put(rs.getString("mon"), rs.getInt("cnt"));
        } catch (SQLException e) { e.printStackTrace(); }
        return map;
    }

    /** Top tiện nghi — amenities là text CSV nên dùng FIND_IN_SET */
    public java.util.Map<String,Integer> getTopAmenities() {
        java.util.Map<String,Integer> map = new java.util.LinkedHashMap<>();
        // Đếm số lần xuất hiện từng từ khóa tiện nghi phổ biến
        String[] keys = {"Wifi","Máy giặt","Điều hòa","Thang máy","Bãi đỗ xe","Hồ bơi","Ban công","Tủ lạnh"};
        String sql = "SELECT COUNT(*) FROM apartments WHERE status='approved' AND amenities LIKE ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (String k : keys) {
                ps.setString(1, "%" + k + "%");
                ResultSet rs = ps.executeQuery();
                if (rs.next()) map.put(k, rs.getInt(1));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return map;
    }
}
