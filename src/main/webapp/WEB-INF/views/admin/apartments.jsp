<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Quản Lý Căn Hộ — Admin"/>
<%@ include file="../includes/header.jsp" %>
<div class="admin-shell">
  <%@ include file="sidebar.jsp" %>
  <main class="admin-main">
    <div class="admin-header">
      <h1>Quản lý căn hộ</h1>
      <p id="countLabel">${totalCount} căn hộ</p>
    </div>

    <c:if test="${param.success=='1'}">
      <div class="alert alert-success auto-dismiss" style="margin-bottom:24px;">
        <i class="fas fa-circle-check"></i>Đã cập nhật thành công.
      </div>
    </c:if>

    <%-- Search/Filter bar — server-side --%>
    <form method="get" action="${pageContext.request.contextPath}/admin/apartments"
          style="display:flex;gap:10px;margin-bottom:18px;flex-wrap:wrap;align-items:center;">
      <input name="q" type="text" placeholder="Tìm theo tên căn hộ, quận, thành phố, tên/email/SĐT chủ nhà…"
             value="${keyword}"
             style="flex:1;min-width:220px;border:1px solid var(--border);padding:8px 13px;font-size:13px;font-family:var(--sans);background:var(--white);">
      <select name="filter"
              style="border:1px solid var(--border);padding:8px 13px;font-size:13px;font-family:var(--sans);background:var(--white);cursor:pointer;">
        <option value="">Tất cả trạng thái</option>
        <option value="pending"  ${filter eq 'pending' ? 'selected' : ''}>Chờ duyệt</option>
        <option value="approved" ${filter eq 'approved' ? 'selected' : ''}>Đã duyệt</option>
        <option value="rejected" ${filter eq 'rejected' ? 'selected' : ''}>Từ chối</option>
        <option value="rented"   ${filter eq 'rented' ? 'selected' : ''}>Đang thuê</option>
      </select>
      <input name="pageSize" type="hidden" value="${pageSize}">
      <button type="submit"
              style="padding:8px 18px;background:var(--dark);color:#fff;border:none;font-size:13px;font-family:var(--sans);cursor:pointer;">
        Tìm kiếm
      </button>
      <c:if test="${not empty keyword}">
        <a href="${pageContext.request.contextPath}/admin/apartments"
           style="font-size:13px;color:var(--light);text-decoration:none;">✕ Xoá tìm kiếm</a>
      </c:if>
    </form>

    <div style="background:var(--white);border:1px solid var(--border);">
      <div class="table-wrap" style="border:none;">
        <table id="aptTable">
          <thead>
            <tr>
              <th>Căn hộ</th><th>Chủ nhà</th><th>Giá thuê</th>
              <th>Loại</th><th>Trạng thái</th><th>Ngày đăng</th><th>Hành động</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="apt" items="${apartments}">
              <tr data-title="${apt.title}" data-district="${apt.district}" data-city="${apt.city}"
                  data-owner="${apt.ownerName}" data-status="${apt.status}"
                  data-type="${apt.rentalType}">
                <td>
                  <a href="${pageContext.request.contextPath}/admin/apartment/${apt.aptId}"
                     style="font-family:var(--serif);font-size:15px;font-weight:700;color:var(--dark);">${apt.title}</a>
                  <div style="font-size:12px;color:var(--light);margin-top:2px;">${apt.district}, ${apt.city}</div>
                </td>
                <td style="color:var(--mid);">${apt.ownerName}</td>
                <td style="font-family:var(--serif);font-size:15px;font-weight:600;">
                  <fmt:formatNumber value="${apt.rentPrice}" pattern="#,###"/>₫
                </td>
                <td><span class="badge badge-dark">${apt.rentalTypeLabel}</span></td>
                <td>
                  <span class="badge ${apt.status=='approved'?'badge-green':apt.status=='pending'?'badge-amber':apt.status=='rented'?'badge-accent':'badge-red'}">
                    <c:choose>
                      <c:when test="${apt.status=='pending'}">Chờ duyệt</c:when>
                      <c:when test="${apt.status=='approved'}">Đã duyệt</c:when>
                      <c:when test="${apt.status=='rejected'}">Từ chối</c:when>
                      <c:when test="${apt.status=='rented'}">Đang thuê</c:when>
                      <c:otherwise>${apt.status}</c:otherwise>
                    </c:choose>
                  </span>
                </td>
                <td style="color:var(--light);font-size:12px;">
                  <fmt:formatDate value="${apt.createdAt}" pattern="dd/MM/yyyy"/>
                </td>
                <td>
                  <div style="display:flex;gap:6px;">
                    <a href="${pageContext.request.contextPath}/admin/apartment/${apt.aptId}"
                       class="btn btn-outline btn-xs">Xem</a>
                    <c:if test="${apt.status=='pending'}">
                      <form action="${pageContext.request.contextPath}/admin/apartment/${apt.aptId}"
                            method="post" style="display:inline;">
                        <input type="hidden" name="action" value="approve">
                        <button class="btn-approve" style="padding:5px 12px;">
                          <i class="fas fa-check"></i> Duyệt
                        </button>
                      </form>
                    </c:if>
                  </div>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
        <div id="emptyMsg" style="display:none;padding:40px;text-align:center;color:var(--light);font-size:14px;">
          Không tìm thấy kết quả phù hợp.
        </div>
      </div>
    </div>

    <%-- Pagination --%>
    <c:if test="${totalPages > 1}">
      <c:set var="pBase" value="?q=${keyword}&filter=${filter}&pageSize=${pageSize}"/>
      <div style="display:flex;align-items:center;justify-content:center;gap:6px;margin-top:24px;flex-wrap:wrap;">
        <c:if test="${page > 1}">
          <a href="${pBase}&page=${page-1}"
             style="padding:7px 14px;border:1px solid var(--border);border-radius:6px;font-size:13px;text-decoration:none;color:var(--dark);">← Trước</a>
        </c:if>
        <c:forEach begin="1" end="${totalPages}" var="p">
          <c:if test="${p >= page-2 && p <= page+2}">
            <a href="${pBase}&page=${p}"
               style="padding:7px 13px;border:1px solid ${p==page?'var(--dark)':'var(--border)'};border-radius:6px;font-size:13px;text-decoration:none;
                      background:${p==page?'var(--dark)':'transparent'};color:${p==page?'#fff':'var(--dark)'};">${p}</a>
          </c:if>
        </c:forEach>
        <c:if test="${page < totalPages}">
          <a href="${pBase}&page=${page+1}"
             style="padding:7px 14px;border:1px solid var(--border);border-radius:6px;font-size:13px;text-decoration:none;color:var(--dark);">Sau →</a>
        </c:if>
        <span style="font-size:12px;color:var(--light);margin-left:8px;">Trang ${page}/${totalPages} · ${totalCount} căn hộ</span>
      </div>
    </c:if>

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
