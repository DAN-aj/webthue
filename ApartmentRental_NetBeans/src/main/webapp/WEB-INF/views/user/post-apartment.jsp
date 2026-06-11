<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đăng Căn Hộ — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>
<div class="page-strip">
  <div style="padding:60px 80px;">
    <span class="eyebrow">Chủ nhà</span>
    <h1>Đăng tin cho thuê</h1>
    <p style="color:rgba(255,255,255,.45);font-size:14px;line-height:1.75;max-width:500px;">Điền đầy đủ thông tin để thu hút người thuê uy tín. Tin sẽ được duyệt trong 24 giờ.</p>
  </div>
</div>
<div class="container-sm" style="padding-bottom:80px;">
  <c:if test="${not empty error}"><div class="alert alert-error" style="margin-top:24px;"><i class="fas fa-circle-xmark"></i>${error}</div></c:if>

  <form action="${pageContext.request.contextPath}/user/apartment/post" method="post" style="margin-top:36px;">

    <%-- 1. THÔNG TIN CƠ BẢN --%>
    <h2 class="sec-title">Thông tin cơ bản</h2>
    <div class="form-group">
      <label class="form-label req">Tiêu đề tin đăng</label>
      <input type="text" name="title" class="form-control" required placeholder="VD: Studio cao cấp Vinhomes Ocean Park, đầy đủ nội thất" value="${apartment.title}">
    </div>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label req">Loại căn hộ</label>
        <select name="type" class="form-control" required>
          <option value="">Chọn loại</option>
          <option value="studio"    ${apartment.type=='studio'   ?'selected':''}>Studio</option>
          <option value="1br"       ${apartment.type=='1br'      ?'selected':''}>1 Phòng ngủ</option>
          <option value="2br"       ${apartment.type=='2br'      ?'selected':''}>2 Phòng ngủ</option>
          <option value="3br"       ${apartment.type=='3br'      ?'selected':''}>3 Phòng ngủ</option>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label req">Hình thức cho thuê</label>
        <select name="rentalType" class="form-control" required id="rentalTypeSelect" onchange="togglePricing()">
          <option value="both"  ${apartment.rentalType=='both' ?'selected':''}>Cả hai (linh hoạt)</option>
          <option value="long"  ${apartment.rentalType=='long' ?'selected':''}>Dài hạn (≥30 ngày)</option>
          <option value="short" ${apartment.rentalType=='short'?'selected':''}>Ngắn hạn (theo ngày)</option>
        </select>
      </div>
    </div>

    <%-- 2. VỊ TRÍ --%>
    <h2 class="sec-title">Vị trí</h2>
    <div class="form-group">
      <label class="form-label req">Địa chỉ đầy đủ</label>
      <input type="text" name="address" class="form-control" required value="${apartment.address}" placeholder="Số nhà, tên đường, tòa nhà...">
      <p class="form-hint">Địa chỉ đầy đủ chỉ hiển thị sau khi hợp đồng được ký.</p>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label req">Quận / Huyện</label>
        <input type="text" name="district" class="form-control" required value="${apartment.district}" placeholder="VD: Cầu Giấy">
      </div>
      <div class="form-group">
        <label class="form-label req">Thành phố</label>
        <input type="text" name="city" class="form-control" required value="${not empty apartment.city ? apartment.city : 'Hà Nội'}" placeholder="Hà Nội">
      </div>
    </div>

    <%-- 3. CHI TIẾT CĂN HỘ --%>
    <h2 class="sec-title">Chi tiết căn hộ</h2>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label req">Diện tích (m²)</label>
        <input type="number" name="area" class="form-control" required value="${apartment.area}" placeholder="45" step="0.5" min="10">
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
      <div class="form-group">
        <label class="form-label">Tầng số</label>
        <input type="number" name="floor" class="form-control" value="${apartment.floor!=0?apartment.floor:''}" placeholder="12" min="1">
      </div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Tổng số tầng tòa nhà</label>
        <input type="number" name="totalFloors" class="form-control" value="${apartment.totalFloors!=0?apartment.totalFloors:''}" placeholder="25" min="1">
      </div>
      <div class="form-group">
        <label class="form-label">Nội thất</label>
        <select name="furniture" class="form-control">
          <option value="">Chọn tình trạng</option>
          <option value="Full" ${apartment.furniture=='Full'?'selected':''}>Full nội thất</option>
          <option value="Full gỗ" ${apartment.furniture=='Full gỗ'?'selected':''}>Full nội thất gỗ</option>
          <option value="Cơ bản" ${apartment.furniture=='Cơ bản'?'selected':''}>Nội thất cơ bản</option>
          <option value="Nguyên bản" ${apartment.furniture=='Nguyên bản'?'selected':''}>Nguyên bản (không nội thất)</option>
        </select>
      </div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label class="form-label">Hướng ban công</label>
        <select name="direction" class="form-control">
          <option value="">Chọn hướng</option>
          <option value="ĐB" ${apartment.direction=='ĐB'?'selected':''}>Đông Bắc (ĐB)</option>
          <option value="ĐN" ${apartment.direction=='ĐN'?'selected':''}>Đông Nam (ĐN)</option>
          <option value="TN" ${apartment.direction=='TN'?'selected':''}>Tây Nam (TN)</option>
          <option value="TB" ${apartment.direction=='TB'?'selected':''}>Tây Bắc (TB)</option>
          <option value="Đ"  ${apartment.direction=='Đ' ?'selected':''}>Đông (Đ)</option>
          <option value="T"  ${apartment.direction=='T' ?'selected':''}>Tây (T)</option>
          <option value="N"  ${apartment.direction=='N' ?'selected':''}>Nam (N)</option>
          <option value="B"  ${apartment.direction=='B' ?'selected':''}>Bắc (B)</option>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">View nhìn ra</label>
        <select name="view" class="form-control">
          <option value="">Chọn view</option>
          <option value="Nội khu"    ${apartment.view=='Nội khu'   ?'selected':''}>Nội khu</option>
          <option value="Ngoại khu"  ${apartment.view=='Ngoại khu' ?'selected':''}>Ngoại khu</option>
          <option value="Hồ"         ${apartment.view=='Hồ'        ?'selected':''}>View hồ</option>
          <option value="Sông"       ${apartment.view=='Sông'      ?'selected':''}>View sông</option>
          <option value="Công viên"  ${apartment.view=='Công viên' ?'selected':''}>Công viên</option>
          <option value="Thành phố"  ${apartment.view=='Thành phố' ?'selected':''}>Thành phố / City view</option>
        </select>
      </div>
    </div>

    <%-- 4. GIÁ THUÊ --%>
    <h2 class="sec-title">Giá thuê &amp; hợp đồng</h2>
    <div id="priceLong">
      <div class="form-row">
        <div class="form-group">
          <label class="form-label req">Giá thuê dài hạn (₫/tháng)</label>
          <input type="number" name="rentPriceMonth" id="rentPriceMonth" class="form-control"
                 value="${not empty apartment.rentPriceMonth ? apartment.rentPriceMonth : ''}"
                 placeholder="8000000" min="0" onchange="updatePreview()">
          <p class="form-hint" id="previewMonth"></p>
        </div>
        <div class="form-group">
          <label class="form-label">Tiền cọc (số tháng)</label>
          <select name="depositMonths" class="form-control">
            <option value="0" ${apartment.depositMonths==0?'selected':''}>Không cọc</option>
            <option value="1" ${apartment.depositMonths==1?'selected':''}>1 tháng</option>
            <option value="2" ${apartment.depositMonths==2?'selected':''}>2 tháng</option>
            <option value="3" ${apartment.depositMonths==3?'selected':''}>3 tháng</option>
          </select>
        </div>
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
    <div id="priceShort" style="display:none;">
      <div class="form-group">
        <label class="form-label req">Giá thuê ngắn hạn (₫/ngày)</label>
        <input type="number" name="rentPriceDay" id="rentPriceDay" class="form-control"
               value="${not empty apartment.rentPriceDay ? apartment.rentPriceDay : ''}"
               placeholder="350000" min="0" onchange="updatePreviewDay()">
        <p class="form-hint" id="previewDay"></p>
      </div>
      <div class="alert alert-info" style="margin-top:0;"><i class="fas fa-circle-info"></i><span>Thuê ngắn hạn: Không thu tiền cọc. Phí nền tảng 10% tổng tiền.</span></div>
    </div>

    <%-- 5. TIỆN NGHI (lưu dạng text CSV, khớp dữ liệu thực tế) --%>
    <h2 class="sec-title">Tiện nghi</h2>

    <p style="font-size:11px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:12px;">Cơ bản</p>
    <div class="checkbox-grid" style="margin-bottom:20px;">
      <label class="chk-item"><input type="checkbox" name="amenities" value="Wifi"> <i class="fas fa-wifi" style="color:var(--accent);width:16px;"></i> Wifi</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Điều hòa"> <i class="fas fa-snowflake" style="color:var(--accent);width:16px;"></i> Điều hòa</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Máy giặt"> <i class="fas fa-shirt" style="color:var(--accent);width:16px;"></i> Máy giặt</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Tủ lạnh"> <i class="fas fa-temperature-low" style="color:var(--accent);width:16px;"></i> Tủ lạnh</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Tivi"> <i class="fas fa-tv" style="color:var(--accent);width:16px;"></i> Tivi</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Bếp từ"> <i class="fas fa-utensils" style="color:var(--accent);width:16px;"></i> Bếp từ</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Lò vi sóng"> <i class="fas fa-circle-dot" style="color:var(--accent);width:16px;"></i> Lò vi sóng</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Ban công"> <i class="fas fa-sun" style="color:var(--accent);width:16px;"></i> Ban công</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Bàn là"> <i class="fas fa-circle-check" style="color:var(--accent);width:16px;"></i> Bàn là</label>
    </div>

    <p style="font-size:11px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:12px;">Tòa nhà</p>
    <div class="checkbox-grid" style="margin-bottom:20px;">
      <label class="chk-item"><input type="checkbox" name="amenities" value="Thang máy"> <i class="fas fa-elevator" style="color:var(--accent);width:16px;"></i> Thang máy</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Bãi đỗ xe"> <i class="fas fa-square-parking" style="color:var(--accent);width:16px;"></i> Bãi đỗ xe</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Phòng gym"> <i class="fas fa-dumbbell" style="color:var(--accent);width:16px;"></i> Phòng gym</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Hồ bơi"> <i class="fas fa-water-ladder" style="color:var(--accent);width:16px;"></i> Hồ bơi</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Sân chơi"> <i class="fas fa-child" style="color:var(--accent);width:16px;"></i> Sân chơi</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="An ninh 24/7"> <i class="fas fa-shield-halved" style="color:var(--accent);width:16px;"></i> An ninh 24/7</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Camera CCTV"> <i class="fas fa-video" style="color:var(--accent);width:16px;"></i> Camera CCTV</label>
      <label class="chk-item"><input type="checkbox" name="amenities" value="Sân thượng"> <i class="fas fa-building" style="color:var(--accent);width:16px;"></i> Sân thượng</label>
    </div>

    <%-- 6. HÌNH ẢNH --%>
    <h2 class="sec-title">Hình ảnh</h2>
    <div class="form-group">
      <label class="form-label">URL ảnh (mỗi dòng một URL)</label>
      <textarea name="imageUrlsRaw" id="imageUrlsRaw" class="form-control" rows="4"
        placeholder="https://images.unsplash.com/photo-...&#10;https://..."></textarea>
      <p class="form-hint">Ảnh đầu tiên sẽ là ảnh đại diện. Hỗ trợ link ảnh từ Unsplash, Imgur, Cloudinary...</p>
    </div>

    <div class="alert alert-info">
      <i class="fas fa-circle-info"></i>
      <span>Tin đăng sẽ được Admin kiểm duyệt trong <strong>24 giờ</strong> trước khi hiển thị công khai.</span>
    </div>
    <div style="display:flex;gap:12px;margin-top:28px;">
      <button type="submit" class="btn btn-dark btn-lg" onclick="prepareImages()"><i class="fas fa-paper-plane"></i> Đăng tin</button>
      <a href="${pageContext.request.contextPath}/user/profile" class="btn btn-outline btn-lg">Hủy</a>
    </div>
  </form>
