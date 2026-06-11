<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="ChungCư.vn — Thuê Chung Cư Cao Cấp, An Toàn"/>
<%@ include file="includes/header.jsp" %>

<%-- HERO — split layout --%>
<section style="min-height:calc(100vh - 72px - 41px);display:grid;grid-template-columns:1fr 1fr;overflow:hidden;">
  <div style="display:flex;flex-direction:column;justify-content:center;padding:80px;background:var(--cream);">
    <span class="eyebrow"><i class="fas fa-shield-halved" style="margin-right:6px;"></i>Escrow · eKYC · Hợp đồng điện tử</span>
    <h1 style="font-family:var(--serif);font-size:clamp(44px,5.5vw,76px);font-weight:700;line-height:1.0;letter-spacing:-.04em;margin-bottom:28px;color:var(--dark);">
      Căn hộ <em style="font-style:italic;color:var(--accent);">lý tưởng</em><br>của bạn<br>đang chờ.
    </h1>
    <p style="font-size:17px;line-height:1.75;color:var(--mid);max-width:420px;margin-bottom:48px;font-weight:300;">
      Hàng nghìn căn hộ được xác thực. Ký hợp đồng điện tử, thanh toán an toàn — tất cả trên một nền tảng.
    </p>
    <div style="display:flex;gap:16px;flex-wrap:wrap;">
      <a href="${pageContext.request.contextPath}/apartments" class="btn btn-dark btn-lg">Tìm căn hộ ngay</a>
      <a href="${pageContext.request.contextPath}/user/apartment/post" style="font-size:14px;color:var(--mid);border-bottom:1px solid var(--border);padding-bottom:2px;align-self:center;transition:all .2s;">Đăng tin cho thuê →</a>
    </div>
    <div style="display:flex;gap:48px;margin-top:60px;padding-top:40px;border-top:1px solid var(--border);">
      <div>
        <div style="font-family:var(--serif);font-size:36px;font-weight:700;line-height:1;">${not empty totalApartments ? totalApartments : '1,200'}<span style="color:var(--accent);">+</span></div>
        <div style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-top:6px;">Căn hộ cho thuê</div>
      </div>
      <div>
        <div style="font-family:var(--serif);font-size:36px;font-weight:700;line-height:1;">98<span style="color:var(--accent);">%</span></div>
        <div style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-top:6px;">Giao dịch thành công</div>
      </div>
      <div>
        <div style="font-family:var(--serif);font-size:36px;font-weight:700;line-height:1;">24<span style="color:var(--accent);">/7</span></div>
        <div style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-top:6px;">Hỗ trợ khách hàng</div>
      </div>
    </div>
  </div>
  <div style="position:relative;overflow:hidden;">
    <img src="https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=900&q=80"
         alt="Luxury apartment" style="width:100%;height:100%;object-fit:cover;">
    <div style="position:absolute;bottom:40px;left:-1px;background:var(--white);padding:20px 28px;border-right:3px solid var(--accent);">
      <div style="font-family:var(--serif);font-size:34px;font-weight:700;line-height:1;">2,400<span style="color:var(--accent);">+</span></div>
      <div style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-top:4px;">Căn hộ đang cho thuê</div>
    </div>
  </div>
</section>

<%-- SEARCH --%>
<div class="search-section">
  <p style="font-size:11px;letter-spacing:3px;text-transform:uppercase;color:var(--accent);margin-bottom:20px;">Tìm kiếm căn hộ</p>
  <div class="search-bar">
    <div class="search-field">
      <label>Khu vực / Từ khóa</label>
      <input type="text" id="hsKw" placeholder="Cầu Giấy, Tây Hồ, Vinhomes...">
    </div>
    <div class="search-field">
      <label>Hình thức thuê</label>
      <select id="hsType">
        <option value="">Tất cả</option>
        <option value="short">Ngắn hạn (&lt;6 tháng)</option>
        <option value="long">Dài hạn (≥6 tháng)</option>
      </select>
    </div>
    <div class="search-field">
      <label>Giá tối đa</label>
      <select id="hsPrice">
        <option value="">Không giới hạn</option>
        <option value="5000000">Dưới 5 triệu</option>
        <option value="10000000">Dưới 10 triệu</option>
        <option value="20000000">Dưới 20 triệu</option>
        <option value="50000000">Dưới 50 triệu</option>
      </select>
    </div>
    <div class="search-field">
      <label>Loại phòng</label>
      <select id="hsRoom">
        <option value="">Tất cả</option>
        <option value="studio">Studio</option>
        <option value="1br">1 Phòng ngủ</option>
        <option value="2br">2 Phòng ngủ</option>
        <option value="3br">3+ Phòng ngủ</option>
      </select>
    </div>
    <button class="search-btn" onclick="goSearch()">Tìm kiếm →</button>
  </div>
