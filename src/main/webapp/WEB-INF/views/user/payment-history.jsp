<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Lịch Sử Thanh Toán — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>
<div class="page-strip"><div style="padding:60px 80px;"><span class="eyebrow">Tài khoản</span><h1>Lịch sử thanh toán</h1></div></div>
<div class="container" style="padding-bottom:80px;">
  <c:choose>
    <c:when test="${empty payments}">
      <div class="empty"><i class="fas fa-receipt"></i><h3>Chưa có giao dịch nào</h3><p>Các giao dịch thanh toán sẽ hiển thị ở đây.</p><a href="${pageContext.request.contextPath}/apartments" class="btn btn-dark">Tìm căn hộ</a></div>
    </c:when>
    <c:otherwise>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Mã GD</th><th>Loại thanh toán</th><th>Phương thức</th><th>Số tiền</th><th>Ngày TT</th><th>Trạng thái</th></tr></thead>
          <tbody>
            <c:forEach var="p" items="${payments}">
              <tr>
                <td><code style="font-size:12px;">${p.transactionCode}</code></td>
                <td><c:choose><c:when test="${p.paymentType=='initial'}">Đợt đầu</c:when><c:when test="${p.paymentType=='periodic'}">Kỳ ${p.periodMonth}</c:when><c:otherwise>${p.paymentType}</c:otherwise></c:choose></td>
                <td><c:choose><c:when test="${p.paymentMethod=='bank_qr'}">🏦 Ngân hàng QR</c:when><c:when test="${p.paymentMethod=='card'}">💳 Thẻ</c:when><c:otherwise>${p.paymentMethod}</c:otherwise></c:choose></td>
                <td style="font-family:var(--serif);font-size:16px;font-weight:600;color:var(--dark);"><fmt:formatNumber value="${p.amount}" pattern="#,###"/> ₫</td>
                <td style="color:var(--light);font-size:12px;"><fmt:formatDate value="${p.paidDate}" pattern="HH:mm dd/MM/yyyy"/></td>
                <td><span class="badge ${p.status=='success'?'badge-green':p.status=='pending'?'badge-amber':'badge-red'}"><c:choose><c:when test="${p.status=='success'}">Thành công</c:when><c:when test="${p.status=='pending'}">Đang xử lý</c:when><c:otherwise>Thất bại</c:otherwise></c:choose></span></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </c:otherwise>
  </c:choose>
</div>
<%@ include file="../includes/footer.jsp" %>
