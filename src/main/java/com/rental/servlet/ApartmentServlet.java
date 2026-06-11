package com.rental.servlet;

import com.rental.dao.ApartmentDAO;
import com.rental.dao.ApartmentEditRequestDAO;
import com.rental.dao.NotificationDAO;
import com.rental.dao.ReviewDAO;
import com.rental.model.ApartmentEditRequest;
import com.rental.model.Apartment;
import com.rental.model.User;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;

public class ApartmentServlet extends HttpServlet {
    private final ApartmentDAO apartmentDAO = new ApartmentDAO();
    private final ApartmentEditRequestDAO editRequestDAO = new ApartmentEditRequestDAO();
    private final NotificationDAO notificationDAO = new NotificationDAO();
    private final ReviewDAO reviewDAO = new ReviewDAO();

    private static String fullPath(HttpServletRequest req) {
        String sp = req.getServletPath(), pi = req.getPathInfo();
        return (pi != null) ? sp + pi : (sp != null ? sp : "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = fullPath(req);
        if ("/apartments".equals(path)) {
            handleSearch(req, resp);
        } else if (path.startsWith("/apartment/")) {
            handleDetail(req, resp, path);
        } else if ("/user/apartment/post".equals(path)) {
            req.getRequestDispatcher("/WEB-INF/views/user/post-apartment.jsp").forward(req, resp);
        } else if (path.startsWith("/user/apartment/edit/")) {
            // FIX: getSession(false) + null-check trước khi vào handler cần auth
            HttpSession s = req.getSession(false);
            User user = (s != null) ? (User) s.getAttribute("loggedUser") : null;
            if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }
            handleEditForm(req, resp, path, user);
        } else {
            resp.sendRedirect(req.getContextPath() + "/apartments");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = fullPath(req);
        // FIX: getSession(false) + null-check — các route POST đều cần auth
        HttpSession s = req.getSession(false);
        User user = (s != null) ? (User) s.getAttribute("loggedUser") : null;
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        if ("/user/apartment/post".equals(path))              handlePost(req, resp, user);
        else if (path.startsWith("/user/apartment/edit/"))    handleEditSubmit(req, resp, path, user);
        else if (path.startsWith("/user/apartment/delete/"))  handleDelete(req, resp, path, user);
    }

    // ── SEARCH ──────────────────────────────────────────────────────
    private void handleSearch(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String keyword    = req.getParameter("keyword");
        String district   = req.getParameter("district");
        String rentalType = req.getParameter("rentalType");
        String type       = req.getParameter("type");
        BigDecimal minPrice = parseDecimal(req.getParameter("minPrice"));
        BigDecimal maxPrice = parseDecimal(req.getParameter("maxPrice"));
        Float minArea = parseFloat(req.getParameter("minArea"));
        Float maxArea = parseFloat(req.getParameter("maxArea"));

        int page = 1;
        try { page = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (page < 1) page = 1;
        int pageSize = 20;

        List<Apartment> apartments = apartmentDAO.search(keyword, district, rentalType,
                minPrice, maxPrice, minArea, maxArea, type, page, pageSize);
        int totalCount = apartmentDAO.countSearch(keyword, district, rentalType,
                minPrice, maxPrice, minArea, maxArea, type);
        int totalPages = (int) Math.ceil((double) totalCount / pageSize);

        req.setAttribute("apartments", apartments);
        req.setAttribute("districts", apartmentDAO.getDistincts());
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("totalCount", totalCount);
        req.setAttribute("keyword", keyword);
        req.setAttribute("district", district);
        req.setAttribute("rentalType", rentalType);
        req.setAttribute("type", type);
        req.setAttribute("maxPrice", req.getParameter("maxPrice"));
        req.getRequestDispatcher("/WEB-INF/views/apartments/list.jsp").forward(req, resp);
    }

    // ── DETAIL ──────────────────────────────────────────────────────
    private void handleDetail(HttpServletRequest req, HttpServletResponse resp, String path)
            throws ServletException, IOException {
        // FIX: Tat ca logic trong try-catch tong quat, tra error truoc khi forward
        // Tranh truong hop response da commit mot phan -> ERR_INCOMPLETE_CHUNKED_ENCODING
        try {
            String idStr = path.substring("/apartment/".length());
            if (idStr.isEmpty()) { resp.sendRedirect(req.getContextPath() + "/apartments"); return; }
            int aptId = Integer.parseInt(idStr);

            Apartment apt = apartmentDAO.findById(aptId);
            if (apt == null) {
                if (!resp.isCommitted()) resp.sendError(404);
                return;
            }

            // FIX: Set tat ca attribute TRUOC khi commit response (truoc forward)
            // Tranh JSP render mot nua roi loi -> encoding error
            HttpSession session = req.getSession(false);
            User user = (session != null) ? (User) session.getAttribute("loggedUser") : null;
            boolean hasActiveContract = (user != null) && apartmentDAO.hasActiveContract(aptId, user.getUserId());

            req.setAttribute("apartment", apt);
            req.setAttribute("hasActiveContract", hasActiveContract);

            // ── Review data ──────────────────────────────────────────────
            req.setAttribute("reviews",     reviewDAO.getApprovedByAptId(aptId));
            req.setAttribute("reviewCount", reviewDAO.countApproved(aptId));
            req.setAttribute("avgRating",   reviewDAO.avgRating(aptId));

            // canReview: đã đăng nhập, không phải chủ nhà, có hợp đồng hợp lệ
            boolean canReview      = false;
            boolean alreadyReviewed = false;
            if (user != null && user.getUserId() != apt.getOwnerId()) {
                int eligibleContract = reviewDAO.findEligibleContractId(aptId, user.getUserId());
                canReview       = (eligibleContract != ReviewDAO.NOT_ELIGIBLE);
                alreadyReviewed = reviewDAO.hasReviewed(aptId, user.getUserId());
            }
            req.setAttribute("canReview",       canReview);
            req.setAttribute("alreadyReviewed", alreadyReviewed);

            // Increment view sau khi da lay du lieu - khong anh huong response
            try { apartmentDAO.incrementView(aptId); } catch (Exception ignored) {}

            req.getRequestDispatcher("/WEB-INF/views/apartments/detail.jsp").forward(req, resp);

        } catch (NumberFormatException e) {
            if (!resp.isCommitted()) resp.sendError(404);
        } catch (Exception e) {
            e.printStackTrace();
            if (!resp.isCommitted()) resp.sendError(500, "Loi tai trang chi tiet can ho");
        }
    }

    // ── POST ────────────────────────────────────────────────────────
    private void handlePost(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException, ServletException {
        try {
            Apartment apt = new Apartment();
            apt.setOwnerId(user.getUserId());
            apt.setTitle(req.getParameter("title"));
            apt.setAddress(req.getParameter("address"));
            apt.setDistrict(req.getParameter("district"));
            String city = req.getParameter("city");
            apt.setCity(city != null && !city.isBlank() ? city : "Hà Nội");
            apt.setType(req.getParameter("type"));
            apt.setArea(parseFloatVal(req.getParameter("area")));
            apt.setFloor(parseInt(req.getParameter("floor")));
            apt.setTotalFloors(parseInt(req.getParameter("totalFloors")));
            apt.setBedrooms(parseInt(req.getParameter("bedrooms")));
            apt.setBathrooms(parseInt(req.getParameter("bathrooms")));
            apt.setFurniture(req.getParameter("furniture"));
            apt.setDirection(req.getParameter("direction"));
            apt.setView(req.getParameter("view"));

            BigDecimal priceMonth = parseDecimal(req.getParameter("rentPriceMonth"));
            BigDecimal priceDay   = parseDecimal(req.getParameter("rentPriceDay"));
            if (priceMonth == null) priceMonth = parseDecimal(req.getParameter("rentPrice"));
            apt.setRentPriceMonth(priceMonth);
            apt.setRentPriceDay(priceDay);
            apt.setRentPrice(priceMonth);
            apt.setDepositMonths(parseInt(req.getParameter("depositMonths")));
            apt.setRentalType(req.getParameter("rentalType"));
            apt.setPaymentPeriod(parseInt(req.getParameter("paymentPeriod")));

            // Amenities — lưu dạng text CSV
            String[] amenArr = req.getParameterValues("amenities");
            if (amenArr != null && amenArr.length > 0) {
                apt.setAmenities(String.join(", ", amenArr));
            } else {
                apt.setAmenities("");
            }

            int aptId = apartmentDAO.insert(apt);
            if (aptId > 0) {
                String[] urls = req.getParameterValues("imageUrls");
                if (urls != null) {
                    for (int i = 0; i < urls.length; i++) {
                        String u = urls[i].trim();
                        if (!u.isBlank()) apartmentDAO.addImage(aptId, u, i == 0);
                    }
                }
                resp.sendRedirect(req.getContextPath() + "/user/profile?success=posted");
            } else {
                req.setAttribute("error", "Đăng tin thất bại. Vui lòng thử lại.");
                req.getRequestDispatcher("/WEB-INF/views/user/post-apartment.jsp").forward(req, resp);
            }
        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("error", "Dữ liệu không hợp lệ: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/views/user/post-apartment.jsp").forward(req, resp);
        }
    }

    // ── EDIT FORM ────────────────────────────────────────────────────
    private void handleEditForm(HttpServletRequest req, HttpServletResponse resp, String path, User user)
            throws ServletException, IOException {
        try {
            int aptId = Integer.parseInt(path.substring("/user/apartment/edit/".length()));
            Apartment apt = apartmentDAO.findById(aptId);
            if (apt == null || apt.getOwnerId() != user.getUserId()) { resp.sendError(403); return; }
            req.setAttribute("apartment", apt);
            req.getRequestDispatcher("/WEB-INF/views/user/edit-apartment.jsp").forward(req, resp);
        } catch (Exception e) { resp.sendError(404); }
    }

    // ── EDIT SUBMIT ──────────────────────────────────────────────────
    private void handleEditSubmit(HttpServletRequest req, HttpServletResponse resp, String path, User user)
            throws IOException, ServletException {
        try {
            int aptId = Integer.parseInt(path.substring("/user/apartment/edit/".length()));
            Apartment apt = apartmentDAO.findById(aptId);
            if (apt == null || apt.getOwnerId() != user.getUserId()) { resp.sendError(403); return; }

            ApartmentEditRequest r = new ApartmentEditRequest();
            r.setAptId(aptId);
            r.setOwnerId(user.getUserId());
            r.setNewTitle(req.getParameter("title"));
            r.setNewDescription(req.getParameter("description"));
            r.setNewRentPriceMonth(parseDecimal(req.getParameter("rentPriceMonth")));
            r.setNewRentPriceDay(parseDecimal(req.getParameter("rentPriceDay")));
            r.setNewDepositMonths(parseInt(req.getParameter("depositMonths")));
            r.setNewPaymentPeriod(parseInt(req.getParameter("paymentPeriod")));
            r.setNewBedrooms(parseInt(req.getParameter("bedrooms")));
            r.setNewBathrooms(parseInt(req.getParameter("bathrooms")));
            r.setNewArea(parseFloatVal(req.getParameter("area")));

            String[] amenArr = req.getParameterValues("amenities");
            if (amenArr != null && amenArr.length > 0) {
                r.setNewAmenities(String.join(", ", amenArr));
            } else {
                r.setNewAmenities("");
            }

            int reqId = editRequestDAO.insert(r);
            if (reqId > 0) {
                notificationDAO.send(1, "Yeu cau chinh sua can ho",
                    user.getFullName() + " muon chinh sua can ho \"" + apt.getTitle() + "\".",
                    "info", aptId, "apartment");
                resp.sendRedirect(req.getContextPath() + "/user/profile?success=edit_requested");
            } else {
                req.setAttribute("error", "Gửi yêu cầu thất bại. Vui lòng thử lại.");
                req.setAttribute("apartment", apt);
                req.getRequestDispatcher("/WEB-INF/views/user/edit-apartment.jsp").forward(req, resp);
            }
        } catch (Exception e) {
            e.printStackTrace();
            // FIX: Không dùng sendError(500) vì response có thể đã commit (chunked).
            // Thay vào đó forward về trang lỗi với thông báo.
            if (!resp.isCommitted()) {
                try {
                    req.setAttribute("error", "Đã xảy ra lỗi hệ thống, vui lòng thử lại: " + e.getMessage());
                    // Cố lấy lại apartment để render form
                    try {
                        int aptId2 = Integer.parseInt(path.substring("/user/apartment/edit/".length()));
                        req.setAttribute("apartment", apartmentDAO.findById(aptId2));
                    } catch (Exception ignored) {}
                    req.getRequestDispatcher("/WEB-INF/views/user/edit-apartment.jsp").forward(req, resp);
                } catch (Exception fe) {
                    resp.sendError(500, "Lỗi hệ thống");
                }
            }
        }
    }

    // ── DELETE ───────────────────────────────────────────────────────
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp, String path, User user)
            throws IOException {
        try {
            int aptId = Integer.parseInt(path.substring("/user/apartment/delete/".length()));
            Apartment apt = apartmentDAO.findById(aptId);
            if (apt != null && apt.getOwnerId() == user.getUserId() && "pending".equals(apt.getStatus()))
                apartmentDAO.updateStatus(aptId, "unavailable", null);
        } catch (Exception e) { e.printStackTrace(); }
        resp.sendRedirect(req.getContextPath() + "/user/profile");
    }

    // ── HELPERS ──────────────────────────────────────────────────────
    private BigDecimal parseDecimal(String v) {
        try { return (v != null && !v.isBlank()) ? new BigDecimal(v.replace(",","")) : null; }
        catch (Exception e) { return null; }
    }
    private Float parseFloat(String v) {
        try { return (v != null && !v.isBlank()) ? Float.parseFloat(v) : null; }
        catch (Exception e) { return null; }
    }
    private float parseFloatVal(String v) {
        try { return (v != null && !v.isBlank()) ? Float.parseFloat(v) : 0f; }
        catch (Exception e) { return 0f; }
    }
    private int parseInt(String v) {
        try { return (v != null && !v.isBlank()) ? Integer.parseInt(v) : 0; }
        catch (Exception e) { return 0; }
    }
}
