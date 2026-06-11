<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%-- FIX: Guard - dung scriptlet thuan tuy, khong long vao JSTL tag de tranh loi "Unreachable code" --%>
<%
  if (request.getAttribute("apartment") == null) {
    response.sendError(404);
    return;
  }
%>
<c:set var="pageTitle" value="${apartment.title} — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>

<div class="container" style="padding-top:0;padding-bottom:80px;">
  <%-- BREADCRUMB --%>
  <div class="breadcrumb">
    <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
    <i class="fas fa-chevron-right"></i>
    <a href="${pageContext.request.contextPath}/apartments">Căn hộ</a>
    <i class="fas fa-chevron-right"></i>
    <span>${apartment.district}, ${apartment.city}</span>
  </div>

  <c:if test="${param.error=='self'}">
    <div class="alert alert-warn"><i class="fas fa-triangle-exclamation"></i>Bạn không thể tự thuê căn hộ của mình.</div>
  </c:if>

  <div class="detail-layout">
    <%-- LEFT: Gallery + Info --%>
    <div>
      <%-- Gallery --%>
      <div class="gal-main">
        <img id="galMain" src="${not empty apartment.images ? apartment.images[0] : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=900'}" alt="${apartment.title}">
        <span class="gal-count"><i class="fas fa-images"></i> ${not empty apartment.images ? apartment.images.size() : 1} ảnh</span>
      </div>
      <c:if test="${not empty apartment.images && apartment.images.size()>1}">
        <div class="gal-thumbs">
          <c:forEach var="img" items="${apartment.images}" varStatus="s">
            <img loading="lazy" src="${img}" alt="" class="${s.first?'on':''}" data-full="${img}">
          </c:forEach>
        </div>
      </c:if>

      <%-- Badges + Title --%>
      <div style="margin-top:28px;">
        <div style="display:flex;flex-wrap:wrap;gap:8px;margin-bottom:14px;align-items:center;">
          <span class="badge badge-dark">${apartment.typeLabel}</span>
          <c:choose>
            <c:when test="${apartment.rentalType=='short'}"><span class="badge badge-amber">Ngắn hạn</span></c:when>
            <c:when test="${apartment.rentalType=='long'}"> <span class="badge badge-green">Dài hạn</span></c:when>
            <c:otherwise><span class="badge badge-green">Ngắn hạn</span><span class="badge badge-amber">Dài hạn</span></c:otherwise>
          </c:choose>
          <span class="badge badge-green"><i class="fas fa-circle-check"></i> Xác thực</span>
          <button class="prop-fav" data-apt-id="${apartment.aptId}"
                  style="margin-left:auto;background:var(--cream);border:1px solid var(--border);width:38px;height:38px;display:flex;align-items:center;justify-content:center;font-size:18px;cursor:pointer;"
                  title="Thêm vào yêu thích">♡</button>
        </div>
        <h1 class="apt-headline">${apartment.title}</h1>
        <div style="display:flex;flex-wrap:wrap;gap:16px;color:var(--light);font-size:12px;text-transform:uppercase;letter-spacing:1.5px;margin-bottom:28px;">
          <span><i class="fas fa-location-dot" style="color:var(--accent);margin-right:4px;"></i>${apartment.district}, ${apartment.city}</span>
          <span><i class="fas fa-expand" style="margin-right:4px;"></i>${apartment.area} m²</span>
          <c:if test="${apartment.bedrooms>0}"><span><i class="fas fa-bed" style="margin-right:4px;"></i>${apartment.bedrooms} PN</span></c:if>
          <span><i class="fas fa-bath" style="margin-right:4px;"></i>${apartment.bathrooms} WC</span>
          <span><i class="fas fa-layer-group" style="margin-right:4px;"></i>Tầng ${apartment.floor}/${apartment.totalFloors}</span>
          <span><i class="fas fa-eye" style="margin-right:4px;"></i>${apartment.viewCount} lượt xem</span>
        </div>

        <%-- Thông số --%>
        <div class="apt-specs">
          <div style="text-align:center;"><div class="spec-num">${apartment.bedrooms>0?apartment.bedrooms:'Studio'}</div><div class="spec-label">Phòng ngủ</div></div>
          <div style="text-align:center;"><div class="spec-num">${apartment.bathrooms}</div><div class="spec-label">Phòng tắm</div></div>
          <div style="text-align:center;"><div class="spec-num">${apartment.area}</div><div class="spec-label">Diện tích m²</div></div>
        </div>

        <%-- Địa chỉ (ẩn nếu chưa có hợp đồng) --%>
        <c:choose>
          <c:when test="${hasActiveContract}">
            <div class="alert alert-success" style="margin-bottom:24px;"><i class="fas fa-map-location-dot"></i><div><strong>Địa chỉ đầy đủ:</strong> ${apartment.address}</div></div>
          </c:when>
          <c:otherwise>
            <div class="addr-hidden"><i class="fas fa-lock"></i><span>Địa chỉ chi tiết hiển thị sau khi hợp đồng xác nhận. Hiện tại: <strong>${apartment.district}, ${apartment.city}</strong></span></div>
          </c:otherwise>
        </c:choose>

        <%-- Thông tin bổ sung: nội thất, hướng, view --%>
        <c:if test="${not empty apartment.furniture or not empty apartment.direction or not empty apartment.view}">
          <h2 class="sec-title">Đặc điểm căn hộ</h2>
          <div style="display:flex;flex-wrap:wrap;gap:12px;margin-bottom:28px;">
            <c:if test="${not empty apartment.furniture}">
              <div style="display:flex;align-items:center;gap:8px;padding:10px 16px;background:var(--cream);border:1px solid var(--border);font-size:13px;">
                <i class="fas fa-couch" style="color:var(--accent);"></i>
                <span><strong>Nội thất:</strong> ${apartment.furniture}</span>
              </div>
            </c:if>
            <c:if test="${not empty apartment.direction}">
              <div style="display:flex;align-items:center;gap:8px;padding:10px 16px;background:var(--cream);border:1px solid var(--border);font-size:13px;">
                <i class="fas fa-compass" style="color:var(--accent);"></i>
                <span><strong>Hướng:</strong> ${apartment.direction}</span>
              </div>
            </c:if>
            <c:if test="${not empty apartment.view}">
              <div style="display:flex;align-items:center;gap:8px;padding:10px 16px;background:var(--cream);border:1px solid var(--border);font-size:13px;">
                <i class="fas fa-binoculars" style="color:var(--accent);"></i>
                <span><strong>View:</strong> ${apartment.view}</span>
              </div>
            </c:if>
          </div>
        </c:if>

        <%-- Tiện nghi — text CSV từ DB --%>
        <c:set var="amenList" value="${apartment.amenitiesList}"/>
        <c:if test="${not empty amenList}">
          <h2 class="sec-title">Tiện nghi</h2>
          <div class="amenity-grid">
            <c:forEach var="item" items="${amenList}">
              <div class="amenity-item">
                <i class="fas fa-circle-check" style="color:var(--accent);font-size:14px;width:18px;text-align:center;"></i>
                ${item}
              </div>
            </c:forEach>
          </div>
        </c:if>

        <%-- Thông tin chủ nhà --%>
        <h2 class="sec-title" style="margin-top:32px;">Chủ nhà</h2>
        <div style="display:flex;align-items:center;gap:16px;padding:20px;background:var(--cream);border:1px solid var(--border);">
          <div class="owner-ava">${apartment.firstLetter}</div>
          <div style="flex:1;">
            <div class="owner-name">${apartment.ownerName}</div>
            <c:choose>
              <c:when test="${hasActiveContract}">
                <div class="owner-meta-txt"><i class="fas fa-phone" style="color:var(--accent);margin-right:4px;"></i>${apartment.ownerPhone}</div>
              </c:when>
              <c:otherwise>
                <div class="owner-meta-txt" style="font-style:italic;color:var(--light);"><i class="fas fa-lock" style="color:var(--accent);margin-right:4px;"></i>SĐT hiển thị sau khi ký hợp đồng</div>
              </c:otherwise>
            </c:choose>
            <div style="font-size:11px;color:var(--success);font-weight:600;margin-top:4px;letter-spacing:.5px;text-transform:uppercase;"><i class="fas fa-circle-check" style="margin-right:4px;"></i>Đã xác thực eKYC</div>
          </div>
        </div>
        <div class="sec-tip" style="margin-top:16px;">
          <i class="fas fa-shield-halved"></i>
          <span><strong>Giao dịch an toàn:</strong> Thực hiện toàn bộ qua ChungCư.vn. Không chuyển tiền ngoài nền tảng.</span>
        </div>
      </div>
    </div>

    <%-- RIGHT: Sidebar giá + nút thuê --%>
    <div class="detail-sidebar">
      <div class="price-card">
        <%-- Hiển thị song song giá ngày và giá tháng --%>
        <c:choose>
          <c:when test="${apartment.rentalType=='short'}">
            <div class="price-main">
              <c:if test="${not empty apartment.rentPriceDay}">
                <fmt:formatNumber value="${apartment.rentPriceDay}" pattern="#,###"/> <small>₫/ngày</small>
              </c:if>
            </div>
            <div class="price-deposit" style="color:var(--success);border-top:none;padding-top:8px;font-size:13px;"><i class="fas fa-circle-check" style="margin-right:4px;"></i>Không cần đặt cọc</div>
          </c:when>
          <c:when test="${apartment.rentalType=='long'}">
            <div class="price-main"><fmt:formatNumber value="${apartment.rentPriceMonth}" pattern="#,###"/> <small>₫/tháng</small></div>
            <div class="price-deposit">Tiền cọc: ${apartment.depositMonths} tháng (<fmt:formatNumber value="${apartment.depositTotal}" pattern="#,###"/> ₫)</div>
          </c:when>
          <c:otherwise>
            <%-- BOTH: hiển thị 2 dòng giá --%>
            <div style="padding:12px 0;border-bottom:1px solid var(--border);margin-bottom:12px;">
              <div style="font-size:10px;letter-spacing:2px;text-transform:uppercase;color:var(--accent);margin-bottom:6px;">Dài hạn (≥30 ngày)</div>
              <div class="price-main" style="font-size:28px;"><fmt:formatNumber value="${apartment.rentPriceMonth}" pattern="#,###"/> <small>₫/tháng</small></div>
              <div style="font-size:12px;color:var(--light);margin-top:4px;">Cọc ${apartment.depositMonths} tháng · <fmt:formatNumber value="${apartment.depositTotal}" pattern="#,###"/>₫</div>
            </div>
            <c:if test="${not empty apartment.rentPriceDay}">
              <div style="padding:12px 0;border-bottom:1px solid var(--border);margin-bottom:16px;">
                <div style="font-size:10px;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:6px;">Ngắn hạn (theo ngày)</div>
                <div style="font-family:var(--serif);font-size:22px;font-weight:700;"><fmt:formatNumber value="${apartment.rentPriceDay}" pattern="#,###"/> <small style="font-family:var(--sans);font-size:13px;font-weight:400;color:var(--light);">₫/ngày</small></div>
                <div style="font-size:12px;color:var(--success);margin-top:4px;"><i class="fas fa-circle-check" style="margin-right:3px;"></i>Không cần đặt cọc</div>
              </div>
            </c:if>
          </c:otherwise>
        </c:choose>

        <%-- Thông tin thêm --%>
        <div style="border-top:1px solid var(--border);padding:12px 0;margin-bottom:16px;">
          <div class="ps-row" style="padding:7px 0;border-bottom:1px solid var(--border);font-size:12px;"><span style="color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Loại căn hộ</span><span style="font-weight:600;color:var(--dark);">${apartment.typeLabel}</span></div>
          <div class="ps-row" style="padding:7px 0;border-bottom:1px solid var(--border);font-size:12px;"><span style="color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Thuê tối thiểu</span><span style="font-weight:600;color:var(--dark);">${apartment.minRentalMonths} tháng</span></div>
          <div class="ps-row" style="padding:7px 0;font-size:12px;"><span style="color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Kỳ thanh toán</span><span style="font-weight:600;color:var(--dark);">${apartment.paymentPeriod} tháng/lần</span></div>
        </div>

        <%-- Nút hành động --%>
        <%-- DEBUG: apt.ownerId=${apartment.ownerId} | user.userId=${sessionScope.loggedUser.userId} --%>
        <c:choose>
          <c:when test="${apartment.status=='approved'}">
            <c:choose>
              <c:when test="${sessionScope.loggedUser==null}">
                <a href="${pageContext.request.contextPath}/login?redirect=/user/contract/rent/${apartment.aptId}" class="btn btn-dark btn-block btn-lg" style="margin-bottom:10px;"><i class="fas fa-right-to-bracket"></i> Đăng nhập để thuê</a>
              </c:when>
              <c:when test="${sessionScope.loggedUser.userId==apartment.ownerId}">
                <div class="alert alert-info" style="text-align:center;margin:0;"><i class="fas fa-home"></i> Đây là căn hộ của bạn</div>
              </c:when>
              <c:otherwise>
                <a href="${pageContext.request.contextPath}/user/contract/rent/${apartment.aptId}" class="btn btn-dark btn-block btn-lg" style="margin-bottom:10px;"><i class="fas fa-key"></i> Thuê căn hộ này →</a>
                <button class="chat-btn" onclick="openChatModal(${apartment.aptId})"><i class="fas fa-comment-dots"></i> Hỏi chủ nhà</button>
              </c:otherwise>
            </c:choose>
          </c:when>
          <c:otherwise>
            <div class="alert alert-warn" style="text-align:center;margin:0;"><i class="fas fa-clock"></i> Hiện đang có người thuê</div>
          </c:otherwise>
        </c:choose>

        <div class="escrow-bar" style="margin-top:12px;margin-bottom:0;">
          <i class="fas fa-shield-halved"></i>
          <div><strong>Bảo vệ bởi Escrow</strong>Tiền cọc giữ an toàn, hoàn trả nếu có tranh chấp.</div>
        </div>
      </div>
    </div>
  </div>
