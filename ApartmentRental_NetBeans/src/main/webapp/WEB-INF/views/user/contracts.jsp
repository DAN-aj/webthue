<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Hợp Đồng Của Tôi — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>

<div class="page-strip">
  <div style="padding:60px 80px;">
    <span class="eyebrow">Tài khoản</span>
    <h1>Hợp đồng của tôi</h1>
  </div>
</div>

<div class="container" style="padding-bottom:80px;">
  <c:if test="${not empty param.error}">
    <div class="alert alert-error" style="margin-top:24px;">
      <c:choose>
        <c:when test="${param.error=='payment_failed'}">Thanh toán thất bại. Vui lòng thử lại.</c:when>
        <c:otherwise>Đã xảy ra lỗi.</c:otherwise>
      </c:choose>
    </div>
  </c:if>
  <c:if test="${param.success=='approved'}">
    <div class="alert alert-success auto-dismiss" style="margin-top:24px;">
      ✓ Đã chấp nhận yêu cầu thuê thành công! Người thuê sẽ tiến hành thanh toán.
    </div>
  </c:if>

  <%-- TABS --%>
  <div style="display:flex;gap:0;border-bottom:2px solid var(--border);margin-top:36px;margin-bottom:28px;">
    <button id="tabTenant" onclick="showTab('tenant')"
            style="padding:12px 28px;font-size:13px;font-weight:600;letter-spacing:.5px;text-transform:uppercase;border:none;background:none;cursor:pointer;border-bottom:3px solid var(--dark);margin-bottom:-2px;color:var(--dark);">
      Hợp đồng đã thuê
      <span style="margin-left:6px;background:var(--dark);color:var(--white);font-size:10px;padding:2px 7px;border-radius:20px;">${contracts.size()}</span>
    </button>
    <button id="tabOwner" onclick="showTab('owner')"
            style="padding:12px 28px;font-size:13px;font-weight:600;letter-spacing:.5px;text-transform:uppercase;border:none;background:none;cursor:pointer;border-bottom:3px solid transparent;margin-bottom:-2px;color:var(--light);">
      Cho thuê của tôi
      <span style="margin-left:6px;background:var(--light);color:var(--white);font-size:10px;padding:2px 7px;border-radius:20px;">${ownerContracts.size()}</span>
    </button>
  </div>

  <%-- ══ TAB: HỢP ĐỒNG ĐÃ THUÊ ══ --%>
  <div id="pane-tenant">
    <c:choose>
      <c:when test="${empty contracts}">
        <div class="empty">
          📄
          <h3>Chưa có hợp đồng nào</h3>
          <p>Tìm căn hộ phù hợp và gửi yêu cầu thuê.</p>
          <a href="${pageContext.request.contextPath}/apartments" class="btn btn-dark">Tìm căn hộ ngay</a>
        </div>
      </c:when>
      <c:otherwise>
        <c:forEach var="ct" items="${contracts}">
          <div class="contract-card" style="margin-bottom:12px;">
            <img src="${not empty ct.aptPrimaryImage ? ct.aptPrimaryImage : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=200'}"
                 alt="" style="width:110px;height:76px;object-fit:cover;flex-shrink:0;">
            <div style="flex:1;min-width:0;">
              <div class="cc-title">${ct.aptTitle}</div>
              <div class="cc-meta">
                <span>📅 <fmt:formatDate value="${ct.startDate}" pattern="dd/MM/yyyy"/> → <fmt:formatDate value="${ct.endDate}" pattern="dd/MM/yyyy"/></span>
                <span>
                  <c:choose>
                    <c:when test="${ct.rentalType=='short'}">
                      💰 <fmt:formatNumber value="${ct.monthlyRent}" pattern="#,###"/> đ/ngày
                      · ${ct.totalDays} ngày
                    </c:when>
                    <c:otherwise>
                      💰 <fmt:formatNumber value="${ct.monthlyRent}" pattern="#,###"/> đ/tháng
                    </c:otherwise>
                  </c:choose>
                </span>
                <span>🏠 ${ct.ownerName}</span>
              </div>
              <div class="cc-actions">
                <c:choose>
                  <c:when test="${ct.status=='pending'}"><span class="badge badge-amber">Chờ duyệt</span></c:when>
                  <c:when test="${ct.status=='approved'}"><span class="badge badge-accent">Cần thanh toán</span></c:when>
                  <c:when test="${ct.status=='active'}"><span class="badge badge-green">Đang hiệu lực</span></c:when>
                  <c:when test="${ct.status=='expired'}"><span class="badge badge-dark">Hết hạn</span></c:when>
                  <c:when test="${ct.status=='rejected'}"><span class="badge badge-red">Từ chối</span></c:when>
                  <c:when test="${ct.status=='terminated'}"><span class="badge badge-red">Chấm dứt</span></c:when>
                  <c:otherwise><span class="badge badge-dark">${ct.status}</span></c:otherwise>
                </c:choose>
                <a href="${pageContext.request.contextPath}/user/contract/detail/${ct.contractId}"
                   class="btn btn-outline btn-sm">Xem chi tiết</a>
                <c:if test="${ct.status=='approved'}">
                  <a href="${pageContext.request.contextPath}/user/payment/checkout/${ct.contractId}?type=initial"
                     class="btn btn-accent btn-sm">🔒 Thanh toán ngay</a>
                </c:if>
                <c:if test="${ct.status=='active' && ct.rentalType=='long'}">
                  <a href="${pageContext.request.contextPath}/user/payment/checkout/${ct.contractId}?type=periodic"
                     class="btn btn-outline btn-sm">Thanh toán tiền thuê</a>
                </c:if>
              </div>
            </div>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </div>

  <%-- ══ TAB: CHO THUÊ CỦA TÔI ══ --%>
  <div id="pane-owner" style="display:none;">
    <c:choose>
      <c:when test="${empty ownerContracts}">
        <div class="empty">
          🏠
          <h3>Chưa có yêu cầu thuê nào</h3>
          <p>Khi có người thuê căn hộ của bạn, hợp đồng sẽ hiện ở đây.</p>
          <a href="${pageContext.request.contextPath}/user/apartment/post" class="btn btn-dark">Đăng tin cho thuê</a>
        </div>
      </c:when>
      <c:otherwise>
        <c:forEach var="ct" items="${ownerContracts}">
          <div style="background:var(--white);border:1px solid var(--border);padding:20px 24px;margin-bottom:12px;display:flex;gap:20px;align-items:flex-start;">
            <img src="${not empty ct.aptPrimaryImage ? ct.aptPrimaryImage : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=200'}"
                 alt="" style="width:110px;height:76px;object-fit:cover;flex-shrink:0;">
            <div style="flex:1;min-width:0;">
              <div style="font-family:var(--serif);font-size:17px;font-weight:700;margin-bottom:6px;">${ct.aptTitle}</div>
              <div style="display:flex;flex-wrap:wrap;gap:16px;font-size:12px;color:var(--mid);margin-bottom:12px;">
                <span>👤 Người thuê: <strong style="color:var(--dark);">${ct.tenantName}</strong></span>
                <span>📅 <fmt:formatDate value="${ct.startDate}" pattern="dd/MM/yyyy"/> → <fmt:formatDate value="${ct.endDate}" pattern="dd/MM/yyyy"/></span>
                <span>
                  <c:choose>
                    <c:when test="${ct.rentalType=='short'}">
                      💰 <fmt:formatNumber value="${ct.monthlyRent}" pattern="#,###"/> đ/ngày
                      · ${ct.totalDays} ngày
                    </c:when>
                    <c:otherwise>
                      💰 <fmt:formatNumber value="${ct.monthlyRent}" pattern="#,###"/> đ/tháng
                    </c:otherwise>
                  </c:choose>
                </span>
              </div>

              <%-- Tiền thực nhận (sau phí nền tảng) --%>
              <c:if test="${ct.status=='active' || ct.status=='approved' || ct.status=='expired'}">
                <div style="display:inline-flex;align-items:center;gap:8px;background:var(--cream);border:1px solid var(--border);padding:8px 14px;margin-bottom:12px;font-size:12px;">
                  <span style="color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Bạn nhận được</span>
                  <c:choose>
                    <c:when test="${ct.rentalType=='short'}">
                      <%-- Ngắn hạn: tổng - phí --%>
                      <strong style="font-family:var(--serif);font-size:16px;color:var(--success);">
                        <fmt:formatNumber value="${ct.totalRent}" pattern="#,###"/> đ
                      </strong>
                    </c:when>
                    <c:otherwise>
                      <%-- Dài hạn: mỗi tháng - phí nền tảng chia đều --%>
                      <strong style="font-family:var(--serif);font-size:16px;color:var(--success);">
                        <fmt:formatNumber value="${ct.monthlyRent}" pattern="#,###"/> đ/tháng
                      </strong>
                    </c:otherwise>
                  </c:choose>
                  <span style="font-size:11px;color:var(--light);">(sau phí nền tảng)</span>
                </div>
              </c:if>

              <div style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;">
                <c:choose>
                  <c:when test="${ct.status=='pending'}"><span class="badge badge-amber">⏳ Chờ xác nhận</span></c:when>
                  <c:when test="${ct.status=='approved'}"><span class="badge badge-accent">Chờ thanh toán</span></c:when>
                  <c:when test="${ct.status=='active'}"><span class="badge badge-green">✓ Đang hiệu lực</span></c:when>
                  <c:when test="${ct.status=='expired'}"><span class="badge badge-dark">Đã kết thúc</span></c:when>
                  <c:when test="${ct.status=='rejected'}"><span class="badge badge-red">Đã từ chối</span></c:when>
                  <c:otherwise><span class="badge badge-dark">${ct.status}</span></c:otherwise>
                </c:choose>
                <a href="${pageContext.request.contextPath}/user/contract/detail/${ct.contractId}"
                   class="btn btn-outline btn-sm">Xem chi tiết &amp; duyệt</a>
                <c:if test="${ct.status=='pending' && ct.ownerId == sessionScope.loggedUser.userId}">
                  <form action="${pageContext.request.contextPath}/user/contract/approve/${ct.contractId}"
                        method="post" style="margin:0;">
                    <input type="hidden" name="from" value="list"/>
                    <button type="submit"
                            class="btn btn-sm"
                            style="background:var(--success);color:white;border:none;padding:6px 16px;font-size:12px;font-weight:600;cursor:pointer;"
                            onclick="return confirm('Xác nhận chấp nhận yêu cầu thuê này?')">
                      ✓ Chấp nhận nhanh
                    </button>
                  </form>
                </c:if>
              </div>
            </div>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </div>
