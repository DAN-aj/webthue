<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Chỉnh sửa căn hộ — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>

<div class="page-strip">
  <div style="padding:60px 80px;">
    <span class="eyebrow">Chủ nhà</span>
    <h1>Chỉnh sửa căn hộ</h1>
    <p style="color:rgba(255,255,255,.45);font-size:14px;">${apartment.title}</p>
  </div>
</div>

<div class="container-sm" style="padding-bottom:80px;">
  <div class="alert alert-warn" style="margin-top:24px;">
    ℹ️ Thay đổi sẽ được gửi cho Admin phê duyệt trước khi áp dụng. Thông tin hiện tại vẫn giữ nguyên cho đến khi được duyệt.
  </div>
  <c:if test="${not empty error}">
    <div class="alert alert-error" style="margin-top:12px;">${error}</div>
  </c:if>

  <form action="${pageContext.request.contextPath}/user/apartment/edit/${apartment.aptId}" method="post" style="margin-top:28px;">

    <h2 class="sec-title">Thông tin cơ bản</h2>
    <div class="form-group">
      <label class="form-label req">Tiêu đề tin đăng</label>
      <input type="text" name="title" class="form-control" required value="${apartment.title}">
    </div>

    <h2 class="sec-title">Chi tiết căn hộ</h2>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label req">Diện tích (m²)</label>
        <input type="number" name="area" class="form-control" required value="${apartment.area}" step="0.5" min="10">
      </div>
      <div class="form-group">
        <label class="form-label">Số phòng ngủ</label>
        <select name="bedrooms" class="form-control">
          <option value="0" ${apartment.bedrooms==0?'selected':''}>Studio (0)</option>
          <option value="1" ${apartment.bedrooms==1?'selected':''}>1 phòng ngủ</option>
          <option value="2" ${apartment.bedrooms==2?'selected':''}>2 phòng ngủ</option>
          <option value="3" ${apartment.bedrooms==3?'selected':''}>3 phòng ngủ</option>
          <option value="4" ${apartment.bedrooms==4?'selected':''}>4+ phòng ngủ</option>
        </select>
      </div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Số phòng tắm</label>
        <select name="bathrooms" class="form-control">
          <option value="1" ${apartment.bathrooms==1?'selected':''}>1</option>
          <option value="2" ${apartment.bathrooms==2?'selected':''}>2</option>
          <option value="3" ${apartment.bathrooms==3?'selected':''}>3+</option>
        </select>
      </div>
    </div>

    <h2 class="sec-title">Giá thuê</h2>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Giá dài hạn (₫/tháng)</label>
        <input type="number" name="rentPriceMonth" class="form-control"
               value="${not empty apartment.rentPriceMonth ? apartment.rentPriceMonth : ''}" min="0">
      </div>
      <div class="form-group">
        <label class="form-label">Giá ngắn hạn (₫/ngày)</label>
        <input type="number" name="rentPriceDay" class="form-control"
               value="${not empty apartment.rentPriceDay ? apartment.rentPriceDay : ''}" min="0">
      </div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Tiền cọc (số tháng)</label>
        <select name="depositMonths" class="form-control">
          <option value="0" ${apartment.depositMonths==0?'selected':''}>Không cọc</option>
          <option value="1" ${apartment.depositMonths==1?'selected':''}>1 tháng</option>
          <option value="2" ${apartment.depositMonths==2?'selected':''}>2 tháng</option>
          <option value="3" ${apartment.depositMonths==3?'selected':''}>3 tháng</option>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Kỳ thanh toán</label>
        <select name="paymentPeriod" class="form-control">
          <option value="1" ${apartment.paymentPeriod==1?'selected':''}>1 tháng/lần</option>
          <option value="2" ${apartment.paymentPeriod==2?'selected':''}>2 tháng/lần</option>
          <option value="3" ${apartment.paymentPeriod==3?'selected':''}>3 tháng/lần</option>
          <option value="6" ${apartment.paymentPeriod==6?'selected':''}>6 tháng/lần</option>
        </select>
      </div>
    </div>

    <h2 class="sec-title">Mô tả</h2>
    <div class="form-group">
      <textarea name="description" class="form-control" rows="4">${apartment.description}</textarea>
    </div>

    <h2 class="sec-title">Tiện nghi</h2>
    <p style="font-size:11px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:12px;">Cơ bản</p>
    <div class="checkbox-grid" style="margin-bottom:20px;">
      <label class="chk-item"><input type="checkbox" name="amenities" value="wifi"> <i class="fas fa-wifi" style="color:var(--accent);width:16px;"></i> WiFi</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="air_conditioner"> <i class="fas fa-snowflake" style="color:var(--accent);width:16px;"></i> Điều hòa</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="washing_machine"> <i class="fas fa-shirt" style="color:var(--accent);width:16px;"></i> Máy giặt</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="refrigerator"> <i class="fas fa-temperature-low" style="color:var(--accent);width:16px;"></i> Tủ lạnh</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="tv"> <i class="fas fa-tv" style="color:var(--accent);width:16px;"></i> Tivi</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="kitchen"> <i class="fas fa-utensils" style="color:var(--accent);width:16px;"></i> Bếp đầy đủ</label>
    </div>
    <p style="font-size:11px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:12px;">Tòa nhà</p>
    <div class="checkbox-grid" style="margin-bottom:20px;">
      <label class="chk-item"><input type="checkbox" name="amenities" value="elevator"> <i class="fas fa-elevator" style="color:var(--accent);width:16px;"></i> Thang máy</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="parking"> <i class="fas fa-square-parking" style="color:var(--accent);width:16px;"></i> Bãi đỗ xe</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="gym"> <i class="fas fa-dumbbell" style="color:var(--accent);width:16px;"></i> Phòng gym</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="pool"> <i class="fas fa-water-ladder" style="color:var(--accent);width:16px;"></i> Hồ bơi</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="concierge"> <i class="fas fa-bell-concierge" style="color:var(--accent);width:16px;"></i> Lễ tân</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="garden"> <i class="fas fa-tree" style="color:var(--accent);width:16px;"></i> Sân vườn</label>
    </div>
    <p style="font-size:11px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:12px;">An ninh &amp; Thông minh</p>
    <div class="checkbox-grid" style="margin-bottom:28px;">
      <label class="chk-item"><input type="checkbox" name="amenities" value="security"> <i class="fas fa-shield-halved" style="color:var(--accent);width:16px;"></i> Bảo vệ 24/7</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="cctv"> <i class="fas fa-video" style="color:var(--accent);width:16px;"></i> Camera CCTV</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="smart_lock"> <i class="fas fa-lock" style="color:var(--accent);width:16px;"></i> Khóa thông minh</label>
    </div>

    <div style="display:flex;gap:12px;margin-top:28px;">
      <button type="submit" class="btn btn-dark btn-lg">
        <i class="fas fa-paper-plane"></i> Gửi yêu cầu chỉnh sửa
      </button>
      <a href="${pageContext.request.contextPath}/user/profile" class="btn btn-outline btn-lg">Hủy</a>
    </div>
  </form>
</div>

<script>
// Khôi phục trạng thái checkbox tiện nghi
(function(){
  var saved = '${apartment.amenities}';
  if (!saved) return;
  try {
    var arr = JSON.parse(saved);
    document.querySelectorAll('input[name="amenities"]').forEach(function(cb){
      if (arr.indexOf(cb.value) >= 0) cb.checked = true;
    });
  } catch(e) {}
})();
</script>

<%@ include file="../includes/footer.jsp" %>