</div>

<%-- ══════ ĐÁNH GIÁ & NHẬN XÉT ══════ --%>
<div class="container" style="max-width:860px;padding-bottom:80px;">

  <%-- Tiêu đề + điểm trung bình --%>
  <div style="display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:28px;flex-wrap:wrap;gap:12px;">
    <h2 class="sec-title" style="margin-bottom:0;flex:1;">Đánh giá từ người thuê</h2>
    <c:if test="${reviewCount > 0}">
      <div style="display:flex;align-items:center;gap:10px;flex-shrink:0;">
        <span style="font-family:var(--serif);font-size:32px;font-weight:700;color:var(--dark);">
          <fmt:formatNumber value="${avgRating}" pattern="#.#"/>
        </span>
        <div>
          <div style="color:var(--accent);font-size:16px;letter-spacing:2px;">
            <c:forEach begin="1" end="5" var="s">
              <c:choose>
                <c:when test="${s <= avgRating}">★</c:when>
                <c:otherwise><span style="color:var(--border);">★</span></c:otherwise>
              </c:choose>
            </c:forEach>
          </div>
          <div style="font-size:11px;color:var(--light);margin-top:3px;text-transform:uppercase;letter-spacing:1px;">${reviewCount} đánh giá</div>
        </div>
      </div>
    </c:if>
  </div>

  <%-- Danh sách review từ DB --%>
  <div id="reviewList">
    <c:choose>
      <c:when test="${empty reviews}">
        <div class="empty" style="padding:48px 24px;">
          <i class="fas fa-star" style="font-size:32px;opacity:.15;margin-bottom:14px;display:block;"></i>
          <h3 style="font-size:18px;">Chưa có đánh giá nào</h3>
          <p>Hãy là người đầu tiên đánh giá căn hộ này sau khi thuê.</p>
        </div>
      </c:when>
      <c:otherwise>
        <c:forEach var="rv" items="${reviews}">
          <div class="review-card" style="padding:24px;margin-bottom:2px;border:1px solid var(--border);">
            <div style="display:flex;align-items:center;gap:12px;margin-bottom:12px;">
              <div style="width:38px;height:38px;border-radius:50%;background:var(--dark);color:var(--accent);display:flex;align-items:center;justify-content:center;font-family:var(--serif);font-weight:700;font-size:15px;flex-shrink:0;">
                ${rv.reviewerFirstLetter}
              </div>
              <div>
                <div style="font-weight:600;font-size:14px;">${rv.reviewerName}</div>
                <div style="font-size:11px;color:var(--light);margin-top:2px;">
                  Đã thuê ·
                  <fmt:formatDate value="${rv.createdAt}" pattern="MM/yyyy"/>
                </div>
              </div>
              <div style="margin-left:auto;color:var(--accent);font-size:14px;letter-spacing:1px;">${rv.stars}</div>
            </div>
            <p style="font-size:14px;line-height:1.8;color:var(--mid);">${rv.comment}</p>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </div>

  <%-- ── Review form ── --%>
  <div style="margin-top:36px;">
    <c:choose>

      <%-- Chưa đăng nhập --%>
      <c:when test="${sessionScope.loggedUser == null}">
        <div class="alert alert-info">
          <i class="fas fa-circle-info"></i>
          <span>
            <a href="${pageContext.request.contextPath}/login?redirect=/apartment/${apartment.aptId}"
               style="color:var(--dark);font-weight:600;border-bottom:1px solid var(--border);">Đăng nhập</a>
            để viết đánh giá về căn hộ này.
          </span>
        </div>
      </c:when>

      <%-- Chủ nhà không thể tự review --%>
      <c:when test="${sessionScope.loggedUser.userId == apartment.ownerId}">
        <div class="alert alert-info">
          <i class="fas fa-home"></i>
          <span>Đây là căn hộ của bạn — chủ nhà không thể tự đánh giá.</span>
        </div>
      </c:when>

      <%-- Đã review rồi --%>
      <c:when test="${alreadyReviewed}">
        <div class="alert alert-success">
          <i class="fas fa-circle-check"></i>
          <span>Bạn đã gửi đánh giá cho căn hộ này. Cảm ơn bạn đã chia sẻ!</span>
        </div>
      </c:when>

      <%-- Chưa từng thuê căn hộ này --%>
      <c:when test="${!canReview}">
        <div class="alert alert-warn">
          <i class="fas fa-triangle-exclamation"></i>
          <div>
            <strong>Chỉ người đã thuê mới được đánh giá.</strong><br>
            <span style="font-size:13px;">Bạn cần có hợp đồng thuê căn hộ này (đang hoạt động hoặc đã kết thúc) mới có thể viết đánh giá.</span>
          </div>
        </div>
      </c:when>

      <%-- Đủ điều kiện — hiện form --%>
      <c:otherwise>
        <div style="background:var(--cream);border:1px solid var(--border);padding:32px;">
          <h3 style="font-family:var(--serif);font-size:20px;font-weight:700;margin-bottom:6px;">Viết đánh giá của bạn</h3>
          <p style="font-size:13px;color:var(--light);margin-bottom:24px;">
            <i class="fas fa-circle-check" style="color:var(--success);margin-right:4px;"></i>
            Bạn đã từng thuê căn hộ này — chia sẻ trải nghiệm để giúp người khác.
          </p>

          <form id="reviewForm"
                action="${pageContext.request.contextPath}/review/${apartment.aptId}"
                method="post">
            <input type="hidden" id="ratingInput" name="rating" value="5">

            <%-- Star rating --%>
            <div style="margin-bottom:20px;">
              <label style="display:block;font-size:11px;font-weight:500;letter-spacing:2px;text-transform:uppercase;color:var(--mid);margin-bottom:10px;">
                Điểm đánh giá <span style="color:#C84E4E;">*</span>
              </label>
              <div style="display:flex;gap:4px;" id="starRow">
                <c:forEach begin="1" end="5" var="si">
                  <button type="button" class="star-btn" data-val="${si}"
                          style="background:none;border:none;font-size:32px;cursor:pointer;color:var(--accent);padding:0 2px;line-height:1;transition:transform .15s;outline:none;"
                          aria-label="${si} sao">★</button>
                </c:forEach>
              </div>
              <div id="ratingLabel" style="font-size:12px;color:var(--light);margin-top:6px;">Tuyệt vời</div>
            </div>

            <%-- Comment --%>
            <div style="margin-bottom:20px;">
              <label style="display:block;font-size:11px;font-weight:500;letter-spacing:2px;text-transform:uppercase;color:var(--mid);margin-bottom:8px;">
                Nhận xét <span style="color:#C84E4E;">*</span>
              </label>
              <textarea name="comment" id="reviewComment" class="form-control" rows="5"
                        placeholder="Chia sẻ thực tế trải nghiệm của bạn: tình trạng căn hộ, thái độ chủ nhà, khu vực xung quanh..."
                        style="resize:vertical;" minlength="10" required></textarea>
              <div style="font-size:11px;color:var(--light);margin-top:5px;" id="charCount">0 / tối thiểu 10 ký tự</div>
            </div>

            <%-- Submit --%>
            <div style="display:flex;align-items:center;gap:16px;flex-wrap:wrap;">
              <button type="submit" class="btn btn-dark" id="reviewSubmitBtn">
                <i class="fas fa-paper-plane"></i> Gửi đánh giá
              </button>
            </div>

            <%-- Thông báo lỗi/thành công inline --%>
            <div id="reviewMsg" style="display:none;margin-top:16px;"></div>
          </form>
        </div>
      </c:otherwise>
    </c:choose>
  </div>