</div>

<%-- FEATURED --%>
<section class="section">
  <div class="section-header reveal">
    <div>
      <span class="section-eyebrow">Tuyển chọn đặc biệt</span>
      <h2 class="section-title">Căn hộ <em>nổi bật</em><br>tháng này</h2>
    </div>
    <a href="${pageContext.request.contextPath}/apartments" class="section-link">Xem tất cả →</a>
  </div>

  <c:choose>
    <c:when test="${not empty apartments && apartments.size() >= 3}">
      <div class="featured-grid reveal">
        <div class="featured-main" onclick="location.href='${pageContext.request.contextPath}/apartment/${apartments[0].aptId}'" style="cursor:pointer;">
          <img src="${not empty apartments[0].primaryImage ? apartments[0].primaryImage : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=900'}" alt="${apartments[0].title}">
          <div class="featured-overlay">
            <span class="featured-tag">Nổi bật</span>
            <div class="featured-title">${apartments[0].title}</div>
            <div class="featured-sub">${apartments[0].district}, ${apartments[0].city} · ${apartments[0].area} m²</div>
          </div>
        </div>
        <div class="featured-side">
          <div class="side-card" onclick="location.href='${pageContext.request.contextPath}/apartment/${apartments[1].aptId}'" style="cursor:pointer;">
            <img loading="lazy" src="${not empty apartments[1].primaryImage ? apartments[1].primaryImage : 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=600'}" alt="">
            <div class="side-overlay">
              <div class="side-price"><fmt:formatNumber value="${apartments[1].rentPrice}" pattern="#,###"/> ₫/tháng</div>
              <div class="side-name">${apartments[1].title} · ${apartments[1].district}</div>
            </div>
          </div>
          <div class="side-card" onclick="location.href='${pageContext.request.contextPath}/apartment/${apartments[2].aptId}'" style="cursor:pointer;">
            <img loading="lazy" src="${not empty apartments[2].primaryImage ? apartments[2].primaryImage : 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600'}" alt="">
            <div class="side-overlay">
              <div class="side-price"><fmt:formatNumber value="${apartments[2].rentPrice}" pattern="#,###"/> ₫/tháng</div>
              <div class="side-name">${apartments[2].title} · ${apartments[2].district}</div>
            </div>
          </div>
        </div>
      </div>
    </c:when>
    <c:otherwise>
      <div class="featured-grid reveal">
        <div class="featured-main">
          <img src="https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=900&q=80" alt="">
          <div class="featured-overlay">
            <span class="featured-tag">Sắp ra mắt</span>
            <div class="featured-title">Căn hộ cao cấp đang cập nhật</div>
            <div class="featured-sub">Hà Nội · TP.HCM · Đà Nẵng</div>
          </div>
        </div>
        <div class="featured-side">
          <div class="side-card"><img src="https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=600&q=80" alt=""><div class="side-overlay"><div class="side-price">Xem ngay</div><div class="side-name">Căn hộ mới nhất</div></div></div>
          <div class="side-card"><img src="https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600&q=80" alt=""><div class="side-overlay"><div class="side-price">Xem ngay</div><div class="side-name">Vị trí đắc địa</div></div></div>
        </div>
      </div>
    </c:otherwise>
  </c:choose>
</section>

