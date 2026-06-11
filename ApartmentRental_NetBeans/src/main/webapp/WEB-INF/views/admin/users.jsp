<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Quản Lý Tài Khoản — Admin"/>
<%@ include file="../includes/header.jsp" %>
<div class="admin-shell">
  <%@ include file="sidebar.jsp" %>
  <main class="admin-main">
    <div class="admin-header">
      <h1>Quản lý tài khoản</h1>
      <p id="countLabel">${totalCount} người dùng trong hệ thống</p>
    </div>

    <c:if test="${param.success=='1'}">
      <div class="alert alert-success auto-dismiss" style="margin-bottom:24px;">
        <i class="fas fa-circle-check"></i>Đã cập nhật thành công.
      </div>
    </c:if>

    <%-- Search/Filter bar — server-side --%>
    <form method="get" action="${pageContext.request.contextPath}/admin/users"
          style="display:flex;gap:10px;margin-bottom:18px;flex-wrap:wrap;align-items:center;">
      <input name="q" type="text" placeholder="Tìm theo tên, email, SĐT…"
             value="${keyword}"
             style="flex:1;min-width:200px;border:1px solid var(--border);padding:8px 13px;font-size:13px;font-family:var(--sans);background:var(--white);">
      <select name="status"
              style="border:1px solid var(--border);padding:8px 13px;font-size:13px;font-family:var(--sans);background:var(--white);cursor:pointer;">
        <option value="">Tất cả trạng thái</option>
        <option value="active"  ${statusFilter=='active' ?'selected':''}>Hoạt động</option>
        <option value="locked"  ${statusFilter=='locked' ?'selected':''}>Bị khóa</option>
      </select>
      <button type="submit"
              style="padding:8px 18px;background:var(--dark);color:#fff;border:none;font-size:13px;font-family:var(--sans);cursor:pointer;">
        Tìm kiếm
      </button>
      <c:if test="${not empty keyword || not empty statusFilter}">
        <a href="${pageContext.request.contextPath}/admin/users"
           style="font-size:13px;color:var(--light);text-decoration:none;">✕ Xoá tìm kiếm</a>
      </c:if>
    </form>

    <div style="background:var(--white);border:1px solid var(--border);">
      <div class="table-wrap" style="border:none;">
        <table id="userTable">
          <thead>
            <tr>
              <th>ID</th><th>Người dùng</th><th>Email</th>
              <th>SĐT</th><th>Ngày đăng ký</th><th>Trạng thái</th><th>Hành động</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="u" items="${users}">
              <tr data-name="${u.fullName}" data-email="${u.email}"
                  data-phone="${u.phone != null ? u.phone : ''}"
                  data-status="${u.status}">
                <td style="color:var(--light);font-size:12px;">#${u.userId}</td>
                <td>
                  <div style="display:flex;align-items:center;gap:10px;">
                    <div style="width:32px;height:32px;border-radius:50%;background:var(--accent);display:flex;align-items:center;justify-content:center;font-family:var(--serif);font-size:14px;font-weight:700;color:var(--dark);flex-shrink:0;">${u.firstLetter}</div>
                    <span style="font-family:var(--serif);font-size:15px;font-weight:600;">${u.fullName}</span>
                  </div>
                </td>
                <td style="color:var(--mid);">${u.email}</td>
                <td style="color:var(--mid);">${u.phone}</td>
                <td style="color:var(--light);font-size:12px;"><fmt:formatDate value="${u.createdAt}" pattern="dd/MM/yyyy"/></td>
                <td><span class="badge ${u.status=='active'?'badge-green':'badge-red'}">${u.status=='active'?'Hoạt động':'Bị khóa'}</span></td>
                <td>
                  <div style="display:flex;gap:6px;">
                    <form action="${pageContext.request.contextPath}/admin/user/${u.userId}" method="post" style="display:inline;">
                      <c:choose>
                        <c:when test="${u.status=='active'}">
                          <input type="hidden" name="action" value="lock">
                          <button class="btn-reject" style="padding:5px 12px;" data-confirm="Khóa tài khoản ${u.fullName}?">
                            <i class="fas fa-lock"></i> Khóa
                          </button>
                        </c:when>
                        <c:otherwise>
                          <input type="hidden" name="action" value="unlock">
                          <button class="btn-approve" style="padding:5px 12px;">
                            <i class="fas fa-lock-open"></i> Mở
                          </button>
                        </c:otherwise>
                      </c:choose>
                    </form>
                    <form action="${pageContext.request.contextPath}/admin/user/${u.userId}" method="post" style="display:inline;">
                      <input type="hidden" name="action" value="delete">
                      <button class="btn btn-outline btn-xs" data-confirm="Xóa tài khoản ${u.fullName}? Không thể hoàn tác!">
                        <i class="fas fa-trash"></i>
                      </button>
                    </form>
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
      <c:set var="pBase" value="?q=${keyword}&status=${statusFilter}"/>
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
        <span style="font-size:12px;color:var(--light);margin-left:8px;">Trang ${page}/${totalPages} · ${totalCount} người dùng</span>
      </div>
    </c:if>
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