</div>

<script>
/* ── Star rating interactive ── */
(function(){
  var stars  = document.querySelectorAll('.star-btn');
  var inp    = document.getElementById('ratingInput');
  var label  = document.getElementById('ratingLabel');
  var labels = ['','Tệ','Không tốt','Bình thường','Tốt','Tuyệt vời'];
  var cur    = 5;

  function paint(val){
    stars.forEach(function(s){
      s.style.color = parseInt(s.dataset.val) <= val ? 'var(--accent)' : 'var(--border)';
    });
    if(label) label.textContent = labels[val] || '';
  }
  paint(cur);

  stars.forEach(function(s){
    s.addEventListener('mouseenter', function(){ paint(parseInt(s.dataset.val)); });
    s.addEventListener('mouseleave', function(){ paint(cur); });
    s.addEventListener('click', function(){
      cur = parseInt(s.dataset.val);
      if(inp) inp.value = cur;
      paint(cur);
    });
  });

  /* Char count */
  var ta = document.getElementById('reviewComment');
  var cc = document.getElementById('charCount');
  if(ta && cc){
    ta.addEventListener('input', function(){
      var n = ta.value.length;
      cc.textContent = n + ' / tối thiểu 10 ký tự';
      cc.style.color = n >= 10 ? 'var(--success)' : 'var(--light)';
      /* Ẩn thông báo lỗi cũ khi user bắt đầu chỉnh sửa */
      var msg = document.getElementById('reviewMsg');
      if(msg) msg.style.display = 'none';
    });
  }
})();

