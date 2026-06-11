<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Thanh Toán — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>

<style>
@keyframes spin  { to { transform:rotate(360deg); } }
@keyframes fadeIn{ from{opacity:0;transform:translateY(6px)} to{opacity:1;transform:translateY(0)} }

/* Phương thức */
.pm-box { border:1px solid var(--border);margin-bottom:10px;border-radius:4px;overflow:hidden;transition:border .15s; }
.pm-box.active { border:2px solid var(--dark); }
.pm-header { display:flex;align-items:center;gap:14px;padding:16px 18px;cursor:pointer;background:var(--white);transition:background .15s; }
.pm-header:hover,.pm-box.active .pm-header { background:var(--cream); }
.pm-panel { display:none;padding:22px;border-top:1px solid var(--border);background:var(--cream); }
.pm-box.active .pm-panel { display:block;animation:fadeIn .2s ease; }

/* Card preview */
.card-preview {
  background:linear-gradient(135deg,#1a1a18,#383830);color:#fff;
  padding:22px 20px;height:158px;display:flex;flex-direction:column;
  justify-content:space-between;border-radius:10px;margin-bottom:20px;
  box-shadow:0 8px 24px rgba(0,0,0,.25);
}
.card-chip { width:36px;height:28px;background:linear-gradient(135deg,#d4a843,#f0c862);border-radius:4px; }

/* Validation */
.form-control.is-valid   { border-color:#1A6B1A!important;box-shadow:0 0 0 3px rgba(26,107,26,.12)!important; }
.form-control.is-invalid { border-color:#C84E4E!important;box-shadow:0 0 0 3px rgba(200,78,78,.12)!important; }
.field-fb { font-size:11px;margin-top:4px;min-height:16px; }
.field-fb.ok  { color:#1A6B1A; }
.field-fb.err { color:#C84E4E; }

/* Nút chính */
#payBtn {
  width:100%;padding:18px;background:var(--dark);color:var(--white);
  border:none;font-family:var(--serif);font-size:18px;font-weight:700;
  cursor:pointer;border-radius:3px;transition:all .2s;
  display:flex;align-items:center;justify-content:center;gap:10px;
}
#payBtn:disabled { opacity:.5;cursor:not-allowed; }
#payBtn:not(:disabled):hover { background:#2a2a22; }
</style>

<div class="page-strip" style="padding:36px 80px;">
  <span class="eyebrow">Bảo vệ bởi Escrow</span>
  <h1>Xác nhận thanh toán</h1>
  <p style="color:rgba(255,255,255,.42);font-size:14px;margin-top:6px;">
    Tiền giữ an toàn trong Escrow — giải phóng sau khi bạn xác nhận nhận nhà.
  </p>
</div>

<c:if test="${not empty param.error}">
  <div style="background:#FFF0F0;border-left:4px solid #C84E4E;padding:12px 24px;
              font-size:13px;color:#7A2020;max-width:1100px;margin:18px auto 0;">
    <c:choose>
      <c:when test="${param.error eq 'expired'}">⏰ QR đã hết hạn — vui lòng tạo QR mới.</c:when>
      <c:when test="${param.error eq 'card_failed'}">❌ Thanh toán thẻ thất bại — kiểm tra lại thông tin.</c:when>
      <c:otherwise>⚠️ Có lỗi xảy ra. Vui lòng thử lại.</c:otherwise>
    </c:choose>
  </div>
</c:if>

<div class="container" style="max-width:1100px;padding-bottom:80px;">
  <div style="display:grid;grid-template-columns:1fr 380px;gap:40px;align-items:start;margin-top:36px;">

    <%-- ═══ LEFT: PHƯƠNG THỨC ═══ --%>
    <div>
      <p style="font-family:var(--serif);font-size:18px;font-weight:600;margin-bottom:16px;">
        Chọn phương thức thanh toán
      </p>

      <%-- 1. QR NGÂN HÀNG --%>
      <div class="pm-box active" id="box-qr">
        <div class="pm-header" onclick="switchPM('qr')">
          <input type="radio" name="pm" checked style="width:16px;height:16px;accent-color:var(--dark);flex-shrink:0;">
          <span style="font-size:22px;">🏦</span>
          <div>
            <div style="font-size:14px;font-weight:600;color:var(--dark);">Chuyển khoản QR ngân hàng</div>
            <div style="font-size:12px;color:var(--light);margin-top:2px;">
              Quét bằng bất kỳ app ngân hàng nào — số tiền tự điền sẵn
            </div>
          </div>
          <span style="margin-left:auto;font-size:11px;background:#E8F5E9;color:#1A6B1A;
                       padding:3px 10px;border-radius:20px;font-weight:600;">Miễn phí</span>
        </div>
        <div class="pm-panel">
          <%-- Preview thông tin ngân hàng — số tiền và nội dung CK đã sẵn --%>
          <div style="background:#fff;border:1px solid var(--border);border-radius:4px;padding:16px 18px;margin-bottom:14px;">
            <div style="display:grid;grid-template-columns:110px 1fr;gap:8px 12px;font-size:13px;align-items:center;">
              <span style="color:var(--light);font-size:10px;text-transform:uppercase;letter-spacing:.5px;">Ngân hàng</span>
              <strong>${bankName}</strong>

              <span style="color:var(--light);font-size:10px;text-transform:uppercase;letter-spacing:.5px;">Số tài khoản</span>
              <strong style="font-family:monospace;font-size:15px;letter-spacing:.8px;">${bankAccount}</strong>

              <span style="color:var(--light);font-size:10px;text-transform:uppercase;letter-spacing:.5px;">Chủ tài khoản</span>
              <strong>${bankHolder}</strong>

              <span style="color:var(--light);font-size:10px;text-transform:uppercase;letter-spacing:.5px;">Số tiền</span>
              <strong style="color:var(--accent);font-size:17px;">
                <fmt:formatNumber value="${amount}" pattern="#,###"/> đ
              </strong>

              <span style="color:var(--light);font-size:10px;text-transform:uppercase;letter-spacing:.5px;">Nội dung CK</span>
              <strong style="font-family:monospace;font-size:13px;color:var(--dark);">${txRef}</strong>
            </div>
          </div>
          <div style="background:#EFF6FF;border-left:3px solid #3B82F6;padding:12px 14px;
                      font-size:12px;color:#1E40AF;line-height:1.8;">
            📱 <strong>Bước tiếp theo:</strong> Bấm "Tiếp tục" → hệ thống hiển thị mã QR để quét.<br>
            ✅ Số tiền và nội dung đã nhúng sẵn — chỉ cần bấm <em>Xác nhận</em> trong app ngân hàng.<br>
            🔄 Hệ thống <strong>tự động xác nhận</strong> sau khi nhận tiền — không cần làm gì thêm.
          </div>
        </div>
      </div>

      <%-- 2. THẺ TÍN DỤNG --%>
      <div class="pm-box" id="box-card">
        <div class="pm-header" onclick="switchPM('card')">
          <input type="radio" name="pm" style="width:16px;height:16px;accent-color:var(--dark);flex-shrink:0;">
          <span style="font-size:22px;">💳</span>
          <div>
            <div style="font-size:14px;font-weight:500;color:var(--dark);">Thẻ tín dụng / Ghi nợ</div>
            <div style="font-size:12px;color:var(--light);margin-top:2px;">Visa · Mastercard · JCB · Napas</div>
          </div>
        </div>
        <div class="pm-panel">

          <%-- Card preview --%>
          <div class="card-preview">
            <div class="card-chip"></div>
            <div id="cDisp" style="font-size:17px;letter-spacing:.2em;font-family:monospace;">
              •••• •••• •••• ••••
            </div>
            <div style="display:flex;justify-content:space-between;font-size:12px;">
              <div>
                <div style="opacity:.45;font-size:9px;text-transform:uppercase;letter-spacing:1px;">Chủ thẻ</div>
                <div id="cName">TÊN CHỦ THẺ</div>
              </div>
              <div>
                <div style="opacity:.45;font-size:9px;text-transform:uppercase;letter-spacing:1px;">Hết hạn</div>
                <div id="cExp">MM/YY</div>
              </div>
              <div id="cNet" style="opacity:.6;align-self:flex-end;font-size:13px;font-weight:700;">VISA</div>
            </div>
          </div>

          <%-- Form thẻ — real-time validation --%>
          <div style="display:flex;flex-direction:column;gap:14px;">

            <div>
              <label class="form-label">Số thẻ <span style="color:#C84E4E;">*</span></label>
              <input id="ccNum" type="text" inputmode="numeric" class="form-control"
                     maxlength="19" placeholder="0000 0000 0000 0000"
                     oninput="vNum(this)" autocomplete="cc-number">
              <div class="field-fb" id="fb-num"></div>
            </div>

            <div>
              <label class="form-label">Tên chủ thẻ <span style="color:#C84E4E;">*</span></label>
              <input id="ccName" type="text" class="form-control"
                     placeholder="NGUYEN VAN AN" style="text-transform:uppercase;"
                     oninput="vName(this)" autocomplete="cc-name">
              <div class="field-fb" id="fb-name"></div>
            </div>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
              <div>
                <label class="form-label">Hết hạn <span style="color:#C84E4E;">*</span></label>
                <input id="ccExp" type="text" inputmode="numeric" class="form-control"
                       maxlength="5" placeholder="MM/YY"
                       oninput="vExp(this)" autocomplete="cc-exp">
                <div class="field-fb" id="fb-exp"></div>
              </div>
              <div>
                <label class="form-label">CVV <span style="color:#C84E4E;">*</span></label>
                <input id="ccCvv" type="password" inputmode="numeric" class="form-control"
                       maxlength="4" placeholder="•••"
                       oninput="vCvv(this)" autocomplete="cc-csc">
                <div class="field-fb" id="fb-cvv"></div>
              </div>
            </div>
          </div>

          <p style="margin-top:12px;font-size:11px;color:var(--light);">
            🔒 Thông tin mã hoá SSL — không lưu trữ trên hệ thống
          </p>
        </div>
      </div>

      <div style="display:flex;gap:10px;padding:13px 16px;background:var(--cream);
                  border:1px solid var(--border);border-left:3px solid var(--accent);
                  font-size:12.5px;color:var(--mid);margin-top:16px;border-radius:2px;">
        🔒 Tiền giữ trong Escrow — hoàn tiền 100% nếu có tranh chấp.
      </div>
    </div>

    <%-- ═══ RIGHT: TÓM TẮT + NÚT ═══ --%>
    <div style="position:sticky;top:88px;">
      <div style="background:var(--white);border:1px solid var(--border);
                  border-radius:4px;overflow:hidden;margin-bottom:16px;">
        <div style="padding:18px 20px;background:var(--cream);border-bottom:1px solid var(--border);">
          <div style="font-family:var(--serif);font-size:16px;font-weight:700;margin-bottom:3px;">
            ${contract.aptTitle}
          </div>
          <div style="font-size:10px;color:var(--light);text-transform:uppercase;letter-spacing:1.5px;">
            <c:choose>
              <c:when test="${payType eq 'initial'}">Thanh toán lần đầu</c:when>
              <c:otherwise>Tiền thuê kỳ ${periodMonth}</c:otherwise>
            </c:choose>
          </div>
        </div>
        <div style="padding:16px 20px;">
          <c:choose>
            <c:when test="${contract.rentalType eq 'short'}">
              <div style="display:flex;justify-content:space-between;padding:8px 0;
                          border-bottom:1px solid var(--border);font-size:13px;color:var(--mid);">
                <span>Giá / ngày</span>
                <span><fmt:formatNumber value="${contract.monthlyRent}" pattern="#,###"/> đ</span>
              </div>
              <div style="display:flex;justify-content:space-between;padding:8px 0;
                          border-bottom:1px solid var(--border);font-size:13px;color:var(--mid);">
                <span>Số ngày</span>
                <strong>${contract.totalDays} ngày</strong>
              </div>
            </c:when>
            <c:when test="${contract.rentalType eq 'long' and payType eq 'initial'}">
              <div style="display:flex;justify-content:space-between;padding:8px 0;
                          border-bottom:1px solid var(--border);font-size:13px;color:var(--mid);">
                <span>Tháng đầu tiên</span>
                <span><fmt:formatNumber value="${contract.monthlyRent}" pattern="#,###"/> đ</span>
              </div>
              <div style="display:flex;justify-content:space-between;padding:8px 0;
                          border-bottom:1px solid var(--border);font-size:13px;color:var(--mid);">
                <span>Tiền cọc</span>
                <span><fmt:formatNumber value="${contract.depositAmount}" pattern="#,###"/> đ</span>
              </div>
            </c:when>
            <c:otherwise>
              <div style="display:flex;justify-content:space-between;padding:8px 0;
                          border-bottom:1px solid var(--border);font-size:13px;color:var(--mid);">
                <span>Kỳ ${nextPeriod}/${totalPeriodicPeriods}</span>
                <span style="font-size:11px;color:var(--light);">${contract.paymentPeriod} tháng/kỳ</span>
              </div>
              <div style="margin:10px 0 4px;">
                <div style="display:flex;justify-content:space-between;font-size:11px;
                            color:var(--light);margin-bottom:5px;">
                  <span>Tiến độ</span>
                  <span>${paidPeriods}/${totalPeriodicPeriods} kỳ đã trả</span>
                </div>
                <c:set var="pct" value="${totalPeriodicPeriods>0 ? paidPeriods*100/totalPeriodicPeriods : 0}"/>
                <div style="background:var(--border);height:5px;border-radius:3px;">
                  <div style="background:var(--success);height:5px;border-radius:3px;width:${pct}%;"></div>
                </div>
              </div>
            </c:otherwise>
          </c:choose>

          <div style="display:flex;justify-content:space-between;align-items:center;
                      padding:14px 0 0;margin-top:10px;border-top:2px solid var(--dark);">
            <span style="font-family:var(--serif);font-size:16px;font-weight:700;">Tổng cộng</span>
            <span style="font-family:var(--serif);font-size:24px;font-weight:700;color:var(--accent);">
              <fmt:formatNumber value="${amount}" pattern="#,###"/> đ
            </span>
          </div>
        </div>
      </div>

      <form id="payForm" method="post"
            action="${pageContext.request.contextPath}/user/payment/process/${contract.contractId}">
        <input type="hidden" name="payType"       value="${payType}">
        <input type="hidden" name="amount"        value="${amount}">
        <input type="hidden" name="periodMonth"   value="${periodMonth}">
        <input type="hidden" name="txRef"         value="${txRef}">
        <input type="hidden" name="paymentMethod" id="hidMethod" value="bank_qr">

        <button type="button" id="payBtn" onclick="doSubmit()">
          🔒 Tiếp tục — <fmt:formatNumber value="${amount}" pattern="#,###"/> đ
        </button>
      </form>

      <a href="${pageContext.request.contextPath}/user/contract/detail/${contract.contractId}"
         style="display:flex;align-items:center;justify-content:center;padding:12px;
                border:1px solid var(--border);font-size:13px;color:var(--mid);
                text-decoration:none;margin-top:10px;border-radius:2px;transition:background .15s;"
         onmouseover="this.style.background='var(--cream)'"
         onmouseout="this.style.background=''">
        ← Quay lại hợp đồng
      </a>

      <div style="border:1px solid var(--border);font-size:12px;color:var(--light);
                  margin-top:14px;border-radius:2px;overflow:hidden;">
        <div style="padding:9px 14px;border-bottom:1px solid var(--border);">🔒 SSL 256-bit · PCI DSS</div>
        <div style="padding:9px 14px;border-bottom:1px solid var(--border);">↩ Hoàn tiền nếu tranh chấp</div>
        <div style="padding:9px 14px;">📞 Hỗ trợ 24/7 · 1800 6868</div>
      </div>
    </div>

  </div>
</div>

<script>
var curPM = 'qr';
var cardOk = {num:false, name:false, exp:false, cvv:false};

function switchPM(pm) {
  curPM = pm;
  ['qr','card'].forEach(function(t) {
    var box = document.getElementById('box-'+t);
    if (t===pm) box.classList.add('active'); else box.classList.remove('active');
    box.querySelector('input[type=radio]').checked = (t===pm);
  });
  document.getElementById('hidMethod').value = (pm==='card') ? 'card' : 'bank_qr';
  if (pm==='qr') document.getElementById('payBtn').disabled = false;
  else           recheck();
}

// ── Real-time validation ────────────────────────────────────────
function setF(inpId, fbId, ok, msg) {
  var inp = document.getElementById(inpId);
  var fb  = document.getElementById(fbId);
  var hasVal = inp.value.length > 0;
  inp.classList.toggle('is-valid',   ok && hasVal);
  inp.classList.toggle('is-invalid', !ok && hasVal);
  fb.textContent = hasVal ? msg : '';
  fb.className = 'field-fb ' + (ok ? 'ok' : 'err');
  return ok;
}

function vNum(inp) {
  var raw = inp.value.replace(/\D/g,'').substring(0,16);
  inp.value = raw.replace(/(.{4})/g,'$1 ').trim();
  document.getElementById('cDisp').textContent = raw.padEnd(16,'•').match(/.{4}/g).join(' ');
  document.getElementById('cNet').textContent =
    raw.startsWith('4')?'VISA': raw.startsWith('5')?'MC': raw.startsWith('37')?'AMEX':'NAPAS';
  var ok = raw.length===16 && luhn(raw);
  cardOk.num = setF('ccNum','fb-num', ok,
    ok ? '✓ Số thẻ hợp lệ' : raw.length<16 ? 'Nhập đủ 16 số' : 'Số thẻ không hợp lệ');
  recheck();
}

function vName(inp) {
  inp.value = inp.value.toUpperCase();
  document.getElementById('cName').textContent = inp.value || 'TÊN CHỦ THẺ';
  var ok = inp.value.trim().length>=2 && /^[A-Z\s]+$/.test(inp.value.trim());
  cardOk.name = setF('ccName','fb-name', ok,
    ok ? '✓ Hợp lệ' : 'Chỉ nhập chữ cái không dấu, viết hoa');
  recheck();
}

function vExp(inp) {
  var raw = inp.value.replace(/\D/g,'');
  if (raw.length>=3) raw = raw.slice(0,2)+'/'+raw.slice(2,4);
  inp.value = raw;
  document.getElementById('cExp').textContent = raw || 'MM/YY';
  var ok=false, msg='Định dạng MM/YY';
  if (raw.length===5) {
    var mm=parseInt(raw),yy=parseInt(raw.slice(3));
    var exp=new Date(2000+yy,mm-1);
    ok = mm>=1&&mm<=12&&exp>=new Date();
    msg = ok ? '✓ Còn hiệu lực' : (exp<new Date() ? 'Thẻ đã hết hạn' : 'Tháng không hợp lệ');
  }
  cardOk.exp = setF('ccExp','fb-exp', ok, msg);
  recheck();
}

function vCvv(inp) {
  inp.value = inp.value.replace(/\D/g,'');
  var ok = inp.value.length>=3;
  cardOk.cvv = setF('ccCvv','fb-cvv', ok, ok ? '✓ Hợp lệ' : '3-4 chữ số');
  recheck();
}

function recheck() {
  if (curPM!=='card') return;
  document.getElementById('payBtn').disabled = !(cardOk.num&&cardOk.name&&cardOk.exp&&cardOk.cvv);
}

function luhn(n) {
  var s=0;
  for (var i=0;i<n.length;i++) {
    var d=parseInt(n[n.length-1-i]);
    if (i%2===1){d*=2;if(d>9)d-=9;}
    s+=d;
  }
  return s%10===0;
}

function doSubmit() {
  if (curPM==='card') {
    vNum(document.getElementById('ccNum'));
    vName(document.getElementById('ccName'));
    vExp(document.getElementById('ccExp'));
    vCvv(document.getElementById('ccCvv'));
    if (!(cardOk.num&&cardOk.name&&cardOk.exp&&cardOk.cvv)) return;
  }
  var btn = document.getElementById('payBtn');
  btn.disabled=true;
  btn.innerHTML='<span style="width:18px;height:18px;border:2px solid rgba(255,255,255,.35);'
    +'border-top-color:#fff;border-radius:50%;animation:spin .7s linear infinite;display:inline-block;"></span> Đang xử lý...';
  document.getElementById('payForm').submit();
}
</script>

<%@ include file="../includes/footer.jsp" %>
