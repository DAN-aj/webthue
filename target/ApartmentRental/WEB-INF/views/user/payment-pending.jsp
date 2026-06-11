<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Chờ thanh toán — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>

<style>
@keyframes spin  { to{transform:rotate(360deg);} }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.35} }
@keyframes popIn { 0%{opacity:0;transform:scale(.85)} 70%{transform:scale(1.04)} 100%{opacity:1;transform:scale(1)} }

.qr-frame {
  background:#fff;padding:10px;border-radius:6px;
  box-shadow:0 6px 32px rgba(0,0,0,.14);
  display:inline-block;position:relative;
}
.qr-frame img { display:block;width:230px;height:230px;border-radius:3px; }
.qr-loader {
  position:absolute;inset:0;background:#fff;border-radius:6px;
  display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;
}
.spinner {width:40px;height:40px;border:3px solid #eee;border-top-color:#c84e2a;
          border-radius:50%;animation:spin .85s linear infinite;}
.dot-blink {width:8px;height:8px;border-radius:50%;background:#F5A623;animation:pulse 1.2s infinite;}

.info-row {
  display:flex;justify-content:space-between;align-items:center;
  padding:10px 0;border-bottom:1px solid var(--border);font-size:13px;
}
.info-row:last-child{border-bottom:none;}
.copy-btn {
  font-size:10px;padding:3px 10px;border:1px solid var(--border);
  background:var(--white);cursor:pointer;color:var(--mid);
  border-radius:3px;transition:all .15s;flex-shrink:0;
}
.copy-btn:hover{background:var(--dark);color:#fff;border-color:var(--dark);}

/* Overlay thành công */
#overlayOk {
  display:none;position:fixed;inset:0;z-index:9999;
  background:rgba(0,0,0,.55);backdrop-filter:blur(5px);
  align-items:center;justify-content:center;
}
#overlayOk.show{display:flex;}
.ok-card {
  background:#fff;border-radius:10px;padding:48px 56px;
  text-align:center;max-width:400px;animation:popIn .4s ease;
}
.ok-icon {
  width:80px;height:80px;background:#E8F5E9;border-radius:50%;
  display:flex;align-items:center;justify-content:center;
  font-size:42px;margin:0 auto 20px;
}

/* Overlay thất bại */
#overlayFail {
  display:none;position:fixed;inset:0;z-index:9999;
  background:rgba(0,0,0,.55);backdrop-filter:blur(5px);
  align-items:center;justify-content:center;
}
#overlayFail.show{display:flex;}
.fail-card {
  background:#fff;border-radius:10px;padding:40px 48px;
  text-align:center;max-width:360px;animation:popIn .4s ease;
}
</style>

<%-- OVERLAY THÀNH CÔNG --%>
<div id="overlayOk">
  <div class="ok-card">
    <div class="ok-icon">✅</div>
    <div style="font-family:var(--serif);font-size:26px;font-weight:700;color:var(--dark);margin-bottom:10px;">
      Thanh toán thành công!
    </div>
    <div style="font-size:14px;color:var(--mid);line-height:1.8;margin-bottom:28px;">
      Hệ thống đã ghi nhận giao dịch của bạn.<br>
      Mã GD: <strong id="ovTx" style="font-family:monospace;color:var(--dark);"></strong>
    </div>
    <div style="background:var(--border);height:5px;border-radius:3px;overflow:hidden;margin-bottom:8px;">
      <div id="redBar" style="width:0%;height:5px;background:#1A6B1A;
                               transition:width 3s linear;border-radius:3px;"></div>
    </div>
    <p style="font-size:12px;color:var(--light);">Đang chuyển trang trong 3 giây...</p>
  </div>
</div>

<%-- OVERLAY THẤT BẠI / HẾT HẠN --%>
<div id="overlayFail">
  <div class="fail-card">
    <div style="font-size:52px;margin-bottom:16px;">⏰</div>
    <div style="font-family:var(--serif);font-size:22px;font-weight:700;color:var(--dark);margin-bottom:10px;">
      QR đã hết hạn
    </div>
    <p style="font-size:13px;color:var(--mid);margin-bottom:24px;line-height:1.7;">
      Mã QR không còn hiệu lực. Vui lòng tạo mã QR mới.
    </p>
    <a href="${pageContext.request.contextPath}/user/payment/checkout/${contract.contractId}?type=${payment.paymentType}"
       style="display:block;padding:13px;background:var(--dark);color:#fff;
              text-decoration:none;font-weight:700;border-radius:3px;font-size:14px;">
      Tạo QR mới →
    </a>
  </div>
</div>

<div class="page-strip" style="padding:30px 80px;">
  <span class="eyebrow">Bước cuối cùng</span>
  <h1>Quét QR để thanh toán</h1>
  <p style="color:rgba(255,255,255,.42);font-size:14px;margin-top:6px;">
    Mở app ngân hàng → Quét QR → Xác nhận. Hệ thống tự động ghi nhận.
  </p>
</div>

