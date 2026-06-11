package com.rental.servlet;

import com.rental.dao.*;
import com.rental.model.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

public class ContractServlet extends HttpServlet {
    private final ContractDAO     contractDAO     = new ContractDAO();
    private final ApartmentDAO    apartmentDAO    = new ApartmentDAO();
    private final PaymentDAO      paymentDAO      = new PaymentDAO();
    private final NotificationDAO notificationDAO = new NotificationDAO();

    private static String fullPath(HttpServletRequest req) {
        String sp = req.getServletPath(), pi = req.getPathInfo();
        return (pi != null) ? sp + pi : (sp != null ? sp : "");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = fullPath(req);
        HttpSession s = req.getSession(false);
        User user = (s != null) ? (User) s.getAttribute("loggedUser") : null;
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        if ("/user/contracts".equals(path)) {
            req.setAttribute("contracts",      contractDAO.getByTenantId(user.getUserId()));
            req.setAttribute("ownerContracts", contractDAO.getByOwnerId(user.getUserId()));
            req.getRequestDispatcher("/WEB-INF/views/user/contracts.jsp").forward(req, resp);
        } else if (path.startsWith("/user/contract/rent/")) {
            handleRentForm(req, resp, user, path.substring("/user/contract/rent/".length()));
        } else if (path.startsWith("/user/contract/detail/")) {
            handleDetail(req, resp, user, path.substring("/user/contract/detail/".length()));
        } else if (path.startsWith("/user/contract/reject/")) {
            handleRejectForm(req, resp, user, path.substring("/user/contract/reject/".length()));
        } else if (path.startsWith("/user/contract/confirm/")) {
            handleConfirmMoveIn(req, resp, user, path.substring("/user/contract/confirm/".length()));
        } else if (path.startsWith("/user/contract/approve/")) {
            // GET đến /approve/ không được xử lý (approve phải dùng POST).
            // Redirect về trang detail để user thấy nút và thực hiện đúng cách.
            String idStr = path.substring("/user/contract/approve/".length());
            resp.sendRedirect(req.getContextPath() + "/user/contract/detail/" + idStr + "?error=use_form");
        } else {
            resp.sendRedirect(req.getContextPath() + "/user/contracts");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = fullPath(req);
        HttpSession s = req.getSession(false);
        User user = (s != null) ? (User) s.getAttribute("loggedUser") : null;
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        if (path.startsWith("/user/contract/rent/"))
            handleRentSubmit(req, resp, user, path.substring("/user/contract/rent/".length()));
        else if (path.startsWith("/user/contract/approve/"))
            handleApprove(req, resp, user, path.substring("/user/contract/approve/".length()));
        else if (path.startsWith("/user/contract/reject/"))
            handleRejectSubmit(req, resp, user, path.substring("/user/contract/reject/".length()));
        else if (path.startsWith("/user/contract/extend/"))
            handleExtend(req, resp, user, path.substring("/user/contract/extend/".length()));
        else if (path.startsWith("/user/contract/confirm/"))
            handleConfirmMoveIn(req, resp, user, path.substring("/user/contract/confirm/".length()));
    }

    // ── RENT FORM ──────────────────────────────────────────────────
    private void handleRentForm(HttpServletRequest req, HttpServletResponse resp,
                                User user, String idStr) throws ServletException, IOException {
        try {
            int aptId = Integer.parseInt(idStr);
            Apartment apt = apartmentDAO.findById(aptId);
            if (apt == null || !"approved".equals(apt.getStatus())) {
                resp.sendRedirect(req.getContextPath() + "/apartments"); return;
            }
            if (apt.getOwnerId() == user.getUserId()) {
                resp.sendRedirect(req.getContextPath() + "/apartment/" + aptId + "?error=self"); return;
            }
            if (contractDAO.hasActiveContract(aptId)) {
                resp.sendRedirect(req.getContextPath() + "/apartment/" + aptId + "?error=occupied"); return;
            }
            req.setAttribute("apartment", apt);
            req.getRequestDispatcher("/WEB-INF/views/user/rent-form.jsp").forward(req, resp);
        } catch (NumberFormatException e) { resp.sendError(404); }
    }

    // ── RENT SUBMIT ────────────────────────────────────────────────
    private void handleRentSubmit(HttpServletRequest req, HttpServletResponse resp,
                                  User user, String idStr) throws IOException, ServletException {
        try {
            int aptId = Integer.parseInt(idStr);
            Apartment apt = apartmentDAO.findById(aptId);
            if (apt == null || apt.getOwnerId() == user.getUserId()) {
                resp.sendRedirect(req.getContextPath() + "/apartments"); return;
            }
            if (contractDAO.hasActiveContract(aptId)) {
                resp.sendRedirect(req.getContextPath() + "/apartment/" + aptId + "?error=occupied"); return;
            }

            String rentalType   = req.getParameter("rentalType");
            LocalDate startDate = LocalDate.parse(req.getParameter("startDate"));
            LocalDate endDate   = LocalDate.parse(req.getParameter("endDate"));
            String cccd         = req.getParameter("cccd");

            long totalDays = ChronoUnit.DAYS.between(startDate, endDate);
            if (totalDays <= 0) {
                req.setAttribute("error", "Ngày kết thúc phải sau ngày bắt đầu.");
                req.setAttribute("apartment", apt); 
                req.getRequestDispatcher("/WEB-INF/views/user/rent-form.jsp").forward(req, resp); return;
            }

            BigDecimal monthlyRent, depositAmount, platformFee;
            // Thêm check startDate không được là ngày quá khứ
            if (startDate.isBefore(LocalDate.now())) {
                req.setAttribute("error", "Ngày bắt đầu không được là ngày trong quá khứ.");
                req.setAttribute("apartment", apt);
                req.getRequestDispatcher("/WEB-INF/views/user/rent-form.jsp").forward(req, resp);
                return;
            }

            if (endDate.isBefore(startDate) || endDate.isEqual(startDate)) {
                req.setAttribute("error", "Ngày kết thúc phải sau ngày bắt đầu.");
                req.setAttribute("apartment", apt);
                req.getRequestDispatcher("/WEB-INF/views/user/rent-form.jsp").forward(req, resp);
                return;
            }

            if ("short".equals(rentalType)) {
                // ── Ngắn hạn: tính theo ngày, KHÔNG cọc ─────────────────────────
                BigDecimal priceDay = apt.getRentPriceDay();
                if (priceDay == null) priceDay = apt.getRentPriceMonth() != null
                        ? apt.getRentPriceMonth().divide(BigDecimal.valueOf(25), 0, java.math.RoundingMode.HALF_UP)
                        : BigDecimal.ZERO;
                monthlyRent   = priceDay;          // đơn giá/ngày lưu vào monthly_rent
                depositAmount = BigDecimal.ZERO;   // không cọc ngắn hạn

                // Phí nền tảng theo quy tắc mới
                platformFee = calcPlatformFee(priceDay.multiply(BigDecimal.valueOf(totalDays)),
                                              priceDay, totalDays);
            } else {
                // ── Dài hạn (≥30 ngày): tháng đầy đủ + ngày lẻ ─────────────────
                BigDecimal priceMonth = apt.getRentPriceMonth() != null
                        ? apt.getRentPriceMonth() : apt.getRentPrice();
                monthlyRent   = priceMonth;
                depositAmount = priceMonth.multiply(BigDecimal.valueOf(apt.getDepositMonths()));

                // Tổng tiền thuê thực tế
                java.time.LocalDate cur = startDate;
                int fullMonths = 0;
                while (true) {
                    java.time.LocalDate next = cur.plusMonths(1);
                    if (next.isAfter(endDate)) break;
                    fullMonths++;
                    cur = next;
                }
                long remainDays = java.time.temporal.ChronoUnit.DAYS.between(cur, endDate);
                BigDecimal rentFull   = priceMonth.multiply(BigDecimal.valueOf(fullMonths));
                BigDecimal rentRemain = remainDays > 0
                    ? priceMonth.multiply(BigDecimal.valueOf(remainDays))
                              .divide(BigDecimal.valueOf(30), 0, java.math.RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
                BigDecimal totalRent  = rentFull.add(rentRemain);

                // Phí nền tảng theo quy tắc mới
                platformFee = calcPlatformFee(totalRent, priceMonth, totalDays);
            }

            Contract c = new Contract();
            c.setAptId(aptId);
            c.setTenantId(user.getUserId());
            c.setOwnerId(apt.getOwnerId());
            c.setRentalType(rentalType);
            c.setStartDate(Date.valueOf(startDate));
            c.setEndDate(Date.valueOf(endDate));
            c.setTotalDays((int) totalDays);
            c.setMonthlyRent(monthlyRent);
            c.setDepositAmount(depositAmount);
            c.setPlatformFee(platformFee);
            c.setPaymentPeriod(apt.getPaymentPeriod());
            c.setTenantCccd(cccd);
            c.setNotes(req.getParameter("notes"));

            int contractId = contractDAO.insert(c);
            if (contractId > 0) {
                apartmentDAO.updateStatus(aptId, "rented", null);
                notificationDAO.send(apt.getOwnerId(), "Yêu cầu thuê mới",
                        user.getFullName() + " gửi yêu cầu thuê \"" + apt.getTitle() + "\"",
                        "contract", contractId, "contract");
                resp.sendRedirect(req.getContextPath() + "/user/contract/detail/" + contractId + "?success=requested");
            } else {
                req.setAttribute("error", "Gửi yêu cầu thất bại. Vui lòng thử lại.");
                req.setAttribute("apartment", apt);
                req.getRequestDispatcher("/WEB-INF/views/user/rent-form.jsp").forward(req, resp);
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/apartments?error=1");
        }
    }

    // ── DETAIL ────────────────────────────────────────────────────
    private void handleDetail(HttpServletRequest req, HttpServletResponse resp,
                              User user, String idStr) throws ServletException, IOException {
        try {
            int contractId = Integer.parseInt(idStr);
            Contract contract = contractDAO.findById(contractId);
            if (contract == null ||
               (contract.getTenantId() != user.getUserId() &&
                contract.getOwnerId()  != user.getUserId() &&
                !user.isAdmin())) { resp.sendError(403); return; }
            req.setAttribute("contract", contract);
            req.setAttribute("payments", paymentDAO.getByContractId(contractId));
            req.getRequestDispatcher("/WEB-INF/views/user/contract-detail.jsp").forward(req, resp);
        } catch (NumberFormatException e) { resp.sendError(404); }
    }

    // ── APPROVE ────────────────────────────────────────────────────
    private void handleApprove(HttpServletRequest req, HttpServletResponse resp,
                               User user, String idStr) throws IOException, ServletException {
        try {
            int contractId = Integer.parseInt(idStr);
            Contract contract = contractDAO.findById(contractId);

            // Guard 1: contract tồn tại và đúng chủ nhà
            if (contract == null || contract.getOwnerId() != user.getUserId()) {
                resp.sendError(403); return;
            }
            // Guard 2: chỉ cho approve khi status đang là 'pending' — tránh double-approve
            if (!"pending".equals(contract.getStatus())) {
                resp.sendRedirect(req.getContextPath()
                    + "/user/contract/detail/" + contractId + "?error=already_processed");
                return;
            }

            // Guard 3: check return value — nếu DB update fail thì KHÔNG redirect success
            boolean updated = contractDAO.updateStatus(contractId, "approved");
            if (!updated) {
                req.setAttribute("contract", contractDAO.findById(contractId));
                req.setAttribute("payments", paymentDAO.getByContractId(contractId));
                req.setAttribute("error", "Không thể cập nhật trạng thái hợp đồng. Vui lòng thử lại.");
                req.getRequestDispatcher("/WEB-INF/views/user/contract-detail.jsp").forward(req, resp);
                return;
            }

            notificationDAO.send(contract.getTenantId(), "Yêu cầu thuê được chấp nhận",
                    "Chủ nhà đã chấp nhận. Vui lòng thanh toán để hoàn tất hợp đồng.",
                    "payment", contractId, "contract");

            // Nếu approve từ trang danh sách (quick approve) → redirect về danh sách với thông báo
            // Nếu approve từ trang detail → redirect về detail để stepper/UI cập nhật
            String from = req.getParameter("from");
            boolean fromList = "list".equals(from);
            if (fromList) {
                resp.sendRedirect(req.getContextPath() + "/user/contracts?success=approved&id=" + contractId + "&tab=owner");
            } else {
                resp.sendRedirect(req.getContextPath() + "/user/contract/detail/" + contractId + "?success=approved");
            }
        } catch (NumberFormatException e) { resp.sendError(404); }
    }

    // ── REJECT FORM ────────────────────────────────────────────────
    private void handleRejectForm(HttpServletRequest req, HttpServletResponse resp,
                                  User user, String idStr) throws ServletException, IOException {
        try {
            int contractId = Integer.parseInt(idStr);
            Contract contract = contractDAO.findById(contractId);
            if (contract == null || contract.getOwnerId() != user.getUserId()) { resp.sendError(403); return; }
            req.setAttribute("contract", contract);
            req.setAttribute("payments", paymentDAO.getByContractId(contractId));
            req.getRequestDispatcher("/WEB-INF/views/user/contract-detail.jsp").forward(req, resp);
        } catch (NumberFormatException e) { resp.sendError(404); }
    }

    // ── REJECT SUBMIT ──────────────────────────────────────────────
    private void handleRejectSubmit(HttpServletRequest req, HttpServletResponse resp,
                                    User user, String idStr) throws IOException {
        try {
            int contractId = Integer.parseInt(idStr);
            Contract contract = contractDAO.findById(contractId);
            if (contract == null || contract.getOwnerId() != user.getUserId()) { resp.sendError(403); return; }
            contractDAO.updateStatus(contractId, "rejected");
            apartmentDAO.updateStatus(contract.getAptId(), "approved", null);
            notificationDAO.send(contract.getTenantId(), "Yêu cầu thuê bị từ chối",
                    "Rất tiếc, chủ nhà đã từ chối yêu cầu của bạn.",
                    "contract", contractId, "contract");
            resp.sendRedirect(req.getContextPath() + "/user/profile");
        } catch (NumberFormatException e) { resp.sendError(404); }
    }

    // ── EXTEND ─────────────────────────────────────────────────────
    private void handleExtend(HttpServletRequest req, HttpServletResponse resp,
                              User user, String idStr) throws IOException {
        try {
            int contractId = Integer.parseInt(idStr);
            Contract contract = contractDAO.findById(contractId);
            if (contract == null || contract.getTenantId() != user.getUserId()) { resp.sendError(403); return; }
            notificationDAO.send(contract.getOwnerId(), "Yêu cầu gia hạn hợp đồng",
                    user.getFullName() + " muốn gia hạn hợp đồng \"" + contract.getAptTitle() + "\".",
                    "contract", contractId, "contract");
            resp.sendRedirect(req.getContextPath() + "/user/contract/detail/" + contractId + "?success=extend_requested");
        } catch (NumberFormatException e) { resp.sendError(404); }
    }
    // ── TÍNH PHÍ NỀN TẢNG (Logic mới) ──────────────────────────────
    /**
     * Quy tắc phí nền tảng:
     *  ≤ 1 tháng  (≤30 ngày)  → 10% tổng tiền thuê
     *  > 1 tháng, < 12 tháng  → tổng tiền thuê / 12
     *  ≥ 12 tháng (≥365 ngày) → 1 tháng tiền thuê
     */
    private BigDecimal calcPlatformFee(BigDecimal totalRent, BigDecimal monthlyRent, long totalDays) {
        if (totalRent == null) totalRent = BigDecimal.ZERO;
        if (monthlyRent == null) monthlyRent = BigDecimal.ZERO;
        double months = totalDays / 30.0;
        if (months <= 1.0) {
            // ≤ 1 tháng: 10% tổng tiền thuê
            return totalRent.multiply(BigDecimal.valueOf(0.10))
                            .setScale(0, java.math.RoundingMode.HALF_UP);
        } else if (months < 12.0) {
            // > 1 tháng và < 12 tháng: tổng tiền thuê / 12
            return totalRent.divide(BigDecimal.valueOf(12), 0, java.math.RoundingMode.HALF_UP);
        } else {
            // ≥ 12 tháng: = 1 tháng tiền thuê
            return monthlyRent.setScale(0, java.math.RoundingMode.HALF_UP);
        }
    }

    // ── XÁC NHẬN NHẬN NHÀ ────────────────────────────────────────
    private void handleConfirmMoveIn(HttpServletRequest req, HttpServletResponse resp,
                                 User user, String idStr) throws IOException {
    try {
        int contractId = Integer.parseInt(idStr);
        Contract contract = contractDAO.findById(contractId);
        if (contract == null || contract.getTenantId() != user.getUserId()) {
            resp.sendError(403); return;
        }
        if (!"active".equals(contract.getStatus())) {
            resp.sendRedirect(req.getContextPath()
                + "/user/contract/detail/" + contractId); return;
        }

        // ── FIX: KHÔNG đổi sang expired ──────────────────────────────
        // Chỉ đánh dấu đã nhận nhà bằng cột riêng, hợp đồng vẫn "active"
        contractDAO.markMoveInConfirmed(contractId);   // thêm method mới

        // Giải phóng Escrow kỳ đầu cho chủ nhà (trừ phí nền tảng)
        notificationDAO.send(contract.getOwnerId(),
            "✅ Khách đã nhận nhà — Escrow giải phóng",
            user.getFullName() + " đã xác nhận nhận nhà "
            + contract.getAptTitle()
            + ". Tiền kỳ đầu đã được giải phóng (trừ phí nền tảng).",
            "payment", contractId, "contract");

        notificationDAO.send(user.getUserId(),
            "🏠 Xác nhận nhận nhà thành công",
            "Bạn đã nhận nhà " + contract.getAptTitle()
            + ". Hợp đồng đang có hiệu lực, vui lòng thanh toán đúng hạn các kỳ tiếp theo.",
            "success", contractId, "contract");

        resp.sendRedirect(req.getContextPath()
            + "/user/contract/detail/" + contractId + "?success=confirmed");
    } catch (NumberFormatException e) { resp.sendError(404); }
}

}