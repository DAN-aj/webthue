<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Trang Cá Nhân — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>

<div class="page-strip">
  <div style="padding:60px 80px;display:flex;align-items:center;gap:24px;flex-wrap:wrap;">
    <div style="width:72px;height:72px;border-radius:50%;background:var(--accent);display:flex;align-items:center;justify-content:center;font-family:var(--serif);font-size:28px;font-weight:700;color:var(--dark);flex-shrink:0;">${sessionScope.loggedUser.firstLetter}</div>
    <div style="flex:1;">
      <span class="eyebrow">Tài khoản</span>
      <h1 style="font-family:var(--serif);font-size:clamp(24px,4vw,40px);font-weight:700;color:var(--white);margin-bottom:4px;letter-spacing:-.03em;">${sessionScope.loggedUser.fullName}</h1>
      <p style="color:rgba(255,255,255,.45);font-size:14px;">${sessionScope.loggedUser.email}</p>
    </div>
    <div style="display:flex;gap:40px;">
      <div style="text-align:center;"><div style="font-family:var(--serif);font-size:30px;font-weight:700;color:var(--white);">${rentedContracts.size()}</div><div style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.35);margin-top:4px;">Hợp đồng</div></div>
      <div style="text-align:center;"><div style="font-family:var(--serif);font-size:30px;font-weight:700;color:var(--white);">${myApartments.size()}</div><div style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.35);margin-top:4px;">Căn hộ đăng</div></div>
    </div>
  </div>
</div>

