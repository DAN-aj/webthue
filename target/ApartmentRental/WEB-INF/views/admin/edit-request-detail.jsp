<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Chi Tiết Yêu Cầu Chỉnh Sửa — Admin"/>
<%@ include file="../includes/header.jsp" %>
<%@ include file="sidebar.jsp" %>

<style>
  .modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:9000;align-items:center;justify-content:center;}
  .modal-overlay.active{display:flex;}
  .modal-box{background:var(--white);border:1px solid var(--border);padding:32px;width:460px;max-width:94vw;animation:modalIn .18s ease;}
  .confirm-box{background:var(--white);border:1px solid var(--border);padding:36px 32px;width:420px;max-width:94vw;text-align:center;animation:modalIn .18s ease;}
  @keyframes modalIn{from{opacity:0;transform:translateY(-12px)}to{opacity:1;transform:translateY(0)}}
  .modal-title{font-family:var(--serif);font-size:20px;font-weight:700;margin-bottom:6px;color:var(--dark);}
  .modal-sub{font-size:13px;color:var(--mid);margin-bottom:20px;line-height:1.55;}
  .modal-footer{display:flex;gap:10px;justify-content:flex-end;margin-top:22px;}
  .confirm-icon{font-size:38px;margin-bottom:14px;}
  .confirm-title{font-family:var(--serif);font-size:19px;font-weight:700;margin-bottom:8px;}
  .confirm-body{font-size:13.5px;color:var(--mid);line-height:1.6;margin-bottom:24px;}
  .confirm-footer{display:flex;gap:10px;justify-content:center;}
  .changed{color:var(--accent)!important;font-weight:700!important;}
  .changed-row{background:#fffbf0;}
  .reason-error{color:var(--danger);font-size:12px;margin-top:5px;display:none;}
  .reason-error.visible{display:block;}
  @keyframes shake{0%,100%{transform:translateX(0)}20%{transform:translateX(-6px)}40%{transform:translateX(6px)}60%{transform:translateX(-4px)}80%{transform:translateX(4px)}}
  .shake{animation:shake .35s ease;}
</style>

<div class="admin-content">
  <div class="admin-header">
    <h1>Yêu cầu chỉnh sửa <span style="color:var(--mid);font-weight:400;">#${editRequest.requestId}</span></h1>
    <a href="${pageContext.request.contextPath}/admin/apartment/edit-requests" class="btn btn-outline btn-sm">← Quay lại danh sách</a>
  </div>

  <div style="font-size:12.5px;color:var(--light);margin-bottom:28px;">
    Gửi lúc <strong><fmt:formatDate value="${editRequest.createdAt}" pattern="HH:mm · dd/MM/yyyy"/></strong>
    &nbsp;·&nbsp; Chủ nhà: <strong>${editRequest.ownerName}</strong>
    &nbsp;·&nbsp; Căn hộ: <a href="${pageContext.request.contextPath}/admin/apartment/${editRequest.aptId}" style="color:var(--accent);">#${editRequest.aptId}</a>
  </div>

  <div style="display:grid;grid-template-columns:1fr 1fr;gap:24px;">
    <%-- GIÁ TRỊ HIỆN TẠI --%>
    <div style="background:var(--white);border:1px solid var(--border);padding:22px;">
      <h3 style="margin-bottom:16px;font-size:13px;text-transform:uppercase;letter-spacing:1px;color:var(--light);">Giá trị hiện tại</h3>
      <div class="ps-row"><span>Tiêu đề</span><strong>${apartment.title}</strong></div>
      <div class="ps-row"><span>Diện tích</span><strong>${apartment.area} m²</strong></div>
      <div class="ps-row"><span>Phòng ngủ</span><strong>${apartment.bedrooms}</strong></div>
      <div class="ps-row"><span>Phòng tắm</span><strong>${apartment.bathrooms}</strong></div>
      <div class="ps-row"><span>Giá tháng</span><strong><fmt:formatNumber value="${apartment.rentPriceMonth}" pattern="#,###"/> ₫</strong></div>
      <div class="ps-row"><span>Giá ngày</span><strong><fmt:formatNumber value="${apartment.rentPriceDay}" pattern="#,###"/> ₫</strong></div>
      <div class="ps-row"><span>Tiền cọc</span><strong>${apartment.depositMonths} tháng</strong></div>
      <div class="ps-row" style="border:none;"><span>Kỳ thanh toán</span><strong>${apartment.paymentPeriod} tháng</strong></div>
    </div>

    <%-- ĐỀ XUẤT THAY ĐỔI – highlight hàng khác biệt --%>
    <div style="background:#f9fdf9;border:2px solid var(--success);padding:22px;">
      <h3 style="margin-bottom:16px;font-size:13px;text-transform:uppercase;letter-spacing:1px;color:var(--success);">
        Đề xuất thay đổi &nbsp;<span style="font-size:11px;opacity:.7;">(màu vàng = đã thay đổi)</span>
      </h3>

      <c:set var="titleChanged" value="${editRequest.newTitle ne apartment.title}"/>
      <div class="ps-row ${titleChanged ? 'changed-row' : ''}">
        <span>Tiêu đề</span><strong class="${titleChanged ? 'changed' : ''}">${editRequest.newTitle}</strong>
      </div>

      <c:set var="areaChanged" value="${editRequest.newArea != apartment.area}"/>
      <div class="ps-row ${areaChanged ? 'changed-row' : ''}">
        <span>Diện tích</span><strong class="${areaChanged ? 'changed' : ''}">${editRequest.newArea} m²</strong>
      </div>

      <c:set var="bedroomsChanged" value="${editRequest.newBedrooms != apartment.bedrooms}"/>
      <div class="ps-row ${bedroomsChanged ? 'changed-row' : ''}">
        <span>Phòng ngủ</span><strong class="${bedroomsChanged ? 'changed' : ''}">${editRequest.newBedrooms}</strong>
      </div>

      <c:set var="bathroomsChanged" value="${editRequest.newBathrooms != apartment.bathrooms}"/>
      <div class="ps-row ${bathroomsChanged ? 'changed-row' : ''}">
        <span>Phòng tắm</span><strong class="${bathroomsChanged ? 'changed' : ''}">${editRequest.newBathrooms}</strong>
      </div>

      <c:set var="priceMonthChanged" value="${editRequest.newRentPriceMonth != apartment.rentPriceMonth}"/>
      <div class="ps-row ${priceMonthChanged ? 'changed-row' : ''}">
        <span>Giá tháng</span>
        <strong class="${priceMonthChanged ? 'changed' : ''}"><fmt:formatNumber value="${editRequest.newRentPriceMonth}" pattern="#,###"/> ₫</strong>
      </div>

      <c:set var="priceDayChanged" value="${editRequest.newRentPriceDay != apartment.rentPriceDay}"/>
      <div class="ps-row ${priceDayChanged ? 'changed-row' : ''}">
        <span>Giá ngày</span>
        <strong class="${priceDayChanged ? 'changed' : ''}"><fmt:formatNumber value="${editRequest.newRentPriceDay}" pattern="#,###"/> ₫</strong>
      </div>

      <c:set var="depositChanged" value="${editRequest.newDepositMonths != apartment.depositMonths}"/>
      <div class="ps-row ${depositChanged ? 'changed-row' : ''}">
        <span>Tiền cọc</span><strong class="${depositChanged ? 'changed' : ''}">${editRequest.newDepositMonths} tháng</strong>
      </div>

      <c:set var="periodChanged" value="${editRequest.newPaymentPeriod != apartment.paymentPeriod}"/>
      <div class="ps-row" style="border:none;" class="${periodChanged ? 'changed-row' : ''}">
        <span>Kỳ thanh toán</span><strong class="${periodChanged ? 'changed' : ''}">${editRequest.newPaymentPeriod} tháng</strong>
      </div>
    </div>
  </div>

  <%-- Mô tả mới --%>
  <c:if test="${not empty editRequest.newDescription}">
    <div style="background:var(--white);border:1px solid var(--border);padding:20px;margin-top:20px;">
      <h3 style="margin-bottom:10px;font-size:13px;text-transform:uppercase;letter-spacing:1px;color:var(--light);">Mô tả mới</h3>
      <p style="font-size:14px;color:var(--mid);line-height:1.7;">${editRequest.newDescription}</p>
    </div>
  </c:if>

  <%-- Tiện nghi mới --%>
  <c:if test="${not empty editRequest.newAmenities}">
    <div style="background:var(--white);border:1px solid var(--border);padding:20px;margin-top:16px;">
      <h3 style="margin-bottom:10px;font-size:13px;text-transform:uppercase;letter-spacing:1px;color:var(--light);">Tiện nghi mới</h3>
      <code style="font-size:13px;">${editRequest.newAmenities}</code>
    </div>
  </c:if>

  <%-- ACTION BUTTONS (chỉ hiện khi còn pending) --%>
  <c:if test="${editRequest.status eq 'pending'}">
    <div style="display:flex;gap:14px;margin-top:32px;padding-top:24px;border-top:1px solid var(--border);">
      <button type="button" class="btn btn-approve btn-lg" id="btnApprove">
        ✓ &nbsp;Duyệt — Áp dụng thay đổi
      </button>
      <button type="button" class="btn btn-reject btn-lg" id="btnReject">
        ✕ &nbsp;Từ chối
      </button>
    </div>
  </c:if>

  <%-- Trạng thái nếu đã xử lý --%>
  <c:if test="${editRequest.status ne 'pending'}">
    <div style="margin-top:28px;" class="alert ${editRequest.status eq 'approved' ? 'alert-success' : 'alert-error'}">
      <c:choose>
        <c:when test="${editRequest.status eq 'approved'}">✅ Yêu cầu này đã được <strong>duyệt</strong>.</c:when>
        <c:otherwise>❌ Yêu cầu này đã bị <strong>từ chối</strong>.
          <c:if test="${not empty editRequest.rejectReason}">&nbsp;Lý do: <em>${editRequest.rejectReason}</em></c:if>
        </c:otherwise>
      </c:choose>
    </div>
  </c:if>
</div>

<%-- ═══════════════════════════════════════════════════
     MODAL 1 — Xác nhận DUYỆT
     ═══════════════════════════════════════════════════ --%>
<div class="modal-overlay" id="approveModal">
  <div class="confirm-box">
    <div class="confirm-icon">✅</div>
    <div class="confirm-title">Xác nhận duyệt yêu cầu?</div>
    <div class="confirm-body">
      Thay đổi sẽ được <strong>áp dụng ngay lập tức</strong> vào thông tin căn hộ.<br>
      Chủ nhà sẽ nhận thông báo xác nhận.
    </div>
    <div class="confirm-footer">
      <button type="button" class="btn btn-outline btn-sm" onclick="closeModal('approveModal')">Huỷ</button>
      <form action="${pageContext.request.contextPath}/admin/apartment/edit-request/${editRequest.requestId}" method="post" style="display:inline;">
        <input type="hidden" name="action" value="approve">
        <button type="submit" class="btn btn-approve">✓ &nbsp;Xác nhận duyệt</button>
      </form>
    </div>
  </div>
</div>

<%-- ═══════════════════════════════════════════════════
     MODAL 2 — Nhập lý do TỪ CHỐI  (A1: bắt buộc)
     ═══════════════════════════════════════════════════ --%>
<div class="modal-overlay" id="rejectModal">
  <div class="modal-box">
    <div class="modal-title">Từ chối yêu cầu chỉnh sửa</div>
    <div class="modal-sub">
      Chủ nhà sẽ nhận thông báo kèm lý do từ chối.<br>
      Vui lòng nhập lý do rõ ràng để chủ nhà có thể điều chỉnh lại.
    </div>
    <form action="${pageContext.request.contextPath}/admin/apartment/edit-request/${editRequest.requestId}" method="post" id="rejectForm">
      <input type="hidden" name="action" value="reject">
      <label style="font-size:13px;font-weight:500;display:block;margin-bottom:6px;">
        Lý do từ chối <span style="color:var(--danger);">*</span>
      </label>
      <textarea name="reason" id="rejectReason" class="form-control"
                placeholder="Ví dụ: Giá đề xuất vượt mức thị trường, cần điều chỉnh lại..."
                rows="4"></textarea>
      <div class="reason-error" id="reasonError">⚠ Vui lòng nhập lý do từ chối trước khi xác nhận.</div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline btn-sm" onclick="closeModal('rejectModal')">Huỷ</button>
        <button type="button" class="btn btn-reject" id="confirmRejectBtn">✕ &nbsp;Xác nhận từ chối</button>
      </div>
    </form>
  </div>
</div>

<script>
(function(){
  function openModal(id){ document.getElementById(id).classList.add('active'); document.body.style.overflow='hidden'; }
  window.closeModal = function(id){
    document.getElementById(id).classList.remove('active');
    document.body.style.overflow='';
    if(id==='rejectModal'){ document.getElementById('rejectReason').value=''; hideError(); }
  };

  // Đóng khi click nền
  document.querySelectorAll('.modal-overlay').forEach(function(o){
    o.addEventListener('click',function(e){ if(e.target===o) closeModal(o.id); });
  });

  // Phím Esc
  document.addEventListener('keydown',function(e){
    if(e.key==='Escape') document.querySelectorAll('.modal-overlay.active').forEach(function(m){ closeModal(m.id); });
  });

  var btnApprove = document.getElementById('btnApprove');
  if(btnApprove) btnApprove.addEventListener('click', function(){ openModal('approveModal'); });

  var btnReject  = document.getElementById('btnReject');
  if(btnReject)  btnReject.addEventListener('click',  function(){ openModal('rejectModal'); });

  function hideError(){
    var err=document.getElementById('reasonError'); var ta=document.getElementById('rejectReason');
    if(err) err.classList.remove('visible');
    if(ta)  ta.style.borderColor='';
  }

  // Validate bắt buộc lý do (luồng A1)
  var confirmBtn = document.getElementById('confirmRejectBtn');
  if(confirmBtn){
    confirmBtn.addEventListener('click', function(){
      var ta=document.getElementById('rejectReason');
      var err=document.getElementById('reasonError');
      if(!ta.value.trim()){
        err.classList.add('visible');
        ta.style.borderColor='var(--danger)';
        ta.classList.add('shake');
        ta.focus();
        setTimeout(function(){ ta.classList.remove('shake'); }, 400);
        return;
      }
      hideError();
      document.getElementById('rejectForm').submit();
    });
    document.getElementById('rejectReason').addEventListener('input', function(){
      if(this.value.trim()) hideError();
    });
  }
})();
</script>

<%@ include file="../includes/footer.jsp" %>