<div class="container" style="max-width:960px;padding-bottom:80px;">
  <div style="display:grid;grid-template-columns:260px 1fr;gap:48px;align-items:start;margin-top:40px;">

    <%-- ══ QR CODE ══ --%>
    <div style="text-align:center;">
      <%-- Badge trạng thái --%>
      <div style="display:inline-flex;align-items:center;gap:8px;background:#FFF8E7;
                  color:#7A5C1E;padding:7px 16px;border-radius:20px;font-size:13px;
                  font-weight:600;margin-bottom:18px;">
        <div class="dot-blink"></div>
        Đang chờ thanh toán...
      </div>

      <%-- QR frame --%>
      <div class="qr-frame">
        <div class="qr-loader" id="qrLoader">
          <div class="spinner"></div>
          <span style="font-size:12px;color:#999;">Đang tải QR...</span>
        </div>
        <img id="qrImg" src="${qrUrl}"
             onload="onQRLoad()"
             onerror="onQRError()"
             alt="QR chuyển khoản"
             style="opacity:0;transition:opacity .3s;">
      </div>

      <%-- Logo VietQR --%>
      <div style="margin-top:10px;display:inline-flex;align-items:center;gap:6px;
                  background:#fff;padding:5px 14px;border-radius:20px;
                  box-shadow:0 2px 10px rgba(0,0,0,.08);">
        <span style="font-size:11px;font-weight:800;color:#d42020;letter-spacing:.5px;">VietQR</span>
        <span style="font-size:10px;color:var(--light);">30+ ngân hàng</span>
      </div>

      <%-- Timer --%>
      <div style="margin-top:16px;padding:9px 18px;border:1px solid var(--border);
                  display:inline-flex;align-items:center;gap:8px;font-size:13px;
                  border-radius:3px;background:var(--white);">
        ⏱ <span style="color:var(--mid);">Hết hạn sau:</span>
        <strong id="timerEl" style="font-family:monospace;font-size:15px;
                                    color:var(--dark);min-width:44px;">
          ${qrExpMin}:00
        </strong>
      </div>

      <%-- Tạo QR mới --%>
      <div style="margin-top:10px;">
        <a href="${pageContext.request.contextPath}/user/payment/checkout/${contract.contractId}?type=${payment.paymentType}"
           style="font-size:12px;color:var(--light);text-decoration:underline;">
          ↺ Tạo QR mới
        </a>
      </div>
    </div>

    <%-- ══ THÔNG TIN CHUYỂN KHOẢN ══ --%>
    <div>
      <div style="font-family:var(--serif);font-size:22px;font-weight:700;margin-bottom:3px;">
        ${contract.aptTitle}
      </div>
      <div style="font-size:11px;color:var(--light);text-transform:uppercase;
                  letter-spacing:1.5px;margin-bottom:22px;">
        <c:choose>
          <c:when test="${payment.paymentType eq 'initial'}">Thanh toán lần đầu</c:when>
          <c:otherwise>Tiền thuê định kỳ</c:otherwise>
        </c:choose>
      </div>

      <%-- Số tiền nổi bật --%>
      <div style="background:var(--dark);color:#fff;padding:18px 22px;border-radius:4px;margin-bottom:20px;">
        <div style="font-size:10px;opacity:.45;text-transform:uppercase;letter-spacing:1px;margin-bottom:6px;">
          Số tiền cần chuyển
        </div>
        <div style="font-family:var(--serif);font-size:32px;font-weight:700;letter-spacing:-.02em;">
          <fmt:formatNumber value="${payment.amount}" pattern="#,###"/> đ
        </div>
      </div>

      <%-- Thông tin TK --%>
      <div style="background:#fff;border:1px solid var(--border);border-radius:4px;
                  padding:0 18px;margin-bottom:18px;">
        <div class="info-row">
          <span style="color:var(--light);font-size:12px;">Ngân hàng</span>
          <strong>${bankName}</strong>
        </div>
        <div class="info-row">
          <span style="color:var(--light);font-size:12px;">Số tài khoản</span>
          <div style="display:flex;align-items:center;gap:10px;">
            <strong style="font-family:monospace;font-size:15px;letter-spacing:.5px;">${bankAccount}</strong>
            <button class="copy-btn" onclick="cp('${bankAccount}',this)">Sao chép</button>
          </div>
        </div>
        <div class="info-row">
          <span style="color:var(--light);font-size:12px;">Chủ tài khoản</span>
          <strong>${bankHolder}</strong>
        </div>
        <div class="info-row">
          <span style="color:var(--light);font-size:12px;">Nội dung chuyển khoản</span>
          <div style="display:flex;align-items:center;gap:10px;">
            <strong style="font-family:monospace;color:var(--accent);font-size:13px;">
              ${payment.txRef}
            </strong>
            <button class="copy-btn" onclick="cp('${payment.txRef}',this)">Sao chép</button>
          </div>
        </div>
      </div>

      <%-- Hướng dẫn --%>
      <div style="background:#EFF6FF;border:1px solid #BFDBFE;border-radius:4px;
                  padding:14px 16px;font-size:13px;color:#1E40AF;line-height:1.9;margin-bottom:16px;">
        <strong>📱 Cách thanh toán:</strong><br>
        1. Mở app ngân hàng → chọn <strong>Quét QR</strong><br>
        2. Quét mã QR bên trái — số tiền tự điền sẵn<br>
        3. Bấm <strong>Xác nhận</strong> trong app ngân hàng<br>
        <span style="color:#3B82F6;font-size:12px;margin-top:4px;display:block;">
          ✅ Hệ thống tự xác nhận — không cần làm gì thêm
        </span>
      </div>

      <div style="background:#FFF8E7;border-left:3px solid #F5A623;
                  padding:11px 14px;font-size:12px;color:#7A5C1E;line-height:1.7;border-radius:2px;">
        ⚠️ Nhập <strong>đúng nội dung</strong>
        <strong style="font-family:monospace;">${payment.txRef}</strong>
        nếu chuyển thủ công (không qua QR).
      </div>

      <%-- Polling status --%>
      <div style="margin-top:20px;padding:14px 18px;background:var(--cream);
                  border:1px dashed var(--border);border-radius:4px;text-align:center;">
        <div style="font-size:13px;color:var(--mid);" id="pollMsg">
          🔄 Đang kiểm tra giao dịch...
        </div>
        <div style="font-size:11px;color:var(--light);margin-top:5px;">
          Tự cập nhật mỗi 3 giây — không cần làm mới trang
        </div>
      </div>
    </div>

  </div>
