package com.rental.filter;

import com.rental.model.User;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

public class AuthFilter implements Filter {
    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("loggedUser") : null;
        String path = request.getServletPath();

        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login?redirect=" + path);
            return;
        }

        if (path.startsWith("/admin") && !user.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/home");
            return;
        }

        if ("locked".equals(user.getStatus())) {
            session.invalidate();
            response.sendRedirect(request.getContextPath() + "/login?error=locked");
            return;
        }

        chain.doFilter(req, res);
    }
}
