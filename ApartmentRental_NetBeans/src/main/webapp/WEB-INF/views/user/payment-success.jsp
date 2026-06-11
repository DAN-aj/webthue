<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Thanh Toán Thành Công — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>
<div class="container" style="max-width:640px;padding:80px 40px;text-align:center;">
  <div style="width:80px;height:80px;background:#f0f7f3;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 28px;border:1px solid #c2ddd0;">
    <i class="fas fa-circle-check" style="font-size:36px;color:var(--success);"></i>
  </div>
  <span class="eyebrow" style="color:var(--success);">Giao dịch hoàn tất</span>
  <h1 style="font-family:var(--serif);font-size:44px;font-weight:700;letter-spacing:-.04em;margin:12px 0 16px;">Thanh toán thành công</h1>
  <p style="color:var(--mid);font-size:15px;line-height:1.8;margin-bottom:48px;">Tiền đã chuyển vào Escrow an toàn.<br>Chủ nhà nhận tiền sau khi bạn xác nhận nhận nhà.</p>
  <div style="background:var(--white);border:1px solid var(--border);margin-bottom:28px;text-align:left;">
    <div style="padding:18px 24px;border-bottom:1px solid var(--border);background:var(--cream);font-size:11px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:var(--light);">Chi tiết giao dịch</div>
    <div style="padding:22px;">
      <div class="ps-row"><span>Mã giao dịch</span><strong style="font-family:monospace;font-size:13px;">${payment.transactionCode}</strong></div>
      <div class="ps-row"><span>Phương thức</span><span><c:choose><c:when test="${payment.paymentMethod=='bank_qr'}">Chuyển khoản ngân hàng QR</c:when><c:when test="${payment.paymentMethod=='card'}">Thẻ tín dụng/ghi nợ</c:when><c:otherwise>${payment.paymentMethod}</c:otherwise></c:choose></span></div>
      <div class="ps-row"><span>Căn hộ</span><span>${contract.aptTitle}</span></div>
      <div class="ps-row ps-total"><span>Tổng thanh toán</span><span style="color:var(--accent);"><fmt:formatNumber value="${payment.amount}" pattern="#,###"/> ₫</span></div>
    </div>
  </div>
  <div class="escrow-bar" style="text-align:left;margin-bottom:28px;"><i class="fas fa-shield-halved"></i><div><strong>Escrow đang bảo vệ tiền của bạn</strong>Hợp đồng đã kích hoạt. Tiền giải phóng sau khi bạn xác nhận nhận nhà.</div></div>
  <div style="display:flex;gap:12px;flex-wrap:wrap;">
    <a href="${pageContext.request.contextPath}/user/contract/detail/${contract.contractId}" class="btn btn-dark btn-lg" style="flex:1;"><i class="fas fa-file-contract"></i> Xem hợp đồng</a>
    <a href="${pageContext.request.contextPath}/user/contracts" class="btn btn-outline btn-lg" style="flex:1;">Tất cả hợp đồng</a>
  </div>
</div>
<%@ include file="../includes/footer.jsp" %>
