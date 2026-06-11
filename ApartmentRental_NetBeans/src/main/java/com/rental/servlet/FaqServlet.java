package com.rental.servlet;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * FaqServlet — hiển thị trang FAQ / Dịch vụ khách hàng.
 * URL: /faq
 */
public class FaqServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/views/faq.jsp").forward(req, resp);
    }
}
