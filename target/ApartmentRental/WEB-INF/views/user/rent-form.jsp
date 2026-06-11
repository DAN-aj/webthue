<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Gửi Yêu Cầu Thuê — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>

<div class="page-strip">
  <div style="padding:60px 80px;">
    <span class="eyebrow">Đăng ký thuê</span>
    <h1>Yêu cầu thuê căn hộ</h1>
    <p style="color:rgba(255,255,255,.45);font-size:14px;">${apartment.title}</p>
  </div>
</div>

<div class="container-sm" style="padding-bottom:80px;">
  <c:if test="${not empty error}">
    <div class="alert alert-error" style="margin-top:24px;"><i class="fas fa-circle-xmark"></i>${error}</div>
  </c:if>

  <%-- Thẻ thông tin căn hộ --%>
  <div style="display:flex;gap:18px;background:var(--cream);border:1px solid var(--border);padding:20px;margin-top:36px;margin-bottom:36px;">
    <img src="${not empty apartment.images ? apartment.images[0] : 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=200'}"
         alt="" style="width:120px;height:80px;object-fit:cover;flex-shrink:0;">
    <div>
      <div style="font-family:var(--serif);font-size:19px;font-weight:700;margin-bottom:4px;">${apartment.title}</div>
      <div style="font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:10px;">${apartment.district}, ${apartment.city}</div>
      <div style="display:flex;gap:20px;flex-wrap:wrap;">
        <c:if test="${not empty apartment.rentPriceMonth}">
          <div>
            <div style="font-size:10px;letter-spacing:1.5px;text-transform:uppercase;color:var(--accent);margin-bottom:2px;">Dài hạn</div>
            <div style="font-family:var(--serif);font-size:18px;font-weight:700;">
              <fmt:formatNumber value="${apartment.rentPriceMonth}" pattern="#,###"/> <span style="font-size:12px;color:var(--light);font-weight:400;">₫/tháng</span>
            </div>
          </div>
        </c:if>
        <c:if test="${not empty apartment.rentPriceDay}">
          <div>
            <div style="font-size:10px;letter-spacing:1.5px;text-transform:uppercase;color:var(--light);margin-bottom:2px;">Ngắn hạn</div>
            <div style="font-family:var(--serif);font-size:18px;font-weight:700;">
              <fmt:formatNumber value="${apartment.rentPriceDay}" pattern="#,###"/> <span style="font-size:12px;color:var(--light);font-weight:400;">₫/ngày</span>
            </div>
          </div>
        </c:if>
      </div>
    </div>
  </div>

  <form action="${pageContext.request.contextPath}/user/contract/rent/${apartment.aptId}" method="post" id="rentForm">
    <h2 class="sec-title">Thông tin hợp đồng</h2>

    <div class="form-row">
      <div class="form-group">
        <label class="form-label req">Số CCCD / CMND</label>
        <input type="text" name="cccd" class="form-control" placeholder="012345678901"
               value="${sessionScope.loggedUser.cccd}" required>
      </div>
      <%-- Loại thuê ẩn — được tự động xác định từ số ngày --%>
      <input type="hidden" name="rentalType" id="rentalType" value="short">
    </div>

    <div class="form-row">
      <div class="form-group">
        <label class="form-label req">Ngày bắt đầu thuê</label>
        <input type="date" name="startDate" id="startDate" class="form-control" required onchange="recalc()">
      </div>
      <div class="form-group">
        <label class="form-label req">Ngày kết thúc</label>
        <input type="date" name="endDate" id="endDate" class="form-control" required onchange="recalc()">
      </div>
    </div>

    <%-- Thông tin loại thuê tự động --%>
    <div id="typeInfo" style="display:none;padding:12px 16px;border-left:4px solid var(--dark);margin-bottom:20px;font-size:14px;font-weight:500;background:var(--cream);border:1px solid var(--border);border-left:4px solid var(--dark);"></div>

    <div class="form-group">
      <label class="form-label">Ghi chú thêm</label>
      <textarea name="notes" class="form-control" rows="3" placeholder="Yêu cầu đặc biệt, thời gian liên hệ..."></textarea>
    </div>

    <%-- Tóm tắt chi phí --%>
    <div style="background:var(--cream);border:1px solid var(--border);padding:24px;margin-bottom:24px;">
      <h2 class="sec-title" style="margin-bottom:20px;">Tóm tắt chi phí</h2>

      <%-- Ngắn hạn: giá ngày × số ngày (KHÔNG hiện phí nền tảng) --%>
      <div id="costShort">
        <div class="ps-row">
          <span>Giá thuê / ngày</span>
          <span id="s_priceDay" style="font-weight:600;">—</span>
        </div>
        <div class="ps-row">
          <span>Số ngày thuê</span>
          <span id="s_days" style="font-weight:600;">—</span>
        </div>
        <div class="ps-row ps-total">
          <span>Tổng thanh toán</span>
          <span id="s_total" style="color:var(--accent);font-family:var(--serif);font-size:20px;">—</span>
        </div>
        <p style="font-size:12px;color:var(--success);margin-top:10px;">
          ✓ Không cần tiền cọc với thuê ngắn hạn.
        </p>
      </div>

      <%-- Dài hạn: tính đúng theo tháng + ngày lẻ (KHÔNG hiện phí nền tảng) --%>
      <div id="costLong" style="display:none;">
        <div class="ps-row">
          <span>Giá thuê / tháng</span>
          <span id="l_priceMonth" style="font-weight:600;">—</span>
        </div>
        <div class="ps-row">
          <span id="l_monthLabel">Số tháng thuê</span>
          <span id="l_months" style="font-weight:600;">—</span>
        </div>
        <div id="l_dayRow" class="ps-row" style="display:none;">
          <span id="l_dayLabel">Ngày lẻ (×<span id="l_dayCount">0</span> ngày)</span>
          <span id="l_dayAmt" style="font-weight:600;">—</span>
        </div>
        <div class="ps-row">
          <span>Tiền cọc (<span id="l_depositN">${apartment.depositMonths}</span> tháng)</span>
          <span id="l_deposit" style="font-weight:600;">—</span>
        </div>
        <div class="ps-row" style="border-bottom:1px solid var(--border);">
          <span style="font-size:12px;color:var(--light);">Tháng đầu thanh toán ngay</span>
          <span id="l_firstPay" style="color:var(--accent);font-family:var(--serif);font-size:18px;font-weight:700;">—</span>
        </div>
        <div class="ps-row ps-total">
          <span>Tổng cả hợp đồng</span>
          <span id="l_total" style="color:var(--mid);font-size:14px;">—</span>
        </div>
      </div>
    </div>

    <%-- Điều khoản --%>
    <div style="background:var(--cream);border:1px solid var(--border);border-left:3px solid var(--accent);padding:18px 20px;margin-bottom:22px;">
      <p style="font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:12px;">Điều khoản hợp đồng</p>
      <ul style="font-size:13.5px;color:var(--mid);line-height:2;list-style:disc;padding-left:20px;">
        <li>Người thuê chịu trách nhiệm bảo quản tài sản trong căn hộ.</li>
        <li>Thanh toán đúng hạn theo kỳ quy định trong hợp đồng.</li>
        <li>Tiền cọc hoàn trả trong 7 ngày sau khi kết thúc hợp đồng hợp lệ.</li>
        <li>Chấm dứt sớm cần thông báo trước 30 ngày.</li>
        <li><strong>Ngắn hạn (&lt;30 ngày):</strong> Tổng = giá ngày × số ngày. Không cọc.</li>
        <li><strong>Dài hạn (≥30 ngày):</strong> Tổng = giá tháng × số tháng + ngày lẻ. Có tiền cọc.</li>
      </ul>
    </div>

    <div class="form-group">
      <label class="chk-item" style="font-size:14px;">
        <input type="checkbox" required>
        <span>Tôi đã đọc và đồng ý với tất cả điều khoản hợp đồng trên.</span>
      </label>
    </div>

    <div style="display:flex;gap:12px;margin-top:24px;">
      <a href="${pageContext.request.contextPath}/apartment/${apartment.aptId}" class="btn btn-outline btn-lg">← Quay lại</a>
      <button type="submit" id="submitBtn" class="btn btn-dark btn-lg" style="flex:1;" disabled>
        <i class="fas fa-paper-plane"></i> Gửi yêu cầu thuê →
      </button>
    </div>
  </form>
