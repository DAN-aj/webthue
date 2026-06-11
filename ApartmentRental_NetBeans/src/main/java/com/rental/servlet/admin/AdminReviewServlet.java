package com.rental.servlet.admin;

import com.rental.dao.ApartmentEditRequestDAO;
import com.rental.dao.NotificationDAO;
import com.rental.dao.ReviewDAO;
import com.rental.model.Review;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

/**
 * AdminReviewServlet — quản lý đánh giá căn hộ (duyệt / từ chối).
 *
 * GET  /admin/reviews          → danh sách pending
 * POST /admin/review/{id}      → action=approve|reject
 */
public class AdminReviewServlet extends HttpServlet {

    private final ReviewDAO               reviewDAO      = new ReviewDAO();
    private final NotificationDAO         notiDAO        = new NotificationDAO();
    private final ApartmentEditRequestDAO editRequestDAO = new ApartmentEditRequestDAO();

    private static String fullPath(HttpServletRequest req) {
        String sp = req.getServletPath(), pi = req.getPathInfo();
        return (pi != null) ? sp + pi : (sp != null ? sp : "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String filter = req.getParameter("filter");
        List<Review> reviews;
        if ("approved".equals(filter)) {
            reviews = reviewDAO.getByStatus("approved");
        } else if ("rejected".equals(filter)) {
            reviews = reviewDAO.getByStatus("rejected");
        } else {
            reviews = reviewDAO.getPending();
            filter  = "pending";
        }

        req.setAttribute("reviews",          reviews);
        req.setAttribute("pendingCount",     reviewDAO.countByStatus("pending"));
        req.setAttribute("pendingReviewCount", reviewDAO.countByStatus("pending"));
        req.setAttribute("filter",           filter);
        req.setAttribute("pendingEditCount", editRequestDAO.countPending());
        req.getRequestDispatcher("/WEB-INF/views/admin/reviews.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String path   = fullPath(req);
        String action = req.getParameter("action");

        // /admin/review/{id}
        if (path.startsWith("/admin/review/")) {
            try {
                int reviewId = Integer.parseInt(path.substring("/admin/review/".length()));
                Review review = reviewDAO.findById(reviewId);
                if (review == null) { resp.sendError(404); return; }

                if ("approve".equals(action)) {
                    reviewDAO.updateStatus(reviewId, "approved");
                    // Thông báo cho user: review đã được duyệt
                    notiDAO.send(review.getUserId(),
                        "✅ Đánh giá của bạn đã được duyệt",
                        "Đánh giá căn hộ \"" + review.getAptTitle() + "\" của bạn đã được công khai.",
                        "success", review.getAptId(), "apartment");

                } else if ("reject".equals(action)) {
                    reviewDAO.updateStatus(reviewId, "rejected");
                    notiDAO.send(review.getUserId(),
                        "❌ Đánh giá của bạn bị từ chối",
                        "Đánh giá căn hộ \"" + review.getAptTitle() + "\" không đáp ứng tiêu chuẩn cộng đồng.",
                        "warning", review.getAptId(), "apartment");
                }

                resp.sendRedirect(req.getContextPath() + "/admin/reviews?success=1&filter=pending");
            } catch (Exception e) {
                e.printStackTrace();
                resp.sendRedirect(req.getContextPath() + "/admin/reviews?error=1");
            }
            return;
        }

        resp.sendRedirect(req.getContextPath() + "/admin/reviews");
    }
}
