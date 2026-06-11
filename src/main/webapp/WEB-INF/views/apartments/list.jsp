<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Tìm Kiếm Căn Hộ — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>

<div class="page-strip">
  <div style="padding:60px 80px;">
    <span class="eyebrow">Khám phá</span>
    <h1 style="font-family:var(--serif);font-size:clamp(28px,4vw,48px);font-weight:700;color:var(--white);margin-bottom:8px;letter-spacing:-.03em;">Tìm căn hộ phù hợp</h1>
    <p style="color:rgba(255,255,255,.45);font-size:14px;line-height:1.75;">Địa chỉ chi tiết chỉ hiển thị sau khi hợp đồng được xác nhận.</p>
  </div>
</div>

<%-- Search bar --%>
<div class="search-section" style="padding:28px 80px;">
  <form action="${pageContext.request.contextPath}/apartments" method="get">
    <div class="search-bar" style="grid-template-columns:2fr 1fr 1fr 1fr 1fr auto;">
      <div class="search-field">
        <label>Từ khóa / Khu vực</label>
        <input type="text" name="keyword" value="${param.keyword}" placeholder="Cầu Giấy, Vinhomes...">
      </div>
      <div class="search-field">
        <label>Quận / Huyện</label>
        <select name="district">
          <option value="">Tất cả quận</option>
          <c:forEach var="d" items="${districts}">
            <option value="${d}" ${param.district==d?'selected':''}>${d}</option>
          </c:forEach>
        </select>
      </div>
      <div class="search-field">
        <label>Hình thức thuê</label>
        <select name="rentalType">
          <option value="">Tất cả</option>
          <option value="short" ${param.rentalType=='short'?'selected':''}>Ngắn hạn</option>
          <option value="long"  ${param.rentalType=='long' ?'selected':''}>Dài hạn</option>
        </select>
      </div>
      <div class="search-field">
        <label>Loại phòng</label>
        <select name="type">
          <option value="">Tất cả</option>
          <option value="studio"    ${param.type=='studio'   ?'selected':''}>Studio</option>
          <option value="1br"       ${param.type=='1br'      ?'selected':''}>1 Phòng ngủ</option>
          <option value="2br"       ${param.type=='2br'      ?'selected':''}>2 Phòng ngủ</option>
          <option value="3br"       ${param.type=='3br'      ?'selected':''}>3+ Phòng ngủ</option>
        </select>
      </div>
      <div class="search-field">
        <label>Giá tối đa</label>
        <select name="maxPrice">
          <option value="">Không giới hạn</option>
          <option value="5000000"  ${param.maxPrice=='5000000' ?'selected':''}>Dưới 5 triệu</option>
          <option value="10000000" ${param.maxPrice=='10000000'?'selected':''}>Dưới 10 triệu</option>
          <option value="20000000" ${param.maxPrice=='20000000'?'selected':''}>Dưới 20 triệu</option>
          <option value="50000000" ${param.maxPrice=='50000000'?'selected':''}>Dưới 50 triệu</option>
        </select>
      </div>
      <button type="submit" class="search-btn">Tìm kiếm →</button>
    </div>
  </form>
</div>

<div class="container" style="padding-top:40px;padding-bottom:80px;">
  <div class="sec-tip" style="margin-bottom:24px;">
    <i class="fas fa-shield-halved"></i>
    <span>Địa chỉ và SĐT chủ nhà được <strong>ẩn để bảo mật</strong> — hiển thị đầy đủ sau khi hợp đồng xác nhận.</span>
  </div>
  <p style="font-size:13px;color:var(--light);margin-bottom:28px;letter-spacing:.5px;text-transform:uppercase;">
    <c:choose>
      <c:when test="${not empty apartments}">Tìm thấy <strong style="color:var(--dark);">${apartments.size()}</strong> căn hộ phù hợp</c:when>
      <c:otherwise>Không tìm thấy kết quả phù hợp</c:otherwise>
    </c:choose>
  </p>
  <c:choose>
    <c:when test="${empty apartments}">
      <div class="empty">
        <i class="fas fa-search"></i>
        <h3>Không tìm thấy căn hộ</h3>
        <p>Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm.</p>
        <a href="${pageContext.request.contextPath}/apartments" class="btn btn-dark">Xem tất cả căn hộ</a>
      </div>
    </c:when>
    <c:otherwise>
      <div class="prop-grid">
        <c:forEach var="apt" items="${apartments}">
          <a href="${pageContext.request.contextPath}/apartment/${apt.aptId}" class="prop-card">
            <div class="prop-img">
              <img src="${not empty apt.primaryImage ? apt.primaryImage : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600'}" alt="${apt.title}" loading="lazy">
              <span class="prop-tag ${apt.rentalType=='short'?'short':apt.rentalType=='both'?'both':''}">
                <c:choose>
                  <c:when test="${apt.rentalType=='short'}">Ngắn hạn</c:when>
                  <c:when test="${apt.rentalType=='long'}">Dài hạn</c:when>
                  <c:otherwise>Linh hoạt</c:otherwise>
                </c:choose>
              </span>
              <span class="prop-verified"><i class="fas fa-circle-check"></i> Xác thực</span>
              <button class="prop-fav" data-apt-id="${apt.aptId}" onclick="event.preventDefault();">♡</button>
            </div>
            <div class="prop-body">
              <p class="prop-location">${apt.district}, ${apt.city}</p>
              <h3 class="prop-name">${apt.title}</h3>
              <div class="prop-meta">
                <c:choose><c:when test="${apt.bedrooms>0}"><span>🛏 ${apt.bedrooms} PN</span></c:when><c:otherwise><span>🛋 Studio</span></c:otherwise></c:choose>
                <span>🚿 ${apt.bathrooms} WC</span>
                <span>📐 ${apt.area} m²</span>
                <span>🏢 Tầng ${apt.floor}</span>
              </div>
              <div class="prop-footer">
                <div class="prop-price"><fmt:formatNumber value="${apt.rentPrice}" pattern="#,###"/> <small>₫/tháng</small></div>
                <span style="font-size:11px;letter-spacing:1px;text-transform:uppercase;padding:4px 10px;background:#E8F4E8;color:#2A6B2A;">Còn trống</span>
              </div>
            </div>
          </a>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</div>

