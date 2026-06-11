package com.rental.servlet;

import com.rental.dao.ApartmentDAO;
import com.rental.dao.NotificationDAO;
import com.rental.model.Apartment;
import com.rental.model.User;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;


/**
 * ChatServlet — nhận tin nhắn từ người dùng và gửi thông báo tới chủ nhà.
 * POST /api/chat   { aptId, message }  → JSON { ok: true } | { ok: false, error }
 */
public class ChatServlet extends HttpServlet {

    private final ApartmentDAO    apartmentDAO    = new ApartmentDAO();
    private final NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        // Kiểm tra đăng nhập
        HttpSession session = req.getSession(false);
        User sender = (session != null) ? (User) session.getAttribute("loggedUser") : null;
        if (sender == null) {
            resp.setStatus(401);
            out.write("{\"ok\":false,\"error\":\"Vui lòng đăng nhập để gửi tin nhắn.\"}");
            return;
        }

        // Parse aptId và message
        int aptId;
        String message;
        try {
            aptId = Integer.parseInt(req.getParameter("aptId"));
            message = req.getParameter("message");
            if (message == null || message.trim().isEmpty()) {
                resp.setStatus(400);
                out.write("{\"ok\":false,\"error\":\"Nội dung tin nhắn không được để trống.\"}");
                return;
            }
            message = message.trim();
            if (message.length() > 500) message = message.substring(0, 500);
        } catch (Exception e) {
            resp.setStatus(400);
            out.write("{\"ok\":false,\"error\":\"Dữ liệu không hợp lệ.\"}");
            return;
        }

        // Lấy thông tin căn hộ
        Apartment apt = apartmentDAO.findById(aptId);
        if (apt == null) {
            resp.setStatus(404);
            out.write("{\"ok\":false,\"error\":\"Căn hộ không tồn tại.\"}");
            return;
        }

        // Không cho tự nhắn cho chính mình
        if (apt.getOwnerId() == sender.getUserId()) {
            resp.setStatus(400);
            out.write("{\"ok\":false,\"error\":\"Bạn không thể nhắn tin cho chính mình.\"}");
            return;
        }

        // Gửi notification đến chủ nhà
        String title = "💬 Tin nhắn từ " + sender.getFullName();
        String body  = "Về căn hộ \"" + apt.getTitle() + "\": " + message;
        notificationDAO.send(apt.getOwnerId(), title, body, "info", aptId, "apartment");

        out.write("{\"ok\":true}");
    }
}