</div>

<script>
function showTab(tab) {
  document.getElementById('pane-tenant').style.display = tab==='tenant' ? 'block' : 'none';
  document.getElementById('pane-owner').style.display  = tab==='owner'  ? 'block' : 'none';
  document.getElementById('tabTenant').style.borderBottomColor = tab==='tenant' ? 'var(--dark)' : 'transparent';
  document.getElementById('tabTenant').style.color = tab==='tenant' ? 'var(--dark)' : 'var(--light)';
  document.getElementById('tabOwner').style.borderBottomColor = tab==='owner' ? 'var(--dark)' : 'transparent';
  document.getElementById('tabOwner').style.color = tab==='owner' ? 'var(--dark)' : 'var(--light)';
  // Update badge colors
  document.querySelector('#tabTenant span').style.background = tab==='tenant' ? 'var(--dark)' : 'var(--light)';
  document.querySelector('#tabOwner span').style.background  = tab==='owner'  ? 'var(--dark)' : 'var(--light)';
}

// Tự động mở tab owner nếu không có tenant contracts nhưng có owner contracts
// Hoặc nếu có param tab=owner (sau khi approve nhanh)
window.addEventListener('load', function() {
  var tenantCount = ${contracts.size()};
  var ownerCount  = ${ownerContracts.size()};
  var urlParams   = new URLSearchParams(window.location.search);
  if (urlParams.get('tab') === 'owner' || (tenantCount === 0 && ownerCount > 0)) showTab('owner');
});
</script>

<%@ include file="../includes/footer.jsp" %>