/* ── AJAX submit ── */
(function(){
  var form = document.getElementById('reviewForm');
  if(!form) return;

  form.addEventListener('submit', function(e){
    e.preventDefault();
    var btn = document.getElementById('reviewSubmitBtn');
    var msg = document.getElementById('reviewMsg');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-clock"></i> Đang gửi...';
    msg.style.display = 'none';

    fetch(form.action, {
      method: 'POST',
      body: new URLSearchParams(new FormData(form)).toString(),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(function(r){ return r.json(); })
    .then(function(res){
      if(res.ok){
        /* Thêm card vào đầu danh sách */
        var list = document.getElementById('reviewList');
        var empty = list.querySelector('.empty');
        if(empty) empty.remove();
        list.insertAdjacentHTML('afterbegin', res.html);

        /* Ẩn form, hiện thông báo */
        form.closest('div[style]').innerHTML =
          '<div class="alert alert-success"><i class="fas fa-circle-check"></i>' +
          '<span>Cảm ơn bạn đã đánh giá!</span></div>';
      } else {
        msg.style.display = 'flex';
        msg.className = 'alert alert-warn';
        msg.innerHTML = '<i class="fas fa-triangle-exclamation"></i><span>' + (res.msg || 'Có lỗi xảy ra.') + '</span>';
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-paper-plane"></i> Gửi đánh giá';
      }
    })
    .catch(function(){
      msg.style.display = 'flex';
      msg.className = 'alert alert-error';
      msg.innerHTML = '<i class="fas fa-circle-xmark"></i><span>Không thể kết nối, vui lòng thử lại.</span>';
      btn.disabled = false;
      btn.innerHTML = '<i class="fas fa-paper-plane"></i> Gửi đánh giá';
    });
  });
})();
</script>

<%-- ══════ CHAT MODAL ══════ --%>
<div id="chatModal" style="display:none;position:fixed;inset:0;z-index:9999;background:rgba(0,0,0,.45);align-items:center;justify-content:center;">
  <div style="background:#fff;width:100%;max-width:460px;margin:16px;padding:32px;position:relative;box-shadow:0 8px 40px rgba(0,0,0,.18);">
    <button onclick="closeChatModal()" style="position:absolute;top:14px;right:16px;background:none;border:none;font-size:22px;cursor:pointer;color:#888;line-height:1;">×</button>
    <h3 style="font-family:var(--serif);font-size:20px;font-weight:700;margin-bottom:6px;">Hỏi chủ nhà</h3>
    <p style="font-size:13px;color:var(--light);margin-bottom:20px;">Chủ nhà sẽ nhận được thông báo ngay sau khi bạn gửi.</p>

    <textarea id="chatMessage" rows="5" class="form-control"
              placeholder="Nhập câu hỏi của bạn (tối đa 500 ký tự)..."
              maxlength="500" style="resize:vertical;margin-bottom:10px;"></textarea>
    <div style="font-size:11px;color:var(--light);margin-bottom:16px;" id="chatCharCount">0 / 500 ký tự</div>

    <div id="chatMsg" style="display:none;margin-bottom:14px;"></div>

    <div style="display:flex;gap:10px;justify-content:flex-end;">
      <button onclick="closeChatModal()" style="padding:10px 20px;border:1px solid var(--border);background:var(--cream);cursor:pointer;font-size:13px;">Huỷ</button>
      <button id="chatSendBtn" onclick="sendChat()" class="btn btn-dark" style="padding:10px 24px;font-size:13px;">
        <i class="fas fa-paper-plane"></i> Gửi tin nhắn
      </button>
    </div>
  </div>
</div>

<script>
var _chatAptId = 0;

function openChatModal(aptId) {
  _chatAptId = aptId;
  document.getElementById('chatMessage').value = '';
  document.getElementById('chatCharCount').textContent = '0 / 500 ký tự';
  var msg = document.getElementById('chatMsg');
  msg.style.display = 'none';
  var btn = document.getElementById('chatSendBtn');
  btn.disabled = false;
  btn.innerHTML = '<i class="fas fa-paper-plane"></i> Gửi tin nhắn';
  var modal = document.getElementById('chatModal');
  modal.style.display = 'flex';
  document.body.style.overflow = 'hidden';
  setTimeout(function(){ document.getElementById('chatMessage').focus(); }, 80);
}

function closeChatModal() {
  document.getElementById('chatModal').style.display = 'none';
  document.body.style.overflow = '';
}

/* Đóng khi click backdrop */
document.getElementById('chatModal').addEventListener('click', function(e){
  if (e.target === this) closeChatModal();
});

/* Char count */
document.getElementById('chatMessage').addEventListener('input', function(){
  document.getElementById('chatCharCount').textContent = this.value.length + ' / 500 ký tự';
});

function sendChat() {
  var message = document.getElementById('chatMessage').value.trim();
  var msg     = document.getElementById('chatMsg');
  var btn     = document.getElementById('chatSendBtn');

  if (!message) {
    msg.style.display = 'flex';
    msg.className = 'alert alert-warn';
    msg.innerHTML = '<i class="fas fa-triangle-exclamation"></i><span>Vui lòng nhập nội dung tin nhắn.</span>';
    return;
  }

  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-clock"></i> Đang gửi...';
  msg.style.display = 'none';

  fetch('${pageContext.request.contextPath}/api/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: 'aptId=' + _chatAptId + '&message=' + encodeURIComponent(message)
  })
  .then(function(r){ return r.json(); })
  .then(function(res){
    if (res.ok) {
      msg.style.display = 'flex';
      msg.className = 'alert alert-success';
      msg.innerHTML = '<i class="fas fa-circle-check"></i><span>Tin nhắn đã gửi! Chủ nhà sẽ liên hệ lại với bạn sớm.</span>';
      btn.innerHTML = '<i class="fas fa-circle-check"></i> Đã gửi';
      document.getElementById('chatMessage').value = '';
      setTimeout(closeChatModal, 2200);
    } else {
      msg.style.display = 'flex';
      msg.className = 'alert alert-warn';
      msg.innerHTML = '<i class="fas fa-triangle-exclamation"></i><span>' + (res.error || 'Có lỗi xảy ra.') + '</span>';
      btn.disabled = false;
      btn.innerHTML = '<i class="fas fa-paper-plane"></i> Gửi tin nhắn';
    }
  })
  .catch(function(){
    msg.style.display = 'flex';
    msg.className = 'alert alert-error';
    msg.innerHTML = '<i class="fas fa-circle-xmark"></i><span>Không thể kết nối, vui lòng thử lại.</span>';
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-paper-plane"></i> Gửi tin nhắn';
  });
}
</script>

<%@ include file="../includes/footer.jsp" %>
