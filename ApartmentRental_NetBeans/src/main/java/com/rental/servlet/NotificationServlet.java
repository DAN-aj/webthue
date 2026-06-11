package com.rental.servlet;

import com.rental.dao.NotificationDAO;
import com.rental.model.User;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

public class NotificationServlet extends HttpServlet {
    private final NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("loggedUser");
        notificationDAO.markAllRead(user.getUserId());
        req.setAttribute("notifications", notificationDAO.getByUserId(user.getUserId()));
        req.getRequestDispatcher("/WEB-INF/views/user/notifications.jsp").forward(req, resp);
    }
}
