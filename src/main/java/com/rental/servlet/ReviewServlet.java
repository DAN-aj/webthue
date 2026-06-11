package com.rental.servlet;

import com.rental.dao.NotificationDAO;
import com.rental.dao.ReviewDAO;
import com.rental.model.Review;
import com.rental.model.User;
import jakarta.servlet.*;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;

/**
 * ReviewServlet — xử lý gửi review qua AJAX POST.
 *
 * URL pattern: /review/{aptId}
 *
 * Luồng xử lý:
 *  1. Kiểm tra đăng nhập
 *  2. Kiểm tra user có hợp đồng đủ điều kiện (active/expired/terminated)
 *  3. Kiểm tra chưa review căn hộ này
 *  4. Insert review (status=pending, chờ admin duyệt)
 *  5. Trả JSON {ok:true/false, msg:"..."}
 */
public class ReviewServlet extends HttpServlet {

    private final ReviewDAO      reviewDAO      = new ReviewDAO();
    private final NotificationDAO notiDAO       = new NotificationDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        /* 1. Kiểm tra đăng nhập */
        User user = (User) req.getSession().getAttribute("loggedUser");
        if (user == null) {
            resp.setStatus(401);
            out.print("{\"ok\":false,\"msg\":\"Bạn cần đăng nhập để viết đánh giá.\"}");
            return;
        }

        /* 2. Lấy aptId từ path /review/{aptId} */
        int aptId;
        try {
            String path = req.getPathInfo();                // "/{aptId}"
            if (path == null || path.length() < 2) throw new NumberFormatException();
            aptId = Integer.parseInt(path.substring(1));
        } catch (NumberFormatException e) {
            resp.setStatus(400);
            out.print("{\"ok\":false,\"msg\":\"Yêu cầu không hợp lệ.\"}");
            return;
        }

        /* 3. Kiểm tra hợp đồng đủ điều kiện */
        int contractId = reviewDAO.findEligibleContractId(aptId, user.getUserId());
        if (contractId == ReviewDAO.NOT_ELIGIBLE) {
            resp.setStatus(403);
            out.print("{\"ok\":false,\"msg\":\"Bạn chưa có hợp đồng thuê căn hộ này, không thể viết đánh giá.\"}");
            return;
        }

        /* 4. Kiểm tra đã review chưa */
        if (reviewDAO.hasReviewed(aptId, user.getUserId())) {
            resp.setStatus(409);
            out.print("{\"ok\":false,\"msg\":\"Bạn đã đánh giá căn hộ này rồi. Mỗi người chỉ được đánh giá một lần.\"}");
            return;
        }

        /* 5. Validate input */
        String commentRaw = req.getParameter("comment");
        String ratingRaw  = req.getParameter("rating");
        if (commentRaw == null || commentRaw.trim().length() < 10) {
            resp.setStatus(400);
            out.print("{\"ok\":false,\"msg\":\"Nội dung đánh giá cần ít nhất 10 ký tự.\"}");
            return;
        }
        int rating = 5;
        try {
            rating = Integer.parseInt(ratingRaw);
            if (rating < 1 || rating > 5) rating = 5;
        } catch (NumberFormatException ignored) {}

        /* 6. Insert */
        Review r = new Review();
        r.setAptId(aptId);
        r.setUserId(user.getUserId());
        r.setContractId(contractId);
        r.setRating(rating);
        r.setComment(commentRaw.trim());

        int newId = reviewDAO.insert(r);
        if (newId == -2) {
            resp.setStatus(409);
            out.print("{\"ok\":false,\"msg\":\"Bạn đã đánh giá căn hộ này rồi.\"}");
            return;
        }
        if (newId < 0) {
            resp.setStatus(500);
            out.print("{\"ok\":false,\"msg\":\"Có lỗi xảy ra khi lưu đánh giá, vui lòng thử lại.\"}");
            return;
        }

        /* 7. Trả JSON thành công — client sẽ prepend card vào DOM */
        String starsHtml = buildStarsHtml(rating);
        String name      = escape(user.getFullName());
        String firstLetter = name.isEmpty() ? "?" : String.valueOf(name.charAt(0)).toUpperCase();
        String comment   = escape(commentRaw.trim());

        String cardHtml =
            "<div class=\"review-card\" style=\"padding:24px;margin-bottom:2px;border:1px solid var(--border);background:#f0f7f3;\">" +
            "  <div style=\"display:flex;align-items:center;gap:12px;margin-bottom:12px;\">" +
            "    <div style=\"width:38px;height:38px;border-radius:50%;background:var(--dark);color:var(--accent);display:flex;align-items:center;justify-content:center;font-family:var(--serif);font-weight:700;font-size:15px;flex-shrink:0;\">" + firstLetter + "</div>" +
            "    <div>" +
            "      <div style=\"font-weight:600;font-size:14px;\">" + name + "</div>" +
            "      <div style=\"font-size:11px;color:var(--light);margin-top:2px;\">Vừa gửi</div>" +
            "    </div>" +
            "    <div style=\"margin-left:auto;color:var(--accent);font-size:13px;\">" + starsHtml + "</div>" +
            "  </div>" +
            "  <p style=\"font-size:14px;line-height:1.8;color:var(--mid);\">" + comment + "</p>" +
            "</div>";

        out.print("{\"ok\":true,\"msg\":\"Cảm ơn bạn đã đánh giá!\",\"html\":" + toJson(cardHtml) + "}");
    }

    private String buildStarsHtml(int rating) {
        StringBuilder sb = new StringBuilder();
        for (int i = 1; i <= 5; i++) {
            sb.append(i <= rating ? "★" : "<span style=\"color:var(--border);\">★</span>");
        }
        return sb.toString();
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    /** Biến HTML string thành JSON string value có escape ký tự đặc biệt */
    private String toJson(String s) {
        return "\"" + s.replace("\\", "\\\\")
                       .replace("\"", "\\\"")
                       .replace("\n", "\\n")
                       .replace("\r", "")
                + "\"";
    }
}
