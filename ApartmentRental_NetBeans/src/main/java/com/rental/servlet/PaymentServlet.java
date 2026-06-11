package com.rental.servlet;

import com.rental.dao.*;
import com.rental.model.*;
import com.rental.util.AppConfig;
import com.rental.util.VietQRService;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Date;
import java.time.LocalDate;
import java.util.UUID;
import java.util.logging.Logger;

public class PaymentServlet extends HttpServlet {

    private static final Logger log = Logger.getLogger(PaymentServlet.class.getName());
    private final PaymentDAO      paymentDAO      = new PaymentDAO();
    private final ContractDAO     contractDAO     = new ContractDAO();
    private final NotificationDAO notificationDAO = new NotificationDAO();

    private static String fullPath(HttpServletRequest req) {
        String sp = req.getServletPath(), pi = req.getPathInfo();
        return (pi != null) ? sp + pi : (sp != null ? sp : "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = fullPath(req);
        User user = (User) req.getSession().getAttribute("loggedUser");
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }
        if (path.startsWith("/user/payment/checkout/"))
            handleCheckout(req, resp, user, path.substring("/user/payment/checkout/".length()));
        else if (path.startsWith("/user/payment/pending/"))
            handlePending(req, resp, user, path.substring("/user/payment/pending/".length()));
        else if (path.startsWith("/user/payment/success/"))
            handleSuccess(req, resp, user, path.substring("/user/payment/success/".length()));
        else if (path.startsWith("/user/payment/history"))
            handleHistory(req, resp, user);
        else
            resp.sendRedirect(req.getContextPath() + "/user/payment/history");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = fullPath(req);
        User user = (User) req.getSession().getAttribute("loggedUser");
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }
        if (path.startsWith("/user/payment/process/"))
            handleProcess(req, resp, user, path.substring("/user/payment/process/".length()));
    }

    // ══════════════════════════════════════════════════════════════
    //  CHECKOUT — hiển thị trang chọn phương thức, tạo QR sẵn
    // ══════════════════════════════════════════════════════════════
    private void handleCheckout(HttpServletRequest req, HttpServletResponse resp,
                                User user, String idStr) throws ServletException, IOException {
        try {
            int contractId = Integer.parseInt(idStr);
            Contract contract = contractDAO.findById(contractId);
            if (contract == null || contract.getTenantId() != user.getUserId()) {
                resp.sendError(403); return;
            }

            String payType = req.getParameter("type");
            if (payType == null) payType = "initial";

            if ("short".equals(contract.getRentalType()) && "periodic".equals(payType)) {
                resp.sendRedirect(req.getContextPath()
                    + "/user/payment/checkout/" + contractId + "?type=initial"); return;
            }

            double totalMonthsD       = (double) contract.getTotalDays() / 30.0;
            int    payPeriod          = Math.max(1, contract.getPaymentPeriod());
            double remainingMonths    = totalMonthsD - 1.0;
            int    totalPeriodicPeriods = remainingMonths <= 0
                    ? 0 : (int) Math.ceil(remainingMonths / payPeriod);
            int paidPeriods = paymentDAO.countPaidPeriods(contractId);
            int nextPeriod  = paidPeriods + 1;

            BigDecimal amount;
            Integer    periodMonth = null;
            String     description;

            if ("initial".equals(payType)) {
                if ("short".equals(contract.getRentalType())) {
                    BigDecimal priceDay  = contract.getMonthlyRent();
                    BigDecimal totalRent = priceDay.multiply(BigDecimal.valueOf(contract.getTotalDays()));
                    BigDecimal fee = contract.getPlatformFee() != null ? contract.getPlatformFee() : BigDecimal.ZERO;
                    amount = totalRent.add(fee);
                    description = "Thanh toan ngan han: " + contract.getTotalDays() + " ngay";
                } else {
                    BigDecimal rent    = contract.getMonthlyRent();
                    BigDecimal deposit = contract.getDepositAmount() != null ? contract.getDepositAmount() : BigDecimal.ZERO;
                    amount = rent.add(deposit);
                    description = "Ky 1: thang dau + tien coc";
                }
            } else {
                if (paidPeriods >= totalPeriodicPeriods && totalPeriodicPeriods > 0) {
                    resp.sendRedirect(req.getContextPath()
                        + "/user/contract/detail/" + contractId + "?success=all_paid"); return;
                }
                String periodStr = req.getParameter("period");
                periodMonth = (periodStr != null && !periodStr.isEmpty())
                              ? Integer.parseInt(periodStr) : nextPeriod;
                if (periodMonth >= totalPeriodicPeriods) {
                    double coveredMonths = 1.0 + (double)(totalPeriodicPeriods - 1) * payPeriod;
                    double lastMonths    = totalMonthsD - coveredMonths;
                    if (lastMonths <= 0) lastMonths = payPeriod;
                    long lastDays = Math.round(lastMonths * 30);
                    amount = contract.getMonthlyRent()
                             .multiply(BigDecimal.valueOf(lastDays))
                             .divide(BigDecimal.valueOf(30), 0, RoundingMode.HALF_UP);
                } else {
                    amount = contract.getMonthlyRent().multiply(BigDecimal.valueOf(payPeriod));
                }
                description = "Tien thue ky " + periodMonth + "/" + totalPeriodicPeriods;
            }

            // Tạo txRef và QR URL ngay tại checkout để hiển thị preview thông tin ngân hàng
            String txRef  = VietQRService.generateTxRef(contractId);
            String qrUrl  = VietQRService.buildQRUrl(amount.longValue(), txRef);
            int    expMin = AppConfig.getInt("qr.expire_minutes", 15);

            req.setAttribute("contract",             contract);
            req.setAttribute("amount",               amount);
            req.setAttribute("payType",              payType);
            req.setAttribute("periodMonth",          periodMonth);
            req.setAttribute("description",          description);
            req.setAttribute("totalPeriodicPeriods", totalPeriodicPeriods);
            req.setAttribute("paidPeriods",          paidPeriods);
            req.setAttribute("nextPeriod",           nextPeriod);
            req.setAttribute("txRef",                txRef);
            req.setAttribute("qrUrl",                qrUrl);
            req.setAttribute("qrExpMin",             expMin);
            req.setAttribute("bankName",             AppConfig.get("bank.name"));
            req.setAttribute("bankAccount",          AppConfig.get("bank.account_no"));
            req.setAttribute("bankHolder",           AppConfig.get("bank.account_name"));

            req.getRequestDispatcher("/WEB-INF/views/user/payment-checkout.jsp").forward(req, resp);
        } catch (Exception e) {
            log.severe("handleCheckout: " + e.getMessage()); e.printStackTrace(); resp.sendError(404);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  PROCESS — tạo payment record, rẽ nhánh theo phương thức
    // ══════════════════════════════════════════════════════════════
    private void handleProcess(HttpServletRequest req, HttpServletResponse resp,
                               User user, String idStr) throws IOException {
        try {
            int contractId = Integer.parseInt(idStr);
            Contract contract = contractDAO.findById(contractId);
            if (contract == null || contract.getTenantId() != user.getUserId()) {
                resp.sendError(403); return;
            }

            String     payType   = req.getParameter("payType");
            String     method    = req.getParameter("paymentMethod"); // bank_qr | card
            BigDecimal amount    = new BigDecimal(req.getParameter("amount"));
            String     periodStr = req.getParameter("periodMonth");
            String     txRef     = req.getParameter("txRef"); // mã QR sinh từ checkout

            Payment payment = new Payment();
            payment.setContractId(contractId);
            payment.setPayerId(user.getUserId());
            payment.setAmount(amount);
            payment.setPaymentType(payType != null ? payType : "initial");
            payment.setPaymentMethod(method != null ? method : "bank_qr");
            payment.setDueDate(Date.valueOf(LocalDate.now()));
            payment.setTxRef(txRef);
            if (periodStr != null && !periodStr.isEmpty())
                payment.setPeriodMonth(Integer.parseInt(periodStr));

            int paymentId = paymentDAO.insert(payment);
            if (paymentId < 0) {
                resp.sendRedirect(req.getContextPath() + "/user/contracts?error=db_error"); return;
            }

            // ── QR Bank → trang chờ, SePay webhook tự xác nhận ──────────
            if ("bank_qr".equals(method)) {
                resp.sendRedirect(req.getContextPath() + "/user/payment/pending/" + paymentId);
                return;
            }

            // ── Thẻ tín dụng → xác nhận ngay (tích hợp cổng thẻ thật sau) ──
            // TODO: gọi VNPAY / Stripe tại đây thay cho UUID giả
            String txCode = "CARD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
            boolean ok = paymentDAO.confirmPayment(paymentId, txCode);
            if (ok) {
                afterPaymentSuccess(contract, payment, paymentId, txCode, user);
                resp.sendRedirect(req.getContextPath() + "/user/payment/success/" + paymentId);
            } else {
                paymentDAO.failPayment(paymentId);
                resp.sendRedirect(req.getContextPath()
                    + "/user/payment/checkout/" + contractId
                    + "?type=" + payType + "&error=card_failed");
            }
        } catch (Exception e) {
            log.severe("handleProcess: " + e.getMessage()); e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/user/contracts?error=payment_failed");
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  PENDING — trang chờ QR (polling AJAX mỗi 3 giây)
    // ══════════════════════════════════════════════════════════════
    private void handlePending(HttpServletRequest req, HttpServletResponse resp,
                               User user, String idStr) throws ServletException, IOException {
        try {
            int paymentId = Integer.parseInt(idStr);
            Payment payment = paymentDAO.findById(paymentId);
            if (payment == null || payment.getPayerId() != user.getUserId()) {
                resp.sendError(403); return;
            }
            // Đã success → redirect ngay
            if ("success".equals(payment.getStatus())) {
                resp.sendRedirect(req.getContextPath() + "/user/payment/success/" + paymentId); return;
            }
            // Đã failed/expired → quay checkout
            if ("failed".equals(payment.getStatus())) {
                resp.sendRedirect(req.getContextPath()
                    + "/user/payment/checkout/" + payment.getContractId()
                    + "?type=" + payment.getPaymentType() + "&error=expired"); return;
            }

            // Tái tạo QR URL từ txRef đã lưu
            String qrUrl = VietQRService.buildQRUrl(payment.getAmount().longValue(), payment.getTxRef());

            req.setAttribute("payment",     payment);
            req.setAttribute("contract",    contractDAO.findById(payment.getContractId()));
            req.setAttribute("qrUrl",       qrUrl);
            req.setAttribute("qrExpMin",    AppConfig.getInt("qr.expire_minutes", 15));
            req.setAttribute("bankName",    AppConfig.get("bank.name"));
            req.setAttribute("bankAccount", AppConfig.get("bank.account_no"));
            req.setAttribute("bankHolder",  AppConfig.get("bank.account_name"));

            req.getRequestDispatcher("/WEB-INF/views/user/payment-pending.jsp").forward(req, resp);
        } catch (Exception e) {
            log.severe("handlePending: " + e.getMessage()); resp.sendError(500);
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  SUCCESS
    // ══════════════════════════════════════════════════════════════
    private void handleSuccess(HttpServletRequest req, HttpServletResponse resp,
                               User user, String idStr) throws ServletException, IOException {
        try {
            int paymentId = Integer.parseInt(idStr);
            Payment payment = paymentDAO.findById(paymentId);
            if (payment == null || payment.getPayerId() != user.getUserId()) {
                resp.sendError(403); return;
            }
            req.setAttribute("payment",  payment);
            req.setAttribute("contract", contractDAO.findById(payment.getContractId()));
            req.getRequestDispatcher("/WEB-INF/views/user/payment-success.jsp").forward(req, resp);
        } catch (Exception e) { resp.sendError(404); }
    }

    // ══════════════════════════════════════════════════════════════
    //  HISTORY
    // ══════════════════════════════════════════════════════════════
    private void handleHistory(HttpServletRequest req, HttpServletResponse resp, User user)
            throws ServletException, IOException {
        req.setAttribute("payments", paymentDAO.getByPayerId(user.getUserId()));
        req.getRequestDispatcher("/WEB-INF/views/user/payment-history.jsp").forward(req, resp);
    }

    // ══════════════════════════════════════════════════════════════
    //  HELPER — notification sau khi xác nhận thành công
    // ══════════════════════════════════════════════════════════════
    void afterPaymentSuccess(Contract contract, Payment payment, int paymentId,
                             String txCode, User user) {
        try {
            if ("initial".equals(payment.getPaymentType()))
                contractDAO.updateStatus(contract.getContractId(), "active");

            String amtFmt = String.format("%,.0f", payment.getAmount().doubleValue());
            BigDecimal net = payment.getAmount().subtract(
                contract.getPlatformFee() != null ? contract.getPlatformFee() : BigDecimal.ZERO);
            String netFmt = String.format("%,.0f", net.doubleValue());

            notificationDAO.send(contract.getOwnerId(),
                "💰 Nhận tiền — " + contract.getAptTitle(),
                user.getFullName() + " đã thanh toán " + amtFmt + " đ. Bạn nhận " + netFmt + " đ (sau phí). Mã GD: " + txCode,
                "payment", paymentId, "payment");

            notificationDAO.send(user.getUserId(),
                "✅ Thanh toán thành công",
                "Đã thanh toán " + amtFmt + " đ cho " + contract.getAptTitle() + ". Mã GD: " + txCode,
                "payment", paymentId, "payment");
        } catch (Exception e) {
            log.warning("afterPaymentSuccess notification: " + e.getMessage());
        }
    }
}