<div class="container" style="padding-bottom:80px;">
  <c:if test="${param.success=='updated'}"><div class="alert alert-success auto-dismiss" style="margin-top:24px;"><i class="fas fa-circle-check"></i>Cập nhật thành công.</div></c:if>
  <c:if test="${not empty sessionScope.loggedUser.cccd}">
    <div class="escrow-bar" style="margin-top:28px;margin-bottom:0;"><i class="fas fa-id-card"></i><div><strong>Danh tính đã xác thực (eKYC)</strong>CCCD của bạn đã xác nhận. Tài khoản uy tín cao.</div></div>
  </c:if>

  <div style="border-bottom:1px solid var(--border);display:flex;gap:0;margin-top:36px;overflow-x:auto;" id="profileTabsBar">
    <button class="tab on" onclick="switchTab('tab-rented',this)">Căn hộ tôi thuê (${rentedContracts.size()})</button>
    <button class="tab" onclick="switchTab('tab-myapts',this)">Căn hộ tôi cho thuê (${myApartments.size()})</button>
    <button class="tab" onclick="switchTab('tab-settings',this)">Cài đặt tài khoản</button>
  </div>

  <div id="tab-rented" style="padding-top:28px;">
    <c:choose>
      <c:when test="${empty rentedContracts}">
        <div class="empty"><i class="fas fa-key"></i><h3>Chưa có hợp đồng thuê</h3><p>Tìm căn hộ và bắt đầu thuê an toàn qua Escrow.</p><a href="${pageContext.request.contextPath}/apartments" class="btn btn-dark">Tìm căn hộ</a></div>
      </c:when>
      <c:otherwise>
        <c:forEach var="ct" items="${rentedContracts}">
          <div class="contract-card">
            <img src="https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=200" alt="">
            <div style="flex:1;min-width:0;">
              <div class="cc-title">${ct.aptTitle}</div>
              <div class="cc-meta"><span><i class="fas fa-calendar"></i><fmt:formatDate value="${ct.startDate}" pattern="dd/MM/yyyy"/> → <fmt:formatDate value="${ct.endDate}" pattern="dd/MM/yyyy"/></span><span><i class="fas fa-coins"></i><fmt:formatNumber value="${ct.monthlyRent}" pattern="#,###"/> ₫/tháng</span></div>
              <div class="cc-actions">
                <span class="badge ${ct.status=='active'?'badge-green':ct.status=='pending'?'badge-amber':ct.status=='approved'?'badge-accent':'badge-dark'}"><c:choose><c:when test="${ct.status=='pending'}">Chờ duyệt</c:when><c:when test="${ct.status=='approved'}">Cần TT</c:when><c:when test="${ct.status=='active'}">Hiệu lực</c:when><c:otherwise>${ct.status}</c:otherwise></c:choose></span>
                <a href="${pageContext.request.contextPath}/user/contract/detail/${ct.contractId}" class="btn btn-outline btn-sm">Chi tiết</a>
                <c:if test="${ct.status=='approved'}"><a href="${pageContext.request.contextPath}/user/payment/checkout/${ct.contractId}?type=initial" class="btn btn-accent btn-sm"><i class="fas fa-lock"></i> Thanh toán</a></c:if>
              </div>
            </div>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </div>

  <div id="tab-myapts" style="display:none;padding-top:28px;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;">
      <h2 class="sec-title" style="margin:0;">Căn hộ của tôi</h2>
      <a href="${pageContext.request.contextPath}/user/apartment/post" class="btn btn-dark btn-sm"><i class="fas fa-plus"></i> Đăng tin mới</a>
    </div>
    <c:if test="${not empty landlordContracts}">
      <c:forEach var="lc" items="${landlordContracts}">
        <c:if test="${lc.status=='pending'}">
          <div class="contract-card" style="border-left:3px solid var(--accent);">
            <img src="https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=200" alt="">
            <div style="flex:1;min-width:0;"><div class="cc-title" style="color:var(--accent);"><i class="fas fa-bell" style="margin-right:6px;"></i>Yêu cầu mới: ${lc.aptTitle}</div><div class="cc-meta"><span><i class="fas fa-user"></i>${lc.tenantName}</span></div><div class="cc-actions"><span class="badge badge-amber">Chờ xác nhận</span><a href="${pageContext.request.contextPath}/user/contract/detail/${lc.contractId}" class="btn btn-accent btn-sm">Xem &amp; Xác nhận</a></div></div>
          </div>
        </c:if>
      </c:forEach>
    </c:if>
    <c:choose>
      <c:when test="${empty myApartments}">
        <div class="empty"><i class="fas fa-home"></i><h3>Chưa có căn hộ nào</h3><a href="${pageContext.request.contextPath}/user/apartment/post" class="btn btn-dark">Đăng tin ngay</a></div>
      </c:when>
      <c:otherwise>
        <div class="prop-grid" style="grid-template-columns:repeat(auto-fill,minmax(300px,1fr));">
          <c:forEach var="apt" items="${myApartments}">
            <div class="prop-card">
              <div class="prop-img"><img src="https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400" alt="">
              <span class="prop-tag ${apt.status=='approved'?'both':apt.status=='pending'?'short':''}"><c:choose><c:when test="${apt.status=='pending'}">Chờ duyệt</c:when><c:when test="${apt.status=='approved'}">Đã duyệt</c:when><c:when test="${apt.status=='rented'}">Đang cho thuê</c:when><c:otherwise>${apt.status}</c:otherwise></c:choose></span></div>
              <div class="prop-body"><p class="prop-location">${apt.district}, ${apt.city}</p><h3 class="prop-name">${apt.title}</h3><div class="prop-footer"><div class="prop-price"><fmt:formatNumber value="${apt.rentPrice}" pattern="#,###"/> <small>₫/tháng</small></div><c:if test="${apt.status=='approved'}"><a href="${pageContext.request.contextPath}/apartment/${apt.aptId}" class="btn btn-outline btn-xs">Xem</a></c:if><a href="${pageContext.request.contextPath}/user/apartment/edit/${apt.aptId}" class="btn btn-outline btn-xs" style="margin-left:6px;">Chỉnh sửa</a></div></div>
            </div>
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>
  </div>

  <div id="tab-settings" style="display:none;padding-top:36px;">
    <div style="max-width:540px;">
      <c:if test="${not empty error}"><div class="alert alert-error"><i class="fas fa-circle-xmark"></i>${error}</div></c:if>
      <h2 class="sec-title">Thông tin cá nhân</h2>
      <form action="${pageContext.request.contextPath}/user/profile" method="post">
        <input type="hidden" name="action" value="updateProfile">
        <div class="form-group"><label class="form-label">Họ và tên</label><input type="text" name="fullName" class="form-control" value="${sessionScope.loggedUser.fullName}" required></div>
        <div class="form-group"><label class="form-label">Email</label><input type="email" class="form-control" value="${sessionScope.loggedUser.email}" disabled></div>
        <div class="form-row">
          <div class="form-group"><label class="form-label">Số điện thoại</label><input type="tel" name="phone" class="form-control" value="${sessionScope.loggedUser.phone}"></div>
          <div class="form-group"><label class="form-label">Số CCCD/CMND <span class="badge badge-amber" style="font-size:9px;vertical-align:middle;">eKYC</span></label><input type="text" name="cccd" class="form-control" value="${sessionScope.loggedUser.cccd}" placeholder="012345678901"></div>
        </div>
        <button type="submit" class="btn btn-dark"><i class="fas fa-floppy-disk"></i> Lưu thay đổi</button>
      </form>
    </div>
  </div>
</div>

<script>
function switchTab(id, el) {
  ['tab-rented','tab-myapts','tab-settings'].forEach(function(t){
    var p=document.getElementById(t); if(p){p.style.display='none';}
  });
  document.querySelectorAll('#profileTabsBar .tab').forEach(function(t){t.classList.remove('on');});
  document.getElementById(id).style.display='block';
  if(el) el.classList.add('on');
}
</script>
<%@ include file="../includes/footer.jsp" %>
