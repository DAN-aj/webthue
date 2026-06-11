<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="${apartment.title} — Admin"/>
<%@ include file="../includes/header.jsp" %>
<div class="admin-shell">
  <%@ include file="sidebar.jsp" %>
  <main class="admin-main">
    <div class="admin-header">
      <a href="${pageContext.request.contextPath}/admin/apartments" style="font-size:12px;color:var(--light);letter-spacing:1px;text-transform:uppercase;display:inline-flex;align-items:center;gap:6px;margin-bottom:14px;"><i class="fas fa-arrow-left"></i>Quay lại danh sách</a>
      <h1>${apartment.title}</h1>
      <div style="margin-top:10px;"><span class="badge ${apartment.status=='approved'?'badge-green':apartment.status=='pending'?'badge-amber':'badge-red'}" style="font-size:12px;padding:5px 14px;"><c:choose><c:when test="${apartment.status=='pending'}">Chờ kiểm duyệt</c:when><c:when test="${apartment.status=='approved'}">Đã duyệt</c:when><c:when test="${apartment.status=='rejected'}">Từ chối</c:when><c:otherwise>${apartment.status}</c:otherwise></c:choose></span></div>
    </div>
    <div style="display:grid;grid-template-columns:1fr 320px;gap:24px;align-items:start;">
      <div>
        <c:if test="${not empty apartment.images}">
          <div style="background:var(--white);border:1px solid var(--border);margin-bottom:20px;overflow:hidden;">
            <img src="${apartment.images[0]}" alt="" style="width:100%;height:300px;object-fit:cover;display:block;">
            <c:if test="${apartment.images.size()>1}"><div style="display:flex;gap:2px;padding:2px 0 0;"><c:forEach var="img" items="${apartment.images}"><img src="${img}" alt="" style="width:80px;height:54px;object-fit:cover;"></c:forEach></div></c:if>
          </div>
        </c:if>
        <div style="background:var(--white);border:1px solid var(--border);padding:28px;">
          <h2 class="sec-title">Thông tin chi tiết</h2>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:0;">
            <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Địa chỉ</span><span style="font-size:13px;">${apartment.address}</span></div>
            <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Quận / Thành phố</span><span>${apartment.district}, ${apartment.city}</span></div>
            <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Loại căn hộ</span><span>${apartment.typeLabel}</span></div>
            <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Diện tích</span><span>${apartment.area} m²</span></div>
            <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Phòng ngủ / tắm</span><span>${apartment.bedrooms} PN / ${apartment.bathrooms} WC</span></div>
            <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Tầng</span><span>${apartment.floor}/${apartment.totalFloors}</span></div>
            <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Giá thuê/tháng</span><span style="font-family:var(--serif);font-size:16px;font-weight:700;color:var(--accent);"><fmt:formatNumber value="${apartment.rentPrice}" pattern="#,###"/>₫</span></div>
            <c:if test="${not empty apartment.rentPriceDay}">
              <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Giá thuê/ngày</span><span style="font-family:var(--serif);font-size:14px;font-weight:600;color:var(--accent);"><fmt:formatNumber value="${apartment.rentPriceDay}" pattern="#,###"/>₫</span></div>
            </c:if>
            <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Hình thức thuê</span><span>${apartment.rentalTypeLabel}</span></div>
            <c:if test="${not empty apartment.furniture}">
              <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Nội thất</span><span>${apartment.furniture}</span></div>
            </c:if>
            <c:if test="${not empty apartment.direction}">
              <div class="ps-row"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Hướng ban công</span><span>${apartment.direction}</span></div>
            </c:if>
            <c:if test="${not empty apartment.view}">
              <div class="ps-row" style="border:none;"><span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">View</span><span>${apartment.view}</span></div>
            </c:if>
          </div>
          <c:if test="${not empty apartment.amenities}">
            <div style="margin-top:20px;padding-top:20px;border-top:1px solid var(--border);">
              <p style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;margin-bottom:10px;">Tiện nghi</p>
              <p style="font-size:13px;color:var(--mid);line-height:1.8;">${apartment.amenities}</p>
            </div>
          </c:if>
        </div>
      </div>
      <div>
        <div style="background:var(--white);border:1px solid var(--border);padding:24px;margin-bottom:16px;">
          <p style="font-size:10px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:16px;">Thông tin chủ nhà</p>
          <div style="display:flex;align-items:center;gap:12px;padding:16px;background:var(--cream);">
            <div class="owner-ava">${apartment.firstLetter}</div>
            <div><div class="owner-name">${apartment.ownerName}</div><div class="owner-meta-txt"><i class="fas fa-phone" style="color:var(--accent);margin-right:3px;"></i>${apartment.ownerPhone}</div><div class="owner-meta-txt"><i class="fas fa-envelope" style="color:var(--accent);margin-right:3px;"></i>${apartment.ownerEmail}</div></div>
          </div>
        </div>
        <c:if test="${apartment.status=='pending'}">
          <div style="background:var(--white);border:1px solid var(--border);padding:24px;">
            <p style="font-size:10px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:18px;">Kiểm duyệt tin đăng</p>
            <form action="${pageContext.request.contextPath}/admin/apartment/${apartment.aptId}" method="post" style="margin-bottom:10px;"><input type="hidden" name="action" value="approve"><button class="btn-approve" style="width:100%;padding:12px;"><i class="fas fa-check"></i> Phê duyệt tin đăng</button></form>
            <form action="${pageContext.request.contextPath}/admin/apartment/${apartment.aptId}" method="post">
              <input type="hidden" name="action" value="reject">
              <div class="form-group" style="margin-bottom:10px;"><label class="form-label req">Lý do từ chối</label><textarea name="reason" class="form-control" rows="3" placeholder="Nêu rõ lý do..."></textarea></div>
              <button class="btn-reject" style="width:100%;padding:12px;"><i class="fas fa-xmark"></i> Từ chối</button>
            </form>
          </div>
        </c:if>
        <c:if test="${apartment.status=='approved'}"><div class="alert alert-success" style="margin-top:0;"><i class="fas fa-circle-check"></i>Tin đăng đã phê duyệt.</div></c:if>
        <a href="${pageContext.request.contextPath}/apartment/${apartment.aptId}" class="btn btn-outline btn-block btn-sm" style="margin-top:12px;" target="_blank"><i class="fas fa-external-link-alt"></i> Xem trang công khai</a>
      </div>
    </div>
  </main>
</div>

<script>
/* Admin nav dropdown */
(function(){
  var btn  = document.getElementById("avatarBtn");
  var drop = document.getElementById("navDrop");
  if (!btn || !drop) return;
  btn.addEventListener("click", function(e){
    e.stopPropagation();
    drop.classList.toggle("open");
  });
  drop.addEventListener("click", function(e){ e.stopPropagation(); });
  document.addEventListener("click", function(){ drop.classList.remove("open"); });
  /* Hamburger */
  var ham  = document.getElementById("hamburger");
  var menu = document.getElementById("navMenu");
  if (ham && menu) {
    ham.addEventListener("click", function(e){
      e.stopPropagation();
      menu.classList.toggle("open");
    });
    document.addEventListener("click", function(){ menu.classList.remove("open"); });
  }
  /* Auto-dismiss alerts */
  document.querySelectorAll(".auto-dismiss").forEach(function(a){
    setTimeout(function(){ a.style.opacity="0"; a.style.transition="opacity .4s"; setTimeout(function(){ a.remove(); },400); }, 4000);
  });
})();
</script>
</body></html>
