<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Yêu Cầu Chỉnh Sửa — Admin"/>
<%@ include file="../includes/header.jsp" %>
<div class="admin-shell">
  <%@ include file="sidebar.jsp" %>
  <main class="admin-main">
    <div class="admin-header">
      <div style="display:flex;align-items:center;gap:14px;">
        <h1>Yêu cầu chỉnh sửa</h1>
        <span class="badge badge-amber">${pendingCount} chờ duyệt</span>
      </div>
      <p id="countLabel">${editRequests.size()} yêu cầu</p>
    </div>

    <c:if test="${not empty param.success}">
      <div class="alert alert-success auto-dismiss" style="margin-bottom:24px;">
        <i class="fas fa-circle-check"></i>Thao tác thành công.
      </div>
    </c:if>
    <c:if test="${not empty param.error}">
      <div class="alert alert-error auto-dismiss" style="margin-bottom:24px;">
        Đã xảy ra lỗi, vui lòng thử lại.
      </div>
    </c:if>

    <%-- Filter bar --%>
    <div style="display:flex;gap:10px;margin-bottom:18px;flex-wrap:wrap;align-items:center;">
      <input id="q" type="text" placeholder="Tìm theo tên căn hộ hoặc chủ nhà…"
             style="flex:1;min-width:220px;border:1px solid var(--border);padding:8px 13px;font-size:13px;font-family:var(--sans);background:var(--white);"
             oninput="filterReqs()">
      <select id="fField" onchange="filterReqs()"
              style="border:1px solid var(--border);padding:8px 13px;font-size:13px;font-family:var(--sans);background:var(--white);cursor:pointer;">
        <option value="">Tất cả thay đổi</option>
        <option value="title">Tiêu đề</option>
        <option value="price">Giá</option>
        <option value="amenities">Tiện nghi</option>
        <option value="bedrooms">Phòng ngủ</option>
      </select>
    </div>

    <c:choose>
      <c:when test="${empty editRequests}">
        <div style="padding:60px;text-align:center;background:var(--white);border:1px solid var(--border);">
          <div style="font-size:32px;margin-bottom:12px;">✓</div>
          <div style="color:var(--mid);font-size:15px;">Không có yêu cầu nào đang chờ duyệt.</div>
        </div>
      </c:when>
      <c:otherwise>
        <div style="background:var(--white);border:1px solid var(--border);">
          <div class="table-wrap" style="border:none;">
            <table id="reqTable">
              <thead>
                <tr>
                  <th>#</th><th>Căn hộ</th><th>Chủ nhà</th>
                  <th>Thay đổi</th><th>Ngày gửi</th><th>Hành động</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="er" items="${editRequests}">
                  <tr data-apt="${er.aptTitle}" data-owner="${er.ownerName}"
                      data-fields="${not empty er.newTitle?'title ':''}${not empty er.newRentPriceMonth || not empty er.newRentPriceDay?'price ':''}${not empty er.newAmenities?'amenities ':''}${er.newBedrooms > 0?'bedrooms':''}">
                    <td style="color:var(--light);font-size:12px;">#${er.requestId}</td>
                    <td style="font-weight:600;font-family:var(--serif);">${er.aptTitle}</td>
                    <td style="color:var(--mid);">${er.ownerName}</td>
                    <td style="font-size:12px;">
                      <div style="display:flex;flex-wrap:wrap;gap:4px;">
                        <c:if test="${not empty er.newTitle}">
                          <span class="badge badge-dark">Tiêu đề</span>
                        </c:if>
                        <c:if test="${not empty er.newRentPriceMonth || not empty er.newRentPriceDay}">
                          <span class="badge badge-dark">Giá</span>
                        </c:if>
                        <c:if test="${not empty er.newAmenities}">
                          <span class="badge badge-dark">Tiện nghi</span>
                        </c:if>
                        <c:if test="${er.newBedrooms > 0}">
                          <span class="badge badge-dark">Phòng ngủ</span>
                        </c:if>
                      </div>
                    </td>
                    <td style="color:var(--light);font-size:12px;">
                      <fmt:formatDate value="${er.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                    </td>
                    <td>
                      <a href="${pageContext.request.contextPath}/admin/apartment/edit-request/${er.requestId}"
                         class="btn btn-outline btn-xs">Xem chi tiết</a>
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
      </c:otherwise>
    </c:choose>

    <script>
    function filterReqs() {
      var q     = document.getElementById('q').value.toLowerCase().trim();
      var field = document.getElementById('fField').value;
      var rows  = document.querySelectorAll('#reqTable tbody tr');
      var shown = 0;
      rows.forEach(function(r) {
        var apt    = (r.dataset.apt   || '').toLowerCase();
        var owner  = (r.dataset.owner || '').toLowerCase();
        var fields = (r.dataset.fields || '');
        var matchQ = !q     || apt.includes(q) || owner.includes(q);
        var matchF = !field || fields.includes(field);
        var show   = matchQ && matchF;
        r.style.display = show ? '' : 'none';
        if (show) shown++;
      });
      document.getElementById('countLabel').textContent = shown + ' yêu cầu';
      document.getElementById('emptyMsg').style.display = shown === 0 ? 'block' : 'none';
    }
    </script>
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
