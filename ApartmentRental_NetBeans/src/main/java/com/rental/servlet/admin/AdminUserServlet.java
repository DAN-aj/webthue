package com.rental.servlet.admin;

import com.rental.dao.ApartmentEditRequestDAO;
import com.rental.dao.ReviewDAO;
import com.rental.dao.UserDAO;
import com.rental.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

public class AdminUserServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private final ApartmentEditRequestDAO editRequestDAO = new ApartmentEditRequestDAO();
    private final ReviewDAO reviewDAO = new ReviewDAO();

    private static String fullPath(HttpServletRequest req) {
        String sp = req.getServletPath();
        String pi = req.getPathInfo();
        return (pi != null) ? sp + pi : (sp != null ? sp : "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String path = fullPath(req);

        // /admin/users → danh sách tất cả user
        if ("/admin/users".equals(path) || "/admin/users".equals(req.getRequestURI())) {
            String keyword = req.getParameter("q");
            String status  = req.getParameter("status");
            int page     = 1;
            int pageSize = 20;
            try { page = Math.max(1, Integer.parseInt(req.getParameter("page"))); } catch (Exception ignored) {}

            List<User> users  = userDAO.searchCustomers(keyword, status, page, pageSize);
            int totalCount    = userDAO.countSearchCustomers(keyword, status);
            int totalPages    = (int) Math.ceil((double) totalCount / pageSize);

            req.setAttribute("users",       users);
            req.setAttribute("keyword",     keyword != null ? keyword : "");
            req.setAttribute("statusFilter",status  != null ? status  : "");
            req.setAttribute("page",        page);
            req.setAttribute("pageSize",    pageSize);
            req.setAttribute("totalCount",  totalCount);
            req.setAttribute("totalPages",  totalPages);
            req.setAttribute("pendingEditCount",   editRequestDAO.countPending());
            req.setAttribute("pendingReviewCount", reviewDAO.countByStatus("pending"));
            req.getRequestDispatcher("/WEB-INF/views/admin/users.jsp").forward(req, resp);
            return;
        }

        // Nếu có pathInfo khác (ví dụ /admin/user/5) thì có thể xử lý sau
        resp.sendRedirect(req.getContextPath() + "/admin/users");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String path = fullPath(req);
        String action = req.getParameter("action");

        try {
            // Lấy userId từ /admin/user/{id}
            String idStr = path.startsWith("/admin/user/")
                    ? path.substring("/admin/user/".length()) : "";

            if (!idStr.isEmpty()) {
                int userId = Integer.parseInt(idStr);

                if ("lock".equals(action)) {
                    userDAO.updateStatus(userId, "locked");
                } else if ("unlock".equals(action)) {
                    userDAO.updateStatus(userId, "active");
                } else if ("delete".equals(action)) {
                    userDAO.deleteUser(userId);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        resp.sendRedirect(req.getContextPath() + "/admin/users?success=1");
    }
}