</div>

<script>
// ── Dữ liệu từ server ──────────────────────────────────────────
var PRICE_MONTH    = ${not empty apartment.rentPriceMonth ? apartment.rentPriceMonth : apartment.rentPrice};
var PRICE_DAY      = ${not empty apartment.rentPriceDay ? apartment.rentPriceDay : 0};
var DEPOSIT_MONTHS = ${apartment.depositMonths};
var RENTAL_TYPE    = '${apartment.rentalType}'; // short, long, both

// Fallback giá ngày nếu không có
if (PRICE_DAY === 0 && PRICE_MONTH > 0) PRICE_DAY = Math.round(PRICE_MONTH / 25);

function fmtVND(n) {
  return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + ' ₫';
}

function daysBetween(s, e) {
  if (!s || !e) return 0;
  var diff = new Date(e) - new Date(s);
  return diff > 0 ? Math.round(diff / 86400000) : 0;
}

// ── Tính ngày lẻ cuối hợp đồng dài hạn ────────────────────────
// Công thức: tháng đầy đủ + ngày lẻ tháng cuối
function calcLongTermCost(startStr, endStr) {
  var start = new Date(startStr);
  var end   = new Date(endStr);
  var totalDays = Math.round((end - start) / 86400000);

  // Số tháng đầy đủ: từ start đến cùng ngày của start ở tháng tiếp theo
  var cur = new Date(start);
  var fullMonths = 0;
  while (true) {
    var next = new Date(cur);
    next.setMonth(next.getMonth() + 1);
    if (next > end) break;
    fullMonths++;
    cur = next;
  }
  // Ngày lẻ = end - cur (phần còn lại sau tháng cuối đầy đủ)
  var remainDays = Math.round((end - cur) / 86400000);

  return {
    totalDays:   totalDays,
    fullMonths:  fullMonths,
    remainDays:  remainDays,
    rentFull:    PRICE_MONTH * fullMonths,
    rentRemain:  remainDays > 0 ? Math.round(PRICE_MONTH / 30 * remainDays) : 0,
    totalRent:   function() { return this.rentFull + this.rentRemain; },
    depositAmt:  PRICE_MONTH * DEPOSIT_MONTHS,
    firstPay:    PRICE_MONTH + (PRICE_MONTH * DEPOSIT_MONTHS), // tháng đầu + cọc
  };
}