</div>

<script>
var PAYMENT_ID = ${payment.paymentId};
var EXPIRE_MS  = ${qrExpMin} * 60 * 1000;
var startTime  = Date.now();
var pollCount  = 0;

// ── QR load ─────────────────────────────────────────────────────
function onQRLoad() {
  document.getElementById('qrImg').style.opacity = '1';
  document.getElementById('qrLoader').style.display = 'none';
}
function onQRError() {
  document.getElementById('qrLoader').innerHTML =
    '<div style="font-size:28px;">🏦</div>' +
    '<div style="font-size:11px;color:#888;text-align:center;line-height:1.7;padding:0 14px;">' +
    'Không tải được QR.<br>Chuyển khoản thủ công<br>theo thông tin bên cạnh.</div>';
}

// ── Countdown ────────────────────────────────────────────────────
var timerEl  = document.getElementById('timerEl');
var timerInt = setInterval(function() {
  var rem = Math.max(0, EXPIRE_MS - (Date.now() - startTime));
  var m = Math.floor(rem/60000), s = Math.floor((rem%60000)/1000);
  timerEl.textContent = (m<10?'0':'')+m+':'+(s<10?'0':'')+s;
  timerEl.style.color = (m===0&&s<=30) ? '#C84E4E' : 'var(--dark)';
  if (rem===0) { clearInterval(timerInt); clearInterval(pollInt); showFail(); }
}, 1000);

// ── AJAX Polling ─────────────────────────────────────────────────
function poll() {
  pollCount++;
  fetch('${pageContext.request.contextPath}/api/payment/status?paymentId='+PAYMENT_ID, {
    headers:{'Cache-Control':'no-cache'}
  })
  .then(function(r){return r.json();})
  .then(function(d) {
    if (d.status==='success') {
      clearInterval(pollInt); clearInterval(timerInt);
      showOk(d.txCode, d.redirectUrl);
    } else if (d.status==='failed') {
      clearInterval(pollInt); clearInterval(timerInt);
      showFail();
    } else {
      document.getElementById('pollMsg').textContent =
        '🔄 Đang kiểm tra giao dịch... (lần '+pollCount+')';
    }
  })
  .catch(function(){});
}

var pollInt = setInterval(poll, 3000);
setTimeout(poll, 2000); // poll lần đầu sau 2 giây

// ── Overlay ──────────────────────────────────────────────────────
function showOk(txCode, url) {
  document.getElementById('ovTx').textContent = txCode||'';
  document.getElementById('overlayOk').classList.add('show');
  setTimeout(function(){ document.getElementById('redBar').style.width='100%'; }, 80);
  setTimeout(function(){
    window.location.href = url ||
      '${pageContext.request.contextPath}/user/payment/success/'+PAYMENT_ID;
  }, 3200);
}
function showFail() {
  document.getElementById('overlayFail').classList.add('show');
}

// ── Copy ─────────────────────────────────────────────────────────
function cp(text, btn) {
  navigator.clipboard.writeText(text).then(function(){
    var orig=btn.textContent;
    btn.textContent='✓ Đã sao chép';btn.style.background='var(--dark)';btn.style.color='#fff';
    setTimeout(function(){btn.textContent=orig;btn.style.background='';btn.style.color='';},2000);
  }).catch(function(){
    var t=document.createElement('textarea');t.value=text;
    document.body.appendChild(t);t.select();document.execCommand('copy');
    document.body.removeChild(t);
    btn.textContent='✓';setTimeout(function(){btn.textContent='Sao chép';},2000);
  });
}
</script>

<%@ include file="../includes/footer.jsp" %>
