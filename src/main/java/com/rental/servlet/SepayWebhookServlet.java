package com.rental.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.rental.dao.ContractDAO;
import com.rental.dao.NotificationDAO;
import com.rental.dao.PaymentDAO;
import com.rental.model.Contract;
import com.rental.model.Payment;
import com.rental.util.AppConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Nhận webhook POST từ SePay khi có giao dịch tiền vào TK ngân hàng.
 * URL: POST /webhook/sepay
 *
 * Cấu hình trong SePay Dashboard:
 *   Webhook URL : https://yourdomain.com/webhook/sepay
 *   Secret Token: (điền vào config.properties → sepay.webhook_secret)
 *
 * SePay gửi header: Authorization: Apikey {secret}
 */
public class SepayWebhookServlet extends HttpServlet {

    private static final Logger log  = Logger.getLogger(SepayWebhookServlet.class.getName());
    private static final Gson   gson = new Gson();
    private static final Pattern TX_PATTERN = Pattern.compile("HD(\\d+)T(\\d{6,})", Pattern.CASE_INSENSITIVE);

    private final PaymentDAO      paymentDAO      = new PaymentDAO();
    private final ContractDAO     contractDAO     = new ContractDAO();
    private final NotificationDAO notificationDAO = new NotificationDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        // 1. Đọc body
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line);
        }
        String body = sb.toString();
        log.info("[Webhook] Body: " + body);

        // 2. Verify secret — SePay gửi header: Authorization: Apikey {secret}
        String webhookSecret = AppConfig.get("sepay.webhook_secret");
        if (!webhookSecret.isBlank()) {
            String authHeader = req.getHeader("Authorization");
            String expected   = "Apikey " + webhookSecret;
            if (!expected.equals(authHeader)) {
                log.warning("[Webhook] Chữ ký không hợp lệ! Received: " + authHeader);
                resp.setStatus(401);
                out.write("{\"success\":false,\"message\":\"Unauthorized\"}");
                return;
            }
        }

        // 3. Parse JSON
        JsonObject payload;
        try { payload = gson.fromJson(body, JsonObject.class); }
        catch (Exception e) {
            resp.setStatus(400);
            out.write("{\"success\":false,\"message\":\"Invalid JSON\"}");
            return;
        }

        // 4. Chỉ xử lý tiền VÀO
        if (!"in".equalsIgnoreCase(getStr(payload, "transferType"))) {
            out.write("{\"success\":true,\"message\":\"Ignored\"}"); return;
        }

        long   amount  = getLong(payload, "transferAmount");
        String content = getStr(payload, "content");
        String code    = getStr(payload, "code");           // SePay tự parse từ content
        String bankRef = getStr(payload, "referenceCode");  // mã GD thật của ngân hàng

        log.info(String.format("[Webhook] amount=%d code=%s content=%s bankRef=%s", amount, code, content, bankRef));

        // 5. Tìm txRef (HD{id}T{ts}) trong code hoặc content
        String txRef = !code.isBlank() ? code : extractTxRef(content);
        if (txRef == null || txRef.isBlank()) {
            log.warning("[Webhook] Không tìm được txRef trong: " + content);
            out.write("{\"success\":true,\"message\":\"No txRef matched\"}"); return;
        }

        // 6. Tìm payment
        Payment payment = paymentDAO.findByTxRef(txRef.toUpperCase());
        if (payment == null) {
            log.warning("[Webhook] Không tìm thấy payment với txRef=" + txRef);
            out.write("{\"success\":true,\"message\":\"Payment not found\"}"); return;
        }

        // 7. Idempotency — tránh xử lý 2 lần
        if ("success".equals(payment.getStatus())) {
            log.info("[Webhook] Payment " + payment.getPaymentId() + " đã success, bỏ qua.");
            out.write("{\"success\":true,\"message\":\"Already processed\"}"); return;
        }

        // 8. Kiểm tra số tiền (±1000đ)
        if (Math.abs(amount - payment.getAmount().longValue()) > 1000) {
            log.warning(String.format("[Webhook] Số tiền không khớp! expected=%d received=%d txRef=%s",
                payment.getAmount().longValue(), amount, txRef));
            out.write("{\"success\":true,\"message\":\"Amount mismatch logged\"}"); return;
        }

        // 9. XÁC NHẬN THÀNH CÔNG
        boolean updated = paymentDAO.confirmPaymentByTxRef(txRef.toUpperCase(), bankRef);
        if (!updated) {
            log.severe("[Webhook] DB update thất bại txRef=" + txRef);
            resp.setStatus(500);
            out.write("{\"success\":false,\"message\":\"DB error\"}"); return;
        }

        log.info("[Webhook] ✅ Xác nhận OK: txRef=" + txRef + " paymentId=" + payment.getPaymentId() + " amount=" + amount);

        // 10. Cập nhật hợp đồng + gửi notification
        try {
            if ("initial".equals(payment.getPaymentType()))
                contractDAO.updateStatus(payment.getContractId(), "active");

            Contract contract = contractDAO.findById(payment.getContractId());
            if (contract != null) {
                String amtFmt = String.format("%,.0f", (double) amount);
                notificationDAO.send(payment.getPayerId(),
                    "✅ Thanh toán thành công",
                    "Đã ghi nhận " + amtFmt + " đ cho " + contract.getAptTitle() + ". Mã GD: " + bankRef,
                    "payment", payment.getPaymentId(), "payment");
                notificationDAO.send(contract.getOwnerId(),
                    "💰 Nhận tiền — " + contract.getAptTitle(),
                    "Khách thuê vừa chuyển " + amtFmt + " đ. Mã GD: " + bankRef,
                    "payment", payment.getPaymentId(), "payment");
            }
        } catch (Exception e) {
            log.warning("[Webhook] Lỗi phụ (notification): " + e.getMessage());
        }

        // 11. Trả success cho SePay (bắt buộc, không thì SePay retry)
        out.write("{\"success\":true}");
    }

    private String extractTxRef(String content) {
        if (content == null) return null;
        Matcher m = TX_PATTERN.matcher(content);
        return m.find() ? m.group(0).toUpperCase() : null;
    }

    private String getStr(JsonObject obj, String key) {
        try { return obj.has(key) && !obj.get(key).isJsonNull() ? obj.get(key).getAsString() : ""; }
        catch (Exception e) { return ""; }
    }
    private long getLong(JsonObject obj, String key) {
        try { return obj.has(key) ? obj.get(key).getAsLong() : 0L; }
        catch (Exception e) { return 0L; }
    }
}