<%-- ── PHÂN TRANG ── --%>
<c:if test="${totalPages > 1}">
  <div style="padding:48px 80px 64px;display:flex;align-items:center;justify-content:center;gap:6px;flex-wrap:wrap;">

    <%-- Trang trước --%>
    <c:choose>
      <c:when test="${currentPage > 1}">
        <a href="${pageContext.request.contextPath}/apartments?page=${currentPage-1}${not empty param.keyword?'&keyword='.concat(param.keyword):''}${not empty param.district?'&district='.concat(param.district):''}${not empty param.rentalType?'&rentalType='.concat(param.rentalType):''}${not empty param.type?'&type='.concat(param.type):''}${not empty param.maxPrice?'&maxPrice='.concat(param.maxPrice):''}"
           style="display:inline-flex;align-items:center;justify-content:center;width:38px;height:38px;border:1px solid var(--border);color:var(--mid);font-size:13px;transition:all .2s;text-decoration:none;"
           onmouseover="this.style.background='var(--dark)';this.style.color='var(--white)';this.style.borderColor='var(--dark)'"
           onmouseout="this.style.background='';this.style.color='var(--mid)';this.style.borderColor='var(--border)'">‹</a>
      </c:when>
      <c:otherwise>
        <span style="display:inline-flex;align-items:center;justify-content:center;width:38px;height:38px;border:1px solid var(--border);color:var(--border);font-size:13px;cursor:not-allowed;">‹</span>
      </c:otherwise>
    </c:choose>

    <%-- Các số trang: hiện tối đa 7 trang quanh trang hiện tại --%>
    <c:forEach var="i" begin="1" end="${totalPages}">
      <c:if test="${i == 1 || i == totalPages || (i >= currentPage-2 && i <= currentPage+2)}">
        <c:choose>
          <c:when test="${i == currentPage}">
            <span style="display:inline-flex;align-items:center;justify-content:center;width:38px;height:38px;background:var(--dark);color:var(--white);border:1px solid var(--dark);font-size:13px;font-weight:600;">${i}</span>
          </c:when>
          <c:otherwise>
            <a href="${pageContext.request.contextPath}/apartments?page=${i}${not empty param.keyword?'&keyword='.concat(param.keyword):''}${not empty param.district?'&district='.concat(param.district):''}${not empty param.rentalType?'&rentalType='.concat(param.rentalType):''}${not empty param.type?'&type='.concat(param.type):''}${not empty param.maxPrice?'&maxPrice='.concat(param.maxPrice):''}"
               style="display:inline-flex;align-items:center;justify-content:center;width:38px;height:38px;border:1px solid var(--border);color:var(--mid);font-size:13px;transition:all .2s;text-decoration:none;"
               onmouseover="this.style.background='var(--dark)';this.style.color='var(--white)';this.style.borderColor='var(--dark)'"
               onmouseout="this.style.background='';this.style.color='var(--mid)';this.style.borderColor='var(--border)'">${i}</a>
          </c:otherwise>
        </c:choose>
      </c:if>
      <%-- Dấu ... --%>
      <c:if test="${(i == 1 && currentPage > 4) || (i == totalPages-1 && currentPage < totalPages-3)}">
        <span style="display:inline-flex;align-items:center;justify-content:center;width:38px;height:38px;color:var(--light);font-size:13px;">…</span>
      </c:if>
    </c:forEach>

    <%-- Trang tiếp --%>
    <c:choose>
      <c:when test="${currentPage < totalPages}">
        <a href="${pageContext.request.contextPath}/apartments?page=${currentPage+1}${not empty param.keyword?'&keyword='.concat(param.keyword):''}${not empty param.district?'&district='.concat(param.district):''}${not empty param.rentalType?'&rentalType='.concat(param.rentalType):''}${not empty param.type?'&type='.concat(param.type):''}${not empty param.maxPrice?'&maxPrice='.concat(param.maxPrice):''}"
           style="display:inline-flex;align-items:center;justify-content:center;width:38px;height:38px;border:1px solid var(--border);color:var(--mid);font-size:13px;transition:all .2s;text-decoration:none;"
           onmouseover="this.style.background='var(--dark)';this.style.color='var(--white)';this.style.borderColor='var(--dark)'"
           onmouseout="this.style.background='';this.style.color='var(--mid)';this.style.borderColor='var(--border)'">›</a>
      </c:when>
      <c:otherwise>
        <span style="display:inline-flex;align-items:center;justify-content:center;width:38px;height:38px;border:1px solid var(--border);color:var(--border);font-size:13px;cursor:not-allowed;">›</span>
      </c:otherwise>
    </c:choose>

    <%-- Thông tin trang --%>
    <span style="margin-left:16px;font-size:12px;color:var(--light);letter-spacing:.5px;">
      Trang ${currentPage} / ${totalPages} &nbsp;·&nbsp; ${totalCount} căn hộ
    </span>
  </div>
</c:if>

<script>
document.querySelectorAll('.prop-fav').forEach(function(btn){
  btn.addEventListener('click',function(e){e.stopPropagation();e.preventDefault();this.textContent=this.textContent==='♡'?'♥':'♡';this.style.color=this.textContent==='♥'?'#C84E4E':'';});
});
</script>

<%@ include file="../includes/footer.jsp" %>
