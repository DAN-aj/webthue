<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Đánh Giá Căn Hộ — Admin"/>
<%@ include file="../includes/header.jsp" %>
<div class="admin-shell">
  <%@ include file="sidebar.jsp" %>
  <main class="admin-main">
    <div class="admin-header">
      <div style="display:flex;align-items:center;gap:14px;">
        <h1>Đánh giá căn hộ</h1>
        <span class="badge badge-amber">${pendingCount} chờ duyệt</span>
      </div>
      <p>${reviews.size()} kết quả</p>
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

    <%-- Filter tabs --%>
    <div style="display:flex;gap:8px;margin-bottom:20px;border-bottom:1px solid var(--border);padding-bottom:0;">
      <a href="${pageContext.request.contextPath}/admin/reviews?filter=pending"
         style="padding:8px 18px;font-size:13px;font-weight:600;text-decoration:none;border-bottom:2px solid ${filter=='pending'?'var(--dark)':'transparent'};color:${filter=='pending'?'var(--dark)':'var(--light)'};">
        Chờ duyệt <c:if test="${pendingCount > 0}"><span class="badge badge-amber" style="margin-left:4px;">${pendingCount}</span></c:if>
      </a>
      <a href="${pageContext.request.contextPath}/admin/reviews?filter=approved"
         style="padding:8px 18px;font-size:13px;font-weight:600;text-decoration:none;border-bottom:2px solid ${filter=='approved'?'var(--dark)':'transparent'};color:${filter=='approved'?'var(--dark)':'var(--light)'};">
        Đã duyệt
      </a>
      <a href="${pageContext.request.contextPath}/admin/reviews?filter=rejected"
         style="padding:8px 18px;font-size:13px;font-weight:600;text-decoration:none;border-bottom:2px solid ${filter=='rejected'?'var(--dark)':'transparent'};color:${filter=='rejected'?'var(--dark)':'var(--light)'};">
        Đã từ chối
      </a>
    </div>

    <c:choose>
      <c:when test="${empty reviews}">
        <div style="padding:60px;text-align:center;background:var(--white);border:1px solid var(--border);">
          <div style="font-size:32px;margin-bottom:12px;">✓</div>
          <div style="color:var(--mid);font-size:15px;">
            <c:choose>
              <c:when test="${filter=='pending'}">Không có đánh giá nào đang chờ duyệt.</c:when>
              <c:when test="${filter=='approved'}">Chưa có đánh giá nào được duyệt.</c:when>
              <c:otherwise>Chưa có đánh giá nào bị từ chối.</c:otherwise>
            </c:choose>
          </div>
        </div>
      </c:when>
      <c:otherwise>
        <div style="display:flex;flex-direction:column;gap:16px;">
          <c:forEach var="rv" items="${reviews}">
            <div style="background:var(--white);border:1px solid var(--border);padding:24px;border-radius:2px;">
              <div style="display:flex;align-items:flex-start;gap:16px;flex-wrap:wrap;">

                <%-- Avatar + meta --%>
                <div style="display:flex;align-items:center;gap:12px;flex:1;min-width:200px;">
                  <div style="width:40px;height:40px;border-radius:50%;background:var(--dark);color:var(--accent);
                              display:flex;align-items:center;justify-content:center;font-weight:700;
                              font-size:16px;font-family:var(--serif);flex-shrink:0;">
                    ${rv.reviewerFirstLetter}
                  </div>
                  <div>
                    <div style="font-weight:600;font-size:14px;">${rv.reviewerName}</div>
                    <div style="font-size:12px;color:var(--light);margin-top:2px;">
                      Căn hộ: <strong>${rv.aptTitle}</strong>
                    </div>
                    <div style="font-size:11px;color:var(--light);margin-top:2px;">
                      <fmt:formatDate value="${rv.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                    </div>
                  </div>
                </div>

                <%-- Stars --%>
                <div style="color:var(--accent);font-size:18px;flex-shrink:0;">
                  ${rv.stars}
                  <span style="font-size:12px;color:var(--mid);margin-left:4px;">(${rv.rating}/5)</span>
                </div>

                <%-- Actions (only for pending) --%>
                <c:if test="${filter == 'pending'}">
                  <div style="display:flex;gap:8px;flex-shrink:0;">
                    <form action="${pageContext.request.contextPath}/admin/review/${rv.reviewId}" method="post" style="display:inline;">
                      <input type="hidden" name="action" value="approve">
                      <button type="submit" class="btn btn-outline btn-xs"
                              style="background:#d1f7e0;border-color:#4caf50;color:#155724;"
                              onclick="return confirm('Duyệt đánh giá này?')">
                        <i class="fas fa-circle-check"></i> Duyệt
                      </button>
                    </form>
                    <form action="${pageContext.request.contextPath}/admin/review/${rv.reviewId}" method="post" style="display:inline;">
                      <input type="hidden" name="action" value="reject">
                      <button type="submit" class="btn btn-outline btn-xs"
                              style="background:#fde8e8;border-color:#e57373;color:#721c24;"
                              onclick="return confirm('Từ chối đánh giá này?')">
                        <i class="fas fa-ban"></i> Từ chối
                      </button>
                    </form>
                  </div>
                </c:if>
                <c:if test="${filter != 'pending'}">
                  <span class="badge ${filter == 'approved' ? 'badge-dark' : 'badge-amber'}"
                        style="${filter == 'rejected' ? 'background:#fde8e8;color:#721c24;' : ''}">
                    ${filter == 'approved' ? 'Đã duyệt' : 'Đã từ chối'}
                  </span>
                </c:if>
              </div>

              <%-- Comment --%>
              <div style="margin-top:16px;padding:14px 16px;background:var(--cream);border-left:3px solid var(--border);
                          font-size:14px;line-height:1.8;color:var(--mid);">
                ${rv.comment}
              </div>
            </div>
          </c:forEach>
        </div>
      </c:otherwise>
    </c:choose>

  </main>
</div>

<script>
(function(){
  var btn  = document.getElementById("avatarBtn");
  var drop = document.getElementById("navDrop");
  if (!btn || !drop) return;
  btn.addEventListener("click", function(e){ e.stopPropagation(); drop.classList.toggle("open"); });
  drop.addEventListener("click", function(e){ e.stopPropagation(); });
  document.addEventListener("click", function(){ drop.classList.remove("open"); });
  var ham  = document.getElementById("hamburger");
  var menu = document.getElementById("navMenu");
  if (ham && menu) {
    ham.addEventListener("click", function(e){ e.stopPropagation(); menu.classList.toggle("open"); });
    document.addEventListener("click", function(){ menu.classList.remove("open"); });
  }
  document.querySelectorAll(".auto-dismiss").forEach(function(a){
    setTimeout(function(){ a.style.opacity="0"; a.style.transition="opacity .4s"; setTimeout(function(){ a.remove(); },400); }, 4000);
  });
})();
</script>
</body></html>
