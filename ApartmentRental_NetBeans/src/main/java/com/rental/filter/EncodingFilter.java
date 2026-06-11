package com.rental.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

public class EncodingFilter implements Filter {
    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        // Skip encoding override for static resources (css, js, images)
        // to avoid interfering with Tomcat's DefaultServlet Content-Type handling
        if (req instanceof HttpServletRequest) {
            String uri = ((HttpServletRequest) req).getRequestURI();
            if (uri.endsWith(".css") || uri.endsWith(".js") ||
                uri.endsWith(".png") || uri.endsWith(".jpg") ||
                uri.endsWith(".ico") || uri.endsWith(".gif") ||
                uri.endsWith(".woff") || uri.endsWith(".woff2")) {
                chain.doFilter(req, res);
                return;
            }
        }

        req.setCharacterEncoding("UTF-8");
        res.setCharacterEncoding("UTF-8");
        chain.doFilter(req, res);
    }
}