<%-- LISTINGS GRID --%>
<section class="section" style="padding-top:0;">
  <div class="section-header reveal">
    <div>
      <span class="section-eyebrow">Danh sách căn hộ</span>
      <h2 class="section-title">Khám phá <em>tất cả</em><br>căn hộ của chúng tôi</h2>
    </div>
    <a href="${pageContext.request.contextPath}/apartments" class="section-link">Xem thêm →</a>
  </div>
  <div class="prop-grid">
    <c:forEach var="apt" items="${apartments}">
      <a href="${pageContext.request.contextPath}/apartment/${apt.aptId}" class="prop-card reveal" data-apt-id="${apt.aptId}">
        <div class="prop-img">
          <img loading="lazy" src="${not empty apt.primaryImage ? apt.primaryImage : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600'}"
               alt="${apt.title}">
          <span class="prop-tag ${apt.rentalType=='short'?'short':apt.rentalType=='both'?'both':''}">
            <c:choose>
              <c:when test="${apt.rentalType=='short'}">Ngắn hạn</c:when>
              <c:when test="${apt.rentalType=='long'}">Dài hạn</c:when>
              <c:otherwise>Linh hoạt</c:otherwise>
            </c:choose>
          </span>
          <span class="prop-verified"><i class="fas fa-circle-check"></i> Xác thực</span>
          <button class="prop-fav" onclick="event.preventDefault();">♡</button>
        </div>
        <div class="prop-body">
          <p class="prop-location">${apt.district}, ${apt.city}</p>
          <h3 class="prop-name">${apt.title}</h3>
          <div class="prop-meta">
            <c:choose><c:when test="${apt.bedrooms>0}"><span>🛏 ${apt.bedrooms} PN</span></c:when><c:otherwise><span>🛋 Studio</span></c:otherwise></c:choose>
            <span>🚿 ${apt.bathrooms} WC</span>
            <span>📐 ${apt.area} m²</span>
          </div>
          <div class="prop-footer">
            <div class="prop-price"><fmt:formatNumber value="${apt.rentPrice}" pattern="#,###"/> <small>₫/tháng</small></div>
            <span style="font-size:11px;letter-spacing:1px;text-transform:uppercase;padding:4px 10px;background:#E8F4E8;color:#2A6B2A;">Còn trống</span>
          </div>
        </div>
      </a>
    </c:forEach>
    <c:if test="${empty apartments}">
      <c:forEach begin="1" end="3">
        <div class="prop-card reveal">
          <div class="prop-img"><img src="https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600&q=80" alt="" loading="lazy"><span class="prop-tag">Sắp có</span></div>
          <div class="prop-body"><p class="prop-location">Hà Nội</p><h3 class="prop-name">Đang cập nhật...</h3><div class="prop-footer"><div class="prop-price">— <small>₫/tháng</small></div></div></div>
        </div>
      </c:forEach>
    </c:if>
  </div>
</section>

<%-- STATS --%>
<div style="background:var(--dark);padding:80px;display:grid;grid-template-columns:repeat(4,1fr);gap:0;">
  <div style="padding:48px 40px;border-left:1px solid rgba(255,255,255,.08);" class="reveal">
    <div class="stat-num">2,400<span>+</span></div><div class="stat-label">Căn hộ đang cho thuê</div>
  </div>
  <div style="padding:48px 40px;border-left:1px solid rgba(255,255,255,.08);" class="reveal">
    <div class="stat-num">18,000<span>+</span></div><div class="stat-label">Khách hàng hài lòng</div>
  </div>
  <div style="padding:48px 40px;border-left:1px solid rgba(255,255,255,.08);" class="reveal">
    <div class="stat-num">99<span>%</span></div><div class="stat-label">Hợp đồng thành công</div>
  </div>
  <div style="padding:48px 40px;border-left:1px solid rgba(255,255,255,.08);" class="reveal">
    <div class="stat-num">24<span>/7</span></div><div class="stat-label">Hỗ trợ khách hàng</div>
  </div>
</div>

<%-- HOW IT WORKS --%>
<section class="how-section">
  <div class="section-header reveal">
    <div>
      <span class="section-eyebrow">Đơn giản &amp; minh bạch</span>
      <h2 class="section-title">Thuê nhà chưa bao giờ<br><em>dễ dàng đến thế</em></h2>
    </div>
  </div>
  <div class="steps">
    <div class="step reveal">
      <div class="step-num">01</div>
      <h3 class="step-title">Tìm kiếm &amp; lọc</h3>
      <p class="step-desc">Dùng bộ lọc thông minh để tìm căn hộ phù hợp theo khu vực, ngân sách và tiện nghi mong muốn.</p>
    </div>
    <div class="step reveal" style="transition-delay:.15s">
      <div class="step-num">02</div>
      <h3 class="step-title">Xem và chọn</h3>
      <p class="step-desc">Xem thông tin chi tiết, hình ảnh thực tế. Gửi yêu cầu thuê trực tiếp qua nền tảng.</p>
    </div>
    <div class="step reveal" style="transition-delay:.3s">
      <div class="step-num">03</div>
      <h3 class="step-title">Ký hợp đồng số</h3>
      <p class="step-desc">Điền thông tin, xem xét hợp đồng điện tử và xác nhận các điều khoản minh bạch.</p>
    </div>
    <div class="step reveal" style="transition-delay:.45s">
      <div class="step-num">04</div>
      <h3 class="step-title">Thanh toán &amp; dọn vào</h3>
      <p class="step-desc">Thanh toán an toàn qua Escrow. Tiền cọc được bảo vệ cho đến khi bạn nhận nhà.</p>
    </div>
  </div>
</section>

