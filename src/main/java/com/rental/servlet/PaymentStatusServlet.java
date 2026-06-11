package com.rental.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.rental.dao.PaymentDAO;
import com.rental.model.Payment;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.logging.Logger;

/**
 * API polling: GET /api/payment/status?paymentId=XXX
 * JSP gọi mỗi 3 giây. Khi status=success → trả redirectUrl → JSP redirect.
 */

public class PaymentStatusServlet extends HttpServlet {

    private static final Logger log  = Logger.getLogger(PaymentStatusServlet.class.getName());
    private static final Gson   gson = new Gson();
    private final PaymentDAO paymentDAO = new PaymentDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");

        String idStr = req.getParameter("paymentId");
        if (idStr == null || idStr.isBlank()) {
            resp.setStatus(400);
            resp.getWriter().write("{\"error\":\"Missing paymentId\"}"); return;
        }

        try {
            int paymentId = Integer.parseInt(idStr);
            Payment payment = paymentDAO.findById(paymentId);
            if (payment == null) {
                resp.setStatus(404);
                resp.getWriter().write("{\"error\":\"Not found\"}"); return;
            }

            JsonObject json = new JsonObject();
            json.addProperty("status", payment.getStatus());
            if ("success".equals(payment.getStatus())) {
                json.addProperty("txCode", payment.getTransactionCode());
                json.addProperty("redirectUrl",
                    req.getContextPath() + "/user/payment/success/" + paymentId);
            }
            resp.getWriter().write(gson.toJson(json));

        } catch (NumberFormatException e) {
            resp.setStatus(400);
            resp.getWriter().write("{\"error\":\"Invalid paymentId\"}");
        } catch (Exception e) {
            log.severe("[PaymentStatus] " + e.getMessage());
            resp.setStatus(500);
            resp.getWriter().write("{\"error\":\"Server error\"}");
        }
    }
}
