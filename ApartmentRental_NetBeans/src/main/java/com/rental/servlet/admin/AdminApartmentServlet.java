package com.rental.servlet.admin;

import com.rental.dao.ApartmentDAO;
import com.rental.dao.ApartmentEditRequestDAO;
import com.rental.dao.NotificationDAO;
import com.rental.dao.ReviewDAO;
import com.rental.model.Apartment;
import com.rental.model.ApartmentEditRequest;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;


public class AdminApartmentServlet extends HttpServlet {
    private final ApartmentDAO           apartmentDAO   = new ApartmentDAO();
    private final ApartmentEditRequestDAO editRequestDAO = new ApartmentEditRequestDAO();
    private final NotificationDAO        notificationDAO = new NotificationDAO();
    private final ReviewDAO              reviewDAO       = new ReviewDAO();

    private static String fullPath(HttpServletRequest req) {
        String sp = req.getServletPath(), pi = req.getPathInfo();
        return (pi != null) ? sp + pi : (sp != null ? sp : "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = fullPath(req);

        // /admin/apartment/edit-requests → danh sách yêu cầu chỉnh sửa
        if ("/admin/apartment/edit-requests".equals(path)) {
            req.setAttribute("editRequests", editRequestDAO.getPending());
            req.setAttribute("pendingCount", editRequestDAO.countPending());
            req.getRequestDispatcher("/WEB-INF/views/admin/edit-requests.jsp").forward(req, resp);
            return;
        }

        // /admin/apartment/edit-request/{id} → xem chi tiết yêu cầu
        if (path.startsWith("/admin/apartment/edit-request/")) {
            try {
                int reqId = Integer.parseInt(path.substring("/admin/apartment/edit-request/".length()));
                ApartmentEditRequest er = editRequestDAO.findById(reqId);
                if (er == null) { resp.sendError(404); return; }
                Apartment apt = apartmentDAO.findById(er.getAptId());
                req.setAttribute("editRequest", er);
                req.setAttribute("apartment", apt);
                req.getRequestDispatcher("/WEB-INF/views/admin/edit-request-detail.jsp").forward(req, resp);
            } catch (NumberFormatException e) { resp.sendError(404); }
            return;
        }

        // /admin/apartment/{id} → chi tiết căn hộ
        if (path.startsWith("/admin/apartment/")) {
            String idStr = path.substring("/admin/apartment/".length());
            if (!idStr.isEmpty()) {
                try {
                    int aptId = Integer.parseInt(idStr);
                    Apartment apt = apartmentDAO.findById(aptId);
                    if (apt == null) { resp.sendError(404); return; }
                    req.setAttribute("apartment", apt);
                    req.getRequestDispatcher("/WEB-INF/views/admin/apartment-detail.jsp").forward(req, resp);
                    return;
                } catch (NumberFormatException e) { resp.sendError(404); return; }
            }
        }

        // /admin/apartments → danh sách
        String filter  = req.getParameter("filter");   // status filter (pending/approved/...)
        String keyword = req.getParameter("q");         // search keyword
        int page     = 1;
        int pageSize = 20;
        try { page = Math.max(1, Integer.parseInt(req.getParameter("page"))); } catch (Exception ignored) {}
        try { pageSize = Math.max(1, Math.min(200, Integer.parseInt(req.getParameter("pageSize")))); } catch (Exception ignored) {}

        // Dùng adminSearch cho cả search lẫn filter — hỗ trợ tìm theo tên chủ nhà
        String statusFilter = "pending".equals(filter) ? "pending" : filter;
        List<Apartment> apartments  = apartmentDAO.adminSearch(keyword, statusFilter, page, pageSize);
        int totalCount              = apartmentDAO.countAdminSearch(keyword, statusFilter);
        int totalPages              = (int) Math.ceil((double) totalCount / pageSize);

        req.setAttribute("apartments",  apartments);
        req.setAttribute("filter",      filter);
        req.setAttribute("keyword",     keyword != null ? keyword : "");
        req.setAttribute("page",        page);
        req.setAttribute("pageSize",    pageSize);
        req.setAttribute("totalCount",  totalCount);
        req.setAttribute("totalPages",  totalPages);
        req.setAttribute("pendingEditCount",   editRequestDAO.countPending());
        req.setAttribute("pendingReviewCount", reviewDAO.countByStatus("pending"));
        req.getRequestDispatcher("/WEB-INF/views/admin/apartments.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String path   = fullPath(req);
        String action = req.getParameter("action");
        String reason = req.getParameter("reason");

        // Duyệt/từ chối yêu cầu chỉnh sửa
        if (path.startsWith("/admin/apartment/edit-request/")) {
            try {
                int reqId = Integer.parseInt(path.substring("/admin/apartment/edit-request/".length()));
                ApartmentEditRequest er = editRequestDAO.findById(reqId);
                if (er == null) { resp.sendError(404); return; }

                if ("approve".equals(action)) {
                    editRequestDAO.approve(reqId, er);
                    notificationDAO.send(er.getOwnerId(),
                        "✅ Chỉnh sửa căn hộ được duyệt",
                        "Yêu cầu chỉnh sửa căn hộ \"" + er.getAptTitle() + "\" đã được Admin duyệt và áp dụng.",
                        "success", er.getAptId(), "apartment");
                } else if ("reject".equals(action)) {
                    String r = (reason != null && !reason.isBlank()) ? reason : "Không đáp ứng yêu cầu";
                    editRequestDAO.reject(reqId, r);
                    notificationDAO.send(er.getOwnerId(),
                        "❌ Chỉnh sửa căn hộ bị từ chối",
                        "Yêu cầu chỉnh sửa \"" + er.getAptTitle() + "\" bị từ chối. Lý do: " + r,
                        "warning", er.getAptId(), "apartment");
                }
                resp.sendRedirect(req.getContextPath() + "/admin/apartment/edit-requests?success=1");
            } catch (Exception e) {
                e.printStackTrace();
                resp.sendRedirect(req.getContextPath() + "/admin/apartment/edit-requests?error=1");
            }
            return;
        }

        // Duyệt/từ chối căn hộ mới
        try {
            String idStr = path.startsWith("/admin/apartment/")
                    ? path.substring("/admin/apartment/".length()) : "";
            int aptId = Integer.parseInt(idStr);
            Apartment apt = apartmentDAO.findById(aptId);
            if (apt == null) { resp.sendError(404); return; }

            if ("approve".equals(action)) {
                apartmentDAO.updateStatus(aptId, "approved", null);
                notificationDAO.send(apt.getOwnerId(), "✅ Căn hộ được duyệt",
                        "Tin đăng \"" + apt.getTitle() + "\" đã được duyệt và hiển thị công khai.",
                        "success", aptId, "apartment");
            } else if ("reject".equals(action)) {
                String r = (reason != null && !reason.isBlank()) ? reason : "Không đáp ứng yêu cầu";
                apartmentDAO.updateStatus(aptId, "rejected", r);
                notificationDAO.send(apt.getOwnerId(), "❌ Căn hộ bị từ chối",
                        "Tin đăng \"" + apt.getTitle() + "\" bị từ chối. Lý do: " + r,
                        "warning", aptId, "apartment");
            }
            resp.sendRedirect(req.getContextPath() + "/admin/apartments?success=1");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/admin/apartments?error=1");
        }
    }
}