// ── Recalculate ────────────────────────────────────────────────
function recalc() {
  var start = document.getElementById('startDate').value;
  var end   = document.getElementById('endDate').value;
  
  // ── FIX BUG 1: Tự động cập nhật min của endDate khi startDate thay đổi ──
  if (start) {
    // endDate phải >= startDate + 1 ngày
    var minEnd = new Date(start);
    minEnd.setDate(minEnd.getDate() + 1);
    document.getElementById('endDate').min = minEnd.toISOString().split('T')[0];
    
    // Nếu endDate hiện tại <= startDate, reset endDate
    if (end && end <= start) {
      // Đặt endDate mặc định tùy loại
      var defaultEnd = new Date(start);
      if (RENTAL_TYPE === 'long') {
        defaultEnd.setMonth(defaultEnd.getMonth() + 6);
      } else {
        defaultEnd.setDate(defaultEnd.getDate() + 7);
      }
      document.getElementById('endDate').value = defaultEnd.toISOString().split('T')[0];
      end = document.getElementById('endDate').value;
    }
  }

  if (!start || !end) return;

  var days = daysBetween(start, end);
  if (days <= 0) {
    showTypeInfo('⚠️ Ngày kết thúc phải sau ngày bắt đầu.', 'warn');
    document.getElementById('submitBtn').disabled = true;
    resetCost();
    return;
  }

  // ── Xác định loại thuê tự động từ số ngày ──────────────────
  var isShort = days < 30;

  // Kiểm tra loại căn hộ hỗ trợ
  if (isShort && RENTAL_TYPE === 'long') {
    showTypeInfo('⚠️ Căn hộ này chỉ cho thuê dài hạn (≥30 ngày). Vui lòng chọn ngày dài hơn.', 'warn');
    document.getElementById('submitBtn').disabled = true;
    resetCost(); return;
  }
  if (!isShort && RENTAL_TYPE === 'short') {
    showTypeInfo('⚠️ Căn hộ này chỉ cho thuê ngắn hạn (<30 ngày). Vui lòng chọn ngày ngắn hơn.', 'warn');
    document.getElementById('submitBtn').disabled = true;
    resetCost(); return;
  }

  document.getElementById('submitBtn').disabled = false;

  if (isShort) {
    // ── NGẮN HẠN ──────────────────────────────────────────────
    document.getElementById('rentalType').value = 'short';
    document.getElementById('costShort').style.display = 'block';
    document.getElementById('costLong').style.display  = 'none';

    var totalRent = PRICE_DAY * days;
    document.getElementById('s_priceDay').textContent = fmtVND(PRICE_DAY);
    document.getElementById('s_days').textContent     = days + ' ngày';
    document.getElementById('s_total').textContent    = fmtVND(totalRent);

    showTypeInfo('📅 Thuê ngắn hạn · ' + days + ' ngày · Tính theo giá ngày', 'ok');

  } else {
    // ── DÀI HẠN ───────────────────────────────────────────────
    document.getElementById('rentalType').value = 'long';
    document.getElementById('costShort').style.display = 'none';
    document.getElementById('costLong').style.display  = 'block';

    var r = calcLongTermCost(start, end);
    var totalRent = r.rentFull + r.rentRemain;
    var totalContract = totalRent + r.depositAmt;

    // Hiển thị tháng đầy đủ
    document.getElementById('l_priceMonth').textContent = fmtVND(PRICE_MONTH);
    document.getElementById('l_months').textContent     = r.fullMonths + ' tháng';

    // Hiển thị ngày lẻ nếu có
    if (r.remainDays > 0) {
      document.getElementById('l_dayRow').style.display = 'flex';
      document.getElementById('l_dayCount').textContent = r.remainDays;
      document.getElementById('l_dayAmt').textContent   = fmtVND(r.rentRemain);
    } else {
      document.getElementById('l_dayRow').style.display = 'none';
    }

    document.getElementById('l_depositN').textContent = DEPOSIT_MONTHS;
    document.getElementById('l_deposit').textContent  = fmtVND(r.depositAmt);
    document.getElementById('l_firstPay').textContent = fmtVND(r.firstPay);
    document.getElementById('l_total').textContent    = fmtVND(totalContract);

    var months = r.fullMonths + (r.remainDays > 0 ? '+' + r.remainDays + ' ngày' : '');
    showTypeInfo('📅 Thuê dài hạn · ' + r.totalDays + ' ngày (' + months + ')', 'ok');
  }
}

