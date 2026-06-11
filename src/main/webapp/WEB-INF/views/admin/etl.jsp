<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="ETL Pipeline — Admin"/>
<%@ include file="../includes/header.jsp" %>

<style>
  /* ETL-specific styles, uses design system from header */
  .schedule-box{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;margin-bottom:24px;}
  .scard{background:var(--white);border:1px solid var(--border);padding:20px 24px;}
  .scard-lbl{font-size:10px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--light);margin-bottom:8px;}
  .scard-val{font-size:20px;font-weight:700;color:var(--dark);line-height:1.2;}
  .scard-sub{font-size:12px;color:var(--light);margin-top:5px;}
  .countdown{font-size:14px;font-weight:700;color:var(--dark);font-variant-numeric:tabular-nums;}
  .krow{display:grid;grid-template-columns:repeat(4,1fr);gap:2px;background:var(--border);margin-bottom:24px;border:1px solid var(--border);}
  .kcard{background:var(--white);padding:20px 22px;}
  .kcard.ok{border-left:3px solid var(--success);}
  .kcard.warn{border-left:3px solid var(--danger);}
  .kcard.info{border-left:3px solid #2563EB;}
  .k-lbl{font-size:10px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:var(--light);margin-bottom:8px;}
  .k-val{font-size:28px;font-weight:700;color:var(--dark);line-height:1;letter-spacing:-.03em;}
  .k-val.g{color:var(--success);}  .k-val.r{color:var(--danger);}  .k-val.b{color:#2563EB;}
  .k-sub{font-size:12px;color:var(--light);margin-top:6px;}
  .panel{background:var(--white);border:1px solid var(--border);margin-bottom:16px;}
  .ph{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;}
  .pt{font-size:10px;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:var(--light);}
  .pb{padding:20px;}
  .etl-btn{display:inline-flex;align-items:center;gap:7px;border:none;padding:10px 20px;font-size:13px;font-weight:600;cursor:pointer;transition:.15s;font-family:var(--sans);letter-spacing:.3px;}
  .etl-btn-run{background:var(--dark);color:var(--white);}
  .etl-btn-run:hover{background:var(--accent);color:var(--dark);}
  .etl-btn-stop{background:var(--danger);color:var(--white);opacity:.4;cursor:not-allowed;}
  .etl-btn-stop.active{opacity:1;cursor:pointer;}
  .etl-btn-stop.active:hover{background:#4e1a1a;}
  .etl-btn-outline{background:var(--white);color:var(--dark);border:1px solid var(--border);}
  .etl-btn-outline:hover{background:var(--cream);}
  .state-badge{display:inline-flex;align-items:center;gap:6px;padding:5px 14px;font-size:11px;font-weight:700;letter-spacing:.8px;text-transform:uppercase;border:1px solid;}
  .pipe-wrap{display:flex;flex-wrap:wrap;gap:8px;align-items:flex-end;margin:14px 0;}
  .pnode{text-align:center;}
  .pnode span{display:inline-block;border:1px solid var(--border);padding:7px 13px;font-size:11px;font-weight:600;color:var(--dark);background:var(--cream);transition:.2s;letter-spacing:.3px;}
  .pnode span.fact{border-color:#C7D9F8;background:#EEF4FF;color:#1a56db;}
  .pnode span.agg{border-color:#B7DFB9;background:#E8F4E8;color:var(--success);}
  .pnode span.running{box-shadow:0 0 0 2px var(--accent);animation:pulse 1.2s infinite;}
  .pnode span.done{border-color:#B7DFB9;background:#E8F4E8;color:var(--success);}
  .pnode span.failed{border-color:#F5C6C0;background:#F4E8E8;color:var(--danger);}
  .pnode span.cancelled{border-color:var(--border);background:var(--cream);color:var(--light);}
  .pnode .to{font-size:10px;color:var(--light);margin-top:4px;display:flex;align-items:center;justify-content:center;gap:3px;}
  @keyframes pulse{0%{box-shadow:0 0 0 2px var(--accent);}50%{box-shadow:0 0 0 5px rgba(200,169,110,.2);}100%{box-shadow:0 0 0 2px var(--accent);}}
  .etbl{width:100%;border-collapse:collapse;font-size:13px;}
  .etbl th{padding:10px 16px;text-align:left;font-size:10px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);}
  .etbl td{padding:11px 16px;border-bottom:1px solid var(--border);color:var(--mid);}
  .etbl tr:last-child td{border-bottom:none;}
  .etbl tr:hover td{background:var(--cream);}
  .etl-st{display:inline-block;padding:3px 10px;font-size:10px;font-weight:700;letter-spacing:.5px;text-transform:uppercase;}
  .etl-st-success,.etl-st-DONE{background:#E8F4E8;color:var(--success);}
  .etl-st-failed,.etl-st-FAILED{background:#F4E8E8;color:var(--danger);}
  .etl-st-running,.etl-st-RUNNING,.etl-st-timeout,.etl-st-TIMEOUT{background:#FEF3E2;color:#B45309;}
  .etl-st-CANCELLED,.etl-st-cancelled{background:var(--cream);color:var(--light);}
  .etl-alert{padding:13px 18px;font-size:13px;font-weight:500;margin-bottom:16px;display:none;border-left:3px solid;}
  .etl-alert.success{background:#f0f7f3;border-color:var(--success);color:var(--success);}
  .etl-alert.error{background:#F4E8E8;border-color:var(--danger);color:var(--danger);}
  .etl-alert.info{background:#FEF3E2;border-color:#B45309;color:#B45309;}
  .etl-sel{border:1px solid var(--border);padding:9px 13px;font-size:13px;font-family:var(--sans);background:var(--white);color:var(--dark);}
  @media(max-width:1024px){.schedule-box{grid-template-columns:1fr 1fr;} .krow{grid-template-columns:1fr 1fr;}}
  @media(max-width:768px){.schedule-box{grid-template-columns:1fr;} .krow{grid-template-columns:1fr;} .admin-main{padding:24px;}}
</style>

<div class="admin-shell">
  <%@ include file="sidebar.jsp" %>

  <main class="admin-main">

    <div class="admin-header">
      <h1>ETL Pipeline</h1>
      <p>Quản lý và giám sát ETL tự động vào DWH</p>
    </div>

    <div id="alertBox" class="etl-alert"></div>

    <%-- Lịch chạy + countdown --%>
    <div class="schedule-box">
      <div class="scard">
        <div class="scard-lbl">Lịch chạy tự động</div>
        <div class="scard-val">02:00 ICT mỗi ngày</div>
        <div class="scard-sub">Cron: <code>0 0 2 * * ?</code></div>
      </div>
      <div class="scard">
        <div class="scard-lbl">Lần chạy tiếp theo</div>
        <div class="scard-val">${nextFireTime}</div>
        <div class="scard-sub">Còn lại: <span id="countdown" class="countdown">--:--:--</span></div>
      </div>
      <div class="scard" style="border-left:3px solid ${dwhFresh ? 'var(--success)' : '#B45309'};">
        <div class="scard-lbl">ETL gần nhất</div>
        <div class="scard-val" style="font-size:15px;color:${dwhFresh ? 'var(--success)' : '#B45309'};">
          ${dwhFresh ? '✓ DWH đã cập nhật' : '⚠ DWH chưa cập nhật'}
        </div>
        <div class="scard-sub">${lastRun}</div>
      </div>
    </div>

    <%-- KPI --%>
    <div class="krow">
      <div class="kcard">
        <div class="k-lbl">Tổng lần chạy</div>
        <div class="k-val">${auditLog.size()}</div>
        <div class="k-sub">40 log gần nhất</div>
      </div>
      <div class="kcard ok">
        <div class="k-lbl">Thành công</div>
        <div class="k-val g">${successCount}</div>
        <div class="k-sub">status = success</div>
      </div>
      <div class="kcard ${failCount > 0 ? 'warn' : 'ok'}">
        <div class="k-lbl">Thất bại</div>
        <div class="k-val ${failCount > 0 ? 'r' : 'g'}">${failCount}</div>
        <div class="k-sub">${failCount > 0 ? 'Cần kiểm tra' : 'Không có lỗi'}</div>
      </div>
      <div class="kcard info">
        <div class="k-lbl">Tổng rows xử lý</div>
        <div class="k-val b">${totalRowsFmt}</div>
        <div class="k-sub">40 log gần nhất</div>
      </div>
    </div>

    <%-- Điều khiển Pipeline --%>
    <div class="panel">
      <div class="ph">
        <span class="pt">Điều khiển pipeline</span>
        <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
          <span id="stateBadge" class="state-badge" style="background:var(--cream);color:var(--light);border-color:var(--border);">IDLE</span>
          <span id="elapsedLabel" style="font-size:12px;color:var(--light);"></span>
          <span id="timeoutBadge" style="display:none;font-size:11px;padding:3px 10px;background:#FEF3E2;color:#B45309;border:1px solid #F6D860;"></span>
        </div>
      </div>
      <div class="pb">
        <div style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:20px;">
          <form method="post" action="${pageContext.request.contextPath}/admin/etl" style="margin:0;" onsubmit="return onRunAll()">
            <input type="hidden" name="etlAction" value="runAll">
            <button type="submit" id="btnRunAll" class="etl-btn etl-btn-run">
              <svg width="11" height="11" viewBox="0 0 10 10" fill="currentColor"><polygon points="1,0 9,5 1,10"/></svg>
              Chạy toàn bộ pipeline
            </button>
          </form>
          <form method="post" action="${pageContext.request.contextPath}/admin/etl" style="margin:0;" onsubmit="return onStop()">
            <input type="hidden" name="etlAction" value="stop">
            <button type="submit" id="btnStop" class="etl-btn etl-btn-stop">
              <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor"><rect width="10" height="10"/></svg>
              Dừng pipeline
            </button>
          </form>
          <div style="display:flex;gap:0;border:1px solid var(--border);">
            <select id="singleJob" class="etl-sel" style="border:none;">
              <option>DimTimeLoader</option>
              <option>DimLocationLoader</option>
              <option>DimUserLoader</option>
              <option>DimApartmentLoader</option>
              <option>FactContractLoader</option>
              <option>FactPaymentLoader</option>
              <option>AggDailyRevenueJob</option>
              <option>AggOccupancyJob</option>
            </select>
            <button onclick="runSingleJob()" class="etl-btn etl-btn-run" style="border-radius:0;">
              <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor"><polygon points="1,0 9,5 1,10"/></svg>
              Chạy job
            </button>
          </div>
          <button onclick="pollStatus()" class="etl-btn etl-btn-outline">
            <svg width="13" height="13" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M17 10A7 7 0 1 1 10 3"/><polyline points="10,3 14,3 14,7"/></svg>
            Làm mới
          </button>
        </div>

        <%-- Pipeline diagram --%>
        <div style="font-size:10px;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:var(--light);margin-bottom:10px;">Thứ tự thực thi + timeout</div>
        <div class="pipe-wrap">
          <div class="pnode"><span id="pipe-DimTimeLoader">DimTimeLoader</span><div class="to"><svg width="9" height="9" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="8"/><path d="M10 6v4l2.5 2.5"/></svg>60s</div></div>
          <div class="pnode"><span id="pipe-DimLocationLoader">DimLocationLoader</span><div class="to"><svg width="9" height="9" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="8"/><path d="M10 6v4l2.5 2.5"/></svg>60s</div></div>
          <div class="pnode"><span id="pipe-DimUserLoader">DimUserLoader</span><div class="to"><svg width="9" height="9" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="8"/><path d="M10 6v4l2.5 2.5"/></svg>120s</div></div>
          <div class="pnode"><span id="pipe-DimApartmentLoader">DimApartmentLoader</span><div class="to"><svg width="9" height="9" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="8"/><path d="M10 6v4l2.5 2.5"/></svg>120s</div></div>
          <span style="color:var(--border);font-size:20px;padding-bottom:18px;">→</span>
          <div class="pnode"><span id="pipe-FactContractLoader" class="fact">FactContractLoader</span><div class="to"><svg width="9" height="9" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="8"/><path d="M10 6v4l2.5 2.5"/></svg>900s</div></div>
          <div class="pnode"><span id="pipe-FactPaymentLoader" class="fact">FactPaymentLoader</span><div class="to"><svg width="9" height="9" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="8"/><path d="M10 6v4l2.5 2.5"/></svg>1800s</div></div>
          <span style="color:var(--border);font-size:20px;padding-bottom:18px;">→</span>
          <div class="pnode"><span id="pipe-AggDailyRevenueJob" class="agg">AggDailyRevenueJob</span><div class="to"><svg width="9" height="9" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="8"/><path d="M10 6v4l2.5 2.5"/></svg>120s</div></div>
          <div class="pnode"><span id="pipe-AggOccupancyJob" class="agg">AggOccupancyJob</span><div class="to"><svg width="9" height="9" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="10" cy="10" r="8"/><path d="M10 6v4l2.5 2.5"/></svg>120s</div></div>
        </div>

        <%-- Live progress --%>
        <div id="livePanel" style="display:none;margin-top:16px;">
          <div style="font-size:10px;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:var(--light);margin-bottom:8px;">Tiến độ thực thi</div>
          <div style="overflow-x:auto;border:1px solid var(--border);">
            <table class="etbl"><thead><tr>
              <th>Job</th><th>Trạng thái</th><th style="text-align:right;">Rows</th><th style="text-align:right;">Thời gian</th><th>Lỗi</th>
            </tr></thead><tbody id="liveTbody"></tbody></table>
          </div>
        </div>
      </div>
    </div>

    <%-- Audit Log --%>
    <div class="panel">
      <div class="ph">
        <span class="pt">Lịch sử ETL — 40 lần gần nhất</span>
        <span class="badge ${dwhFresh ? 'badge-green' : 'badge-amber'}">${dwhFresh ? 'DWH FRESH' : 'DWH STALE'}</span>
      </div>
      <div style="overflow-x:auto;">
        <table class="etbl">
          <thead><tr>
            <th>Job</th><th>Bắt đầu</th><th>Kết thúc</th><th style="text-align:right;">Rows</th><th>Trạng thái</th><th>Lỗi</th>
          </tr></thead>
          <tbody>
            <c:choose>
              <c:when test="${empty auditLog}">
                <tr><td colspan="6" style="text-align:center;padding:40px;color:var(--light);">Chưa có lịch sử ETL.</td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="row" items="${auditLog}">
                  <tr>
                    <td style="font-weight:500;color:var(--dark);">${row.job}</td>
                    <td style="color:var(--light);font-size:12px;">${row.start}</td>
                    <td style="color:var(--light);font-size:12px;">${row.end}</td>
                    <td style="text-align:right;font-weight:600;">${row.rowsFmt}</td>
                    <td><span class="etl-st etl-st-${row.status}">${row.statusLabel}</span></td>
                    <td>
                      <c:choose>
                        <c:when test="${not empty row.error}">
                          <span style="color:var(--danger);font-size:11px;">${row.error}</span>
                        </c:when>
                        <c:otherwise><span style="color:var(--light);">—</span></c:otherwise>
                      </c:choose>
                    </td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </tbody>
        </table>
      </div>
    </div>

  </main>
</div>

<script>
(function(){
  function pad(n){return String(n).padStart(2,'0');}
  function tick(){
    var now=new Date(), next=new Date();
    next.setHours(2,0,0,0);
    if(now>=next) next.setDate(next.getDate()+1);
    var diff=Math.floor((next-now)/1000);
    var h=Math.floor(diff/3600), m=Math.floor(diff%3600/60), s=diff%60;
    var el=document.getElementById('countdown');
    if(el) el.textContent=pad(h)+':'+pad(m)+':'+pad(s);
  }
  tick(); setInterval(tick,1000);
})();

var pollTimer=null;
var JOB_TO={DimTimeLoader:60,DimLocationLoader:60,DimUserLoader:120,DimApartmentLoader:120,FactContractLoader:900,FactPaymentLoader:1800,AggDailyRevenueJob:120,AggOccupancyJob:120};
var jobStart={};
var STATE_CFG={
  IDLE:{bg:'var(--cream)',color:'var(--light)',bd:'var(--border)',txt:'IDLE'},
  RUNNING:{bg:'#FEF3E2',color:'#B45309',bd:'#F6D860',txt:'● ĐANG CHẠY'},
  DONE:{bg:'#E8F4E8',color:'var(--success)',bd:'#B7DFB9',txt:'✓ HOÀN THÀNH'},
  FAILED:{bg:'#F4E8E8',color:'var(--danger)',bd:'#F5C6C0',txt:'⚠ CÓ LỖI'},
  STOPPED:{bg:'var(--cream)',color:'var(--light)',bd:'var(--border)',txt:'■ ĐÃ DỪNG'}
};

function pollStatus(){
  fetch('${pageContext.request.contextPath}/admin/etl?action=status')
  .then(r=>r.json()).then(updateUI).catch(console.error);
}
function startPolling(){if(!pollTimer) pollTimer=setInterval(pollStatus,2000);}
function stopPolling(){clearInterval(pollTimer);pollTimer=null;}

function updateUI(d){
  var sc=STATE_CFG[d.state]||STATE_CFG.IDLE;
  var b=document.getElementById('stateBadge');
  b.innerHTML=sc.txt;b.style.background=sc.bg;b.style.color=sc.color;b.style.borderColor=sc.bd;
  var el=document.getElementById('elapsedLabel');
  if(d.state==='RUNNING'&&d.elapsedMs>0){var s=Math.round(d.elapsedMs/1000);el.textContent=s<60?s+'s':Math.floor(s/60)+'m '+(s%60)+'s';}else{el.textContent='';}
  var tb=document.getElementById('timeoutBadge');
  if(d.state==='RUNNING'&&d.runningJob){
    if(!jobStart[d.runningJob])jobStart[d.runningJob]=Date.now();
    var max=JOB_TO[d.runningJob]||120;
    var spent=Math.round((Date.now()-jobStart[d.runningJob])/1000);
    var left=Math.max(0,max-spent);
    tb.style.display='';tb.textContent=d.runningJob+': còn '+left+'s';
    tb.style.background=left<30?'#F4E8E8':'#FEF3E2';tb.style.color=left<30?'var(--danger)':'#B45309';
    highlightJob(d.runningJob);
  } else {tb.style.display='none';clearHighlights();}
  var running=d.state==='RUNNING';
  document.getElementById('btnRunAll').disabled=running;
  document.getElementById('btnRunAll').style.opacity=running?.4:1;
  var bs=document.getElementById('btnStop');
  bs.disabled=!running;bs.classList.toggle('active',running);
  if(d.jobs&&d.jobs.length>0){document.getElementById('livePanel').style.display='';renderLive(d.jobs);}
  if(d.state!=='RUNNING'){
    stopPolling();clearHighlights();
    if(d.state==='DONE') showAlert('success','✓ Pipeline hoàn thành! Dashboard đã cập nhật DWH.',3000);
    else if(d.state==='FAILED') showAlert('error','⚠ Pipeline có lỗi. Xem bảng tiến độ.');
    else if(d.state==='STOPPED') showAlert('info','■ Pipeline đã dừng.');
  }
}

function renderLive(jobs){
  var stC={SUCCESS:'var(--success)',FAILED:'var(--danger)',TIMEOUT:'#B45309',CANCELLED:'var(--light)',RUNNING:'#B45309'};
  var tb=document.getElementById('liveTbody');
  tb.innerHTML=jobs.map(function(r){
    var c=stC[r.state]||'#888';
    var ms=r.ms>0?(r.ms>60000?Math.round(r.ms/1000)+'s':r.ms+'ms'):'—';
    var err=r.error?'<span style="color:var(--danger);font-size:11px;">'+r.error.substring(0,80)+'</span>':'—';
    return '<tr><td style="font-weight:500;color:var(--dark);">'+r.job+'</td>'
      +'<td><span style="background:'+c+'22;color:'+c+';padding:2px 10px;font-size:10px;font-weight:700;letter-spacing:.5px;">'+r.state+'</span></td>'
      +'<td style="text-align:right;">'+(r.rows>0?r.rows.toLocaleString():'—')+'</td>'
      +'<td style="text-align:right;">'+ms+'</td>'
      +'<td>'+err+'</td></tr>';
  }).join('');
}

function highlightJob(name){
  ['DimTimeLoader','DimLocationLoader','DimUserLoader','DimApartmentLoader','FactContractLoader','FactPaymentLoader','AggDailyRevenueJob','AggOccupancyJob'].forEach(function(j){
    var el=document.getElementById('pipe-'+j);
    if(el) el.classList.toggle('running',j===name);
  });
}
function clearHighlights(){document.querySelectorAll('.pnode span').forEach(function(el){el.classList.remove('running');});}

function showAlert(type,msg,autoDismiss){
  var el=document.getElementById('alertBox');
  el.className='etl-alert '+type;el.innerHTML=msg;el.style.display='block';
  if(autoDismiss) setTimeout(function(){el.style.display='none';},autoDismiss);
}
function onRunAll(){startPolling();return true;}
function onStop(){return confirm('Dừng pipeline đang chạy?');}
function runSingleJob(){
  var job=document.getElementById('singleJob').value;
  var f=document.createElement('form');
  f.method='post';f.action='${pageContext.request.contextPath}/admin/etl';
  f.innerHTML='<input name="etlAction" value="runJob"><input name="etlJob" value="'+job+'">';
  document.body.appendChild(f);f.submit();startPolling();
}
pollStatus();
</script>

<%@ include file="../includes/footer.jsp" %>