<%-- CTA --%>
<section style="background:var(--dark);padding:100px 80px;text-align:center;">
  <span class="eyebrow" style="color:rgba(255,255,255,.3);">Bắt đầu ngay hôm nay</span>
  <h2 style="font-family:var(--serif);font-size:clamp(36px,5vw,60px);font-weight:700;color:var(--white);margin:16px 0 20px;line-height:1.1;letter-spacing:-.03em;">
    Căn hộ lý tưởng<br><em style="font-style:italic;color:var(--accent);">đang chờ bạn</em>
  </h2>
  <p style="color:rgba(255,255,255,.45);font-size:15px;max-width:480px;margin:0 auto 40px;line-height:1.8;">
    Đăng ký miễn phí và khám phá hàng nghìn căn hộ được xác thực trên toàn quốc.
  </p>
  <div style="display:flex;gap:16px;justify-content:center;flex-wrap:wrap;">
    <a href="${pageContext.request.contextPath}/apartments" class="btn btn-accent btn-lg">Khám phá ngay →</a>
    <a href="${pageContext.request.contextPath}/register" class="btn btn-outline btn-lg" style="color:var(--white);border-color:rgba(255,255,255,.3);">Tạo tài khoản</a>
  </div>
</section>

<script>
function goSearch() {
  var kw    = document.getElementById('hsKw').value;
  var type  = document.getElementById('hsType').value;
  var price = document.getElementById('hsPrice').value;
  var room  = document.getElementById('hsRoom').value;
  var url = '${pageContext.request.contextPath}/apartments?';
  if(kw)    url += 'keyword='+encodeURIComponent(kw)+'&';
  if(type)  url += 'rentalType='+type+'&';
  if(price) url += 'maxPrice='+price+'&';
  if(room)  url += 'type='+room+'&';
  window.location.href = url;
}
document.getElementById('hsKw').addEventListener('keydown', function(e){ if(e.key==='Enter') goSearch(); });

/* Ghi nhận lịch sử xem gần đây cho từng prop-card */
document.querySelectorAll('.prop-card[data-apt-id]').forEach(function(card){
  card.addEventListener('click', function(){
    var id   = parseInt(card.dataset.aptId);
    var name = card.querySelector('.prop-name')  ? card.querySelector('.prop-name').textContent.trim()  : '';
    var img  = card.querySelector('.prop-img img')? card.querySelector('.prop-img img').src : '';
    var url  = card.href;
    try {
      var hist = JSON.parse(localStorage.getItem('ccvn_recent') || '[]');
      hist = hist.filter(function(x){ return x.id !== id; });
      hist.unshift({id:id, name:name, img:img, url:url});
      if(hist.length > 6) hist = hist.slice(0,6);
      localStorage.setItem('ccvn_recent', JSON.stringify(hist));
    } catch(e){}
  });
});

/* Hiện section "Đã xem gần đây" nếu có data */
(function(){
  var hist = [];
  try { hist = JSON.parse(localStorage.getItem('ccvn_recent') || '[]'); } catch(e){}
  if(hist.length < 2) return;
  var sec = document.getElementById('recentSection');
  if(!sec) return;
  sec.style.display = '';
  var grid = document.getElementById('recentGrid');
  hist.slice(0,4).forEach(function(item){
    var a = document.createElement('a');
    a.href = item.url;
    a.style.cssText = 'display:block;border:1px solid var(--border);background:var(--white);text-decoration:none;transition:transform .2s;';
    a.onmouseenter = function(){ a.style.transform='translateY(-3px)'; };
    a.onmouseleave = function(){ a.style.transform=''; };
    a.innerHTML = '<img src="'+item.img+'" style="width:100%;height:130px;object-fit:cover;" loading="lazy" onerror="this.style.background=\'var(--cream)\'">'
      + '<div style="padding:12px 14px;font-family:var(--serif);font-size:14px;font-weight:600;color:var(--dark);display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;">'+item.name+'</div>';
    grid.appendChild(a);
  });
})();
</script>

<%-- RECENTLY VIEWED — hiện từ localStorage, ẩn mặc định --%>
<section id="recentSection" style="display:none;padding:64px 80px;background:var(--cream);">
  <div style="display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:32px;">
    <div>
      <span class="section-eyebrow">Của bạn</span>
      <h2 class="section-title">Đã xem gần đây</h2>
    </div>
    <button onclick="localStorage.removeItem('ccvn_recent');document.getElementById('recentSection').style.display='none';"
            style="font-size:12px;color:var(--light);background:none;border:none;cursor:pointer;letter-spacing:.5px;text-transform:uppercase;">
      Xóa lịch sử
    </button>
  </div>
  <div id="recentGrid" style="display:grid;grid-template-columns:repeat(4,1fr);gap:2px;background:var(--border);">
  </div>
</section>

<%@ include file="includes/footer.jsp" %>