function showTypeInfo(msg, type) {
  var el = document.getElementById('typeInfo');
  el.style.display = 'block';
  el.style.borderLeftColor = type === 'warn' ? 'var(--warn)' : 'var(--success)';
  el.style.background = type === 'warn' ? '#fffbec' : 'var(--cream)';
  el.innerHTML = '<strong>' + msg + '</strong>';
}

function resetCost() {
  document.getElementById('costShort').style.display = 'block';
  document.getElementById('costLong').style.display  = 'none';
  document.getElementById('s_priceDay').textContent = '—';
  document.getElementById('s_days').textContent     = '—';
  document.getElementById('s_total').textContent    = '—';
}

// ── Khởi tạo khi load ─────────────────────────────────────────
(function init() {
  var today = new Date().toISOString().split('T')[0];
  document.getElementById('startDate').min   = today;
  document.getElementById('startDate').value = today;

  // ── FIX: endDate.min = today + 1 ngày ──
  var minEnd = new Date();
  minEnd.setDate(minEnd.getDate() + 1);
  document.getElementById('endDate').min = minEnd.toISOString().split('T')[0];

  var d = new Date();
  if (RENTAL_TYPE === 'long') {
    d.setMonth(d.getMonth() + 6);
  } else {
    d.setDate(d.getDate() + 7);
  }
  document.getElementById('endDate').value = d.toISOString().split('T')[0];
  recalc();
})();

</script>

<%@ include file="../includes/footer.jsp" %>