</div>

<script>
function togglePricing() {
  var v = document.getElementById('rentalTypeSelect').value;
  document.getElementById('priceLong').style.display  = (v==='short') ? 'none' : 'block';
  document.getElementById('priceShort').style.display = (v==='long')  ? 'none' : 'block';
}
function fmtVND(n) { return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + ' ₫'; }
function updatePreview() {
  var v = parseFloat(document.getElementById('rentPriceMonth').value.replace(/,/g,''));
  document.getElementById('previewMonth').textContent = isNaN(v)?'': '≈ ' + fmtVND(v) + '/tháng';
}
function updatePreviewDay() {
  var v = parseFloat(document.getElementById('rentPriceDay').value.replace(/,/g,''));
  document.getElementById('previewDay').textContent = isNaN(v)?'': '≈ ' + fmtVND(v) + '/ngày · ' + fmtVND(v*30) + '/30 ngày';
}
// Chuyển textarea thành hidden inputs imageUrls[]
function prepareImages() {
  var raw = document.getElementById('imageUrlsRaw').value.trim();
  if (!raw) return;
  var lines = raw.split(/\n/).map(function(l){return l.trim();}).filter(function(l){return l.length>0;});
  var form = document.getElementById('imageUrlsRaw').form;
  lines.forEach(function(url) {
    var inp = document.createElement('input');
    inp.type = 'hidden'; inp.name = 'imageUrls'; inp.value = url;
    form.appendChild(inp);
  });
}
// Restore checked state for amenities (lưu dạng CSV text)
(function(){
  var saved = '${apartment.amenities}';
  if (!saved) return;
  var arr = saved.split(',').map(function(s){return s.trim();});
  document.querySelectorAll('input[name="amenities"]').forEach(function(cb){
    if (arr.indexOf(cb.value) >= 0) cb.checked = true;
  });
  togglePricing();
})();
</script>
<%@ include file="../includes/footer.jsp" %>
