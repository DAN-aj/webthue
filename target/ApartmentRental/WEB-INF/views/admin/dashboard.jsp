<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Dashboard — Admin"/>
<%@ include file="../includes/header.jsp" %>

<div class="admin-shell">
  <%@ include file="sidebar.jsp" %>

  <main class="admin-main">

    <%-- Page header --%>
    <div class="admin-header" style="display:flex;align-items:flex-start;justify-content:space-between;gap:16px;">
      <div>
        <h1>Dashboard</h1>
        <p>Nguồn dữ liệu:
          <strong style="color:${dataSource=='DWH'?'#2A6B2A':'#C0392B'};">${dataSource}</strong>
          &nbsp;·&nbsp; ETL gần nhất: <span style="color:var(--mid);">${lastEtlRun}</span>
        </p>
      </div>
      <form method="get" action="${pageContext.request.contextPath}/admin/dashboard"
            style="display:flex;align-items:center;gap:8px;flex-shrink:0;margin-top:4px;">
        <input type="date" name="fromDate" value="${fromDate}"
               style="border:1px solid var(--border);padding:7px 11px;font-size:13px;font-family:var(--sans);background:var(--white);">
        <span style="color:var(--light);">→</span>
        <input type="date" name="toDate" value="${toDate}"
               style="border:1px solid var(--border);padding:7px 11px;font-size:13px;font-family:var(--sans);background:var(--white);">
        <button type="submit" class="btn-approve" style="padding:8px 18px;">Xem báo cáo</button>
        <a href="${pageContext.request.contextPath}/admin/export?fromDate=${fromDate}&toDate=${toDate}"
           target="_blank"
           style="padding:8px 16px;border:1px solid var(--border);background:var(--white);font-size:13px;
                  font-family:var(--sans);cursor:pointer;font-weight:500;color:var(--dark);text-decoration:none;">↓ Xuất PDF</a>
      </form>
    </div>

    <%-- Tab navigation --%>
    <div style="display:flex;border-bottom:2px solid var(--border);margin-bottom:32px;">
      <button class="dash-tab on"  onclick="switchTab(0,this)">Tổng quan</button>
      <button class="dash-tab"     onclick="switchTab(1,this)">Doanh thu</button>
      <button class="dash-tab"     onclick="switchTab(2,this)">Hợp đồng</button>
      <button class="dash-tab"     onclick="switchTab(3,this)">Căn hộ</button>
    </div>

    <style>
      .dash-tab{background:none;border:none;border-bottom:2px solid transparent;margin-bottom:-2px;
        padding:10px 20px;font-family:var(--sans);font-size:13px;font-weight:500;color:var(--light);
        cursor:pointer;letter-spacing:.3px;transition:all .15s;}
      .dash-tab:hover{color:var(--dark);}
      .dash-tab.on{color:var(--dark);border-bottom-color:var(--dark);font-weight:600;}
      .tab-section{display:none;} .tab-section.active{display:block;}
      .krow{display:grid;gap:16px;margin-bottom:20px;}
      .k3{grid-template-columns:repeat(3,1fr);}
      .k4{grid-template-columns:repeat(4,1fr);}
      .k5{grid-template-columns:repeat(5,1fr);}
      .kcard{background:var(--white);border:1px solid var(--border);padding:20px 22px;
        display:flex;align-items:flex-start;justify-content:space-between;gap:10px;}
      .kcard.warn{border-left:3px solid #C0392B;}
      .kcard.ok{border-left:3px solid #2A6B2A;}
      .k-lbl{font-size:10px;font-weight:600;letter-spacing:1.5px;text-transform:uppercase;
        color:var(--light);margin-bottom:8px;}
      .k-val{font-size:26px;font-weight:700;color:var(--dark);line-height:1;letter-spacing:-.5px;}
      .k-val.r{color:#C0392B;} .k-val.g{color:#2A6B2A;}
      .k-sub{font-size:12px;color:var(--light);margin-top:6px;}
      .k-ico{font-size:28px;opacity:0.1;align-self:center;flex-shrink:0;}
      .g2{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px;}
      .g3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;margin-bottom:16px;}
      .g62{display:grid;grid-template-columns:1.65fr 1fr;gap:16px;margin-bottom:16px;}
      .panel{background:var(--white);border:1px solid var(--border);margin-bottom:16px;}
      .panel-head{padding:14px 20px;border-bottom:1px solid var(--border);
        display:flex;align-items:center;justify-content:space-between;}
      .panel-title{font-size:10px;font-weight:700;letter-spacing:1.2px;
        text-transform:uppercase;color:var(--light);}
      .panel-body{padding:20px;}
      .chart-wrap{position:relative;height:170px;}
      .brow{display:flex;align-items:center;gap:9px;margin-bottom:9px;font-size:12px;}
      .blbl{width:130px;flex-shrink:0;color:var(--light);text-align:right;font-size:11px;}
      .btrack{flex:1;background:var(--cream);height:16px;overflow:hidden;}
      .bfill{height:100%;}
      .bval{width:72px;text-align:right;font-size:11px;font-weight:600;color:var(--dark);}
      .bdg{font-size:11px;font-weight:600;padding:3px 9px;}
      .bdg-g{background:#E8F4E8;color:#2A6B2A;}
      .bdg-r{background:#F4E8E8;color:#C0392B;}
      .bdg-a{background:#FEF3E2;color:#B45309;}
      .lgrow{display:flex;align-items:center;gap:8px;}
      .lgdot{width:9px;height:9px;border-radius:50%;flex-shrink:0;}
      .lgnm{font-size:12px;color:var(--light);flex:1;}
      .lgpct{font-size:12px;font-weight:600;color:var(--dark);}
      .al-item{display:flex;align-items:flex-start;gap:12px;padding:12px 0;
        border-bottom:1px solid var(--border);}
      .al-item:last-child{border-bottom:none;}
      .al-ico{width:28px;height:28px;display:flex;align-items:center;
        justify-content:center;font-size:12px;flex-shrink:0;}
      .al-ico.r{background:#F4E8E8;color:#C0392B;}
      .al-ico.a{background:#FEF3E2;color:#B45309;}
      .al-ico.g{background:#E8F4E8;color:#2A6B2A;}
      .al-ico.n{background:var(--cream);color:var(--mid);}
      .al-t{font-size:13px;font-weight:600;color:var(--dark);margin-bottom:3px;}
      .al-d{font-size:12px;color:var(--mid);line-height:1.55;}
      .risk-row{display:flex;justify-content:space-between;padding:12px 0;
        border-bottom:1px solid var(--border);}
      .risk-row:last-child{border-bottom:none;}
      .risk-lbl{font-size:13px;color:var(--mid);}
      .risk-val{font-size:13px;font-weight:700;}
      .no-data{text-align:center;padding:24px;color:var(--light);font-size:13px;}
      .st{display:inline-block;padding:3px 9px;font-size:10px;font-weight:600;}
      .st-active,.st-approved{background:#E8F4E8;color:#2A6B2A;}
      .st-pending{background:#FEF3E2;color:#B45309;}
      .st-terminated,.st-rejected,.st-cancelled{background:#F4E8E8;color:#C0392B;}
      .st-expired,.st-ended{background:var(--cream);color:var(--light);}
      .maph{background:#EAE4DA;height:148px;position:relative;overflow:hidden;}
      .mbub{position:absolute;border-radius:50%;background:rgba(26,26,24,.12);
        border:1.5px solid rgba(26,26,24,.32);display:flex;align-items:center;
        justify-content:center;font-size:9px;font-weight:700;color:var(--dark);}
    </style>

    <%-- ══════════════════════════════════════════════════════
         TAB 0: TỔNG QUAN
    ══════════════════════════════════════════════════════ --%>
    <div class="tab-section active" id="tab-0">

      <div class="krow k3">
        <div class="kcard">
          <div>
            <div class="k-lbl">Tổng người dùng</div>
            <div class="k-val"><fmt:formatNumber value="${totalUsers}" pattern="#,###"/></div>
            <div class="k-sub">Tài khoản đã đăng ký</div>
          </div>
          <div class="k-ico">👤</div>
        </div>
        <div class="kcard">
          <div>
            <div class="k-lbl">Căn hộ hoạt động</div>
            <div class="k-val"><fmt:formatNumber value="${approvedApartments}" pattern="#,###"/></div>
            <div class="k-sub">${pendingApartments} chờ duyệt</div>
          </div>
          <div class="k-ico">🏢</div>
        </div>
        <div class="kcard">
          <div>
            <div class="k-lbl">Tổng hợp đồng</div>
            <div class="k-val"><fmt:formatNumber value="${totalContracts}" pattern="#,###"/></div>
            <div class="k-sub">${activeContracts} đang hiệu lực</div>
          </div>
          <div class="k-ico">📋</div>
        </div>
      </div>

      <div class="krow k4">
        <div class="kcard">
          <div>
            <div class="k-lbl">Tổng phí nền tảng</div>
            <div class="k-val" style="font-size:16px;">
              <fmt:formatNumber value="${totalRevenue}" pattern="#,###"/>đ
            </div>
            <div class="k-sub">Kỳ này: <fmt:formatNumber value="${periodRevenue}" pattern="#,###"/>đ</div>
          </div>
          <div class="k-ico">💰</div>
        </div>
        <div class="kcard">
          <div>
            <div class="k-lbl">Thời gian cho thuê TB</div>
            <div class="k-val">
              <fmt:formatNumber value="${avgDaysToRent}" pattern="#,##0.0"/>
              <span style="font-size:13px;font-weight:400;color:var(--light);"> ngày</span>
            </div>
            <div class="k-sub">Từ đăng tới ký HĐ</div>
          </div>
          <div class="k-ico">⏱</div>
        </div>
        <div class="kcard ok">
          <div>
            <div class="k-lbl">Thanh toán thành công</div>
            <div class="k-val g"><fmt:formatNumber value="${successPayments}" pattern="#,###"/></div>
            <div class="k-sub">${pendingPayments} đang chờ</div>
          </div>
          <div class="k-ico">✅</div>
        </div>
        <div class="kcard warn">
          <div>
            <div class="k-lbl">HĐ pending > 7 ngày</div>
            <div class="k-val r"><fmt:formatNumber value="${overdueContracts}" pattern="#,###"/></div>
            <div class="k-sub">Cần xử lý ngay</div>
          </div>
          <div class="k-ico">⚠</div>
        </div>
      </div>

      <div class="g62">
        <div class="panel">
          <div class="panel-head">
            <span class="panel-title">Doanh thu theo tháng</span>
            <span class="bdg bdg-g" id="revGrowthBadge">...</span>
          </div>
          <div class="panel-body">
            <div class="chart-wrap"><canvas id="revenueChart"></canvas></div>
          </div>
        </div>
        <div class="panel">
          <div class="panel-head"><span class="panel-title">Loại hợp đồng</span></div>
          <div class="panel-body">
            <div class="chart-wrap" style="height:120px;"><canvas id="rentalTypeChart"></canvas></div>
            <div id="rentalTypeLegend" style="margin-top:12px;display:flex;flex-direction:column;gap:7px;"></div>
          </div>
        </div>
      </div>

      <div class="g2">
        <div class="panel">
          <div class="panel-head">
            <span class="panel-title">Doanh thu theo quận — Top 5</span>
            <span class="bdg bdg-a">Tích lũy</span>
          </div>
          <div class="panel-body" id="districtBarsOverview"></div>
        </div>
        <div class="panel">
          <div class="panel-head"><span class="panel-title">🔍 Nhận định tự động</span></div>
          <div class="panel-body">
            <c:choose>
              <c:when test="${overdueContracts > 10}">
                <div class="al-item">
                  <div class="al-ico r">↓</div>
                  <div>
                    <div class="al-t">Có <fmt:formatNumber value="${overdueContracts}" pattern="#,###"/> hợp đồng pending quá 7 ngày</div>
                    <div class="al-d">Cần admin phê duyệt hoặc từ chối để tránh tắc nghẽn luồng Escrow.</div>
                  </div>
                </div>
              </c:when>
              <c:otherwise>
                <div class="al-item">
                  <div class="al-ico g">↑</div>
                  <div>
                    <div class="al-t">Luồng hợp đồng thông suốt</div>
                    <div class="al-d">Số hợp đồng pending quá hạn ở mức thấp. Hệ thống đang vận hành ổn định.</div>
                  </div>
                </div>
              </c:otherwise>
            </c:choose>
            <c:if test="${pendingApartments > 50}">
              <div class="al-item">
                <div class="al-ico a">!</div>
                <div>
                  <div class="al-t"><fmt:formatNumber value="${pendingApartments}" pattern="#,###"/> căn hộ đang chờ duyệt</div>
                  <div class="al-d">Nên ưu tiên duyệt các căn hộ ở khu vực có occupancy rate cao.</div>
                </div>
              </div>
            </c:if>
            <c:if test="${moveInRate < 10}">
              <div class="al-item">
                <div class="al-ico a">!</div>
                <div>
                  <div class="al-t">Tỷ lệ xác nhận vào nhà: <fmt:formatNumber value="${moveInRate}" pattern="#,##0.0"/>%</div>
                  <div class="al-d">Move-in confirmation rate thấp bất thường. Kiểm tra luồng xác nhận.</div>
                </div>
              </div>
            </c:if>
            <div class="al-item">
              <div class="al-ico n">i</div>
              <div>
                <div class="al-t">Nguồn dữ liệu: ${dataSource}</div>
                <div class="al-d">ETL gần nhất: ${lastEtlRun}. Kỳ: ${fromDate} — ${toDate}.</div>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div><%-- /tab-0 --%>

    <%-- ══════════════════════════════════════════════════════
         TAB 1: DOANH THU
    ══════════════════════════════════════════════════════ --%>
    <div class="tab-section" id="tab-1">

      <div class="krow k3">
        <div class="kcard">
          <div>
            <div class="k-lbl">Tổng phí nền tảng</div>
            <div class="k-val" style="font-size:17px;"><fmt:formatNumber value="${totalRevenue}" pattern="#,###"/>đ</div>
            <div class="k-sub">Tích lũy toàn thời gian</div>
          </div>
        </div>
        <div class="kcard">
          <div>
            <div class="k-lbl">Phí kỳ này</div>
            <div class="k-val" style="font-size:17px;"><fmt:formatNumber value="${periodRevenue}" pattern="#,###"/>đ</div>
            <div class="k-sub">${fromDate} — ${toDate}</div>
          </div>
        </div>
        <div class="kcard ok">
          <div>
            <div class="k-lbl">Thanh toán thành công</div>
            <div class="k-val g"><fmt:formatNumber value="${successPayments}" pattern="#,###"/></div>
            <div class="k-sub">${pendingPayments} đang chờ xử lý</div>
          </div>
        </div>
      </div>

      <div class="g3">
        <div class="panel">
          <div class="panel-head"><span class="panel-title">Doanh thu theo quận</span></div>
          <div class="panel-body" id="districtBarsRevenue"></div>
        </div>
        <div class="panel">
          <div class="panel-head"><span class="panel-title">Xu hướng 12 tháng</span></div>
          <div class="panel-body">
            <div class="chart-wrap"><canvas id="revTrendChart"></canvas></div>
          </div>
        </div>
        <div class="panel">
          <div class="panel-head"><span class="panel-title">Loại hợp đồng</span></div>
          <div class="panel-body">
            <div class="chart-wrap" style="height:130px;"><canvas id="rentalTypeChart2"></canvas></div>
          </div>
        </div>
      </div>

      <div class="panel">
        <div class="panel-head"><span class="panel-title">Top 5 căn hộ được thuê nhiều nhất</span></div>
        <table style="width:100%;border-collapse:collapse;font-size:13px;">
          <thead><tr>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">#</th>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Tên căn hộ</th>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Khu vực</th>
            <th style="padding:10px 16px;text-align:right;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Số HĐ</th>
          </tr></thead>
          <tbody>
            <c:forEach var="apt" items="${topApartments}" varStatus="s">
              <tr>
                <td style="padding:10px 16px;font-weight:700;color:var(--light);border-bottom:1px solid var(--border);">${s.index+1}</td>
                <td style="padding:10px 16px;font-weight:600;border-bottom:1px solid var(--border);">${apt[0]}</td>
                <td style="padding:10px 16px;color:var(--mid);border-bottom:1px solid var(--border);">${apt[2]}</td>
                <td style="padding:10px 16px;text-align:right;font-weight:700;border-bottom:1px solid var(--border);">${apt[1]}</td>
              </tr>
            </c:forEach>
            <c:if test="${empty topApartments}">
              <tr><td colspan="4" class="no-data">Chưa có dữ liệu</td></tr>
            </c:if>
          </tbody>
        </table>
      </div>

    </div><%-- /tab-1 --%>

    <%-- ══════════════════════════════════════════════════════
         TAB 2: HỢP ĐỒNG
    ══════════════════════════════════════════════════════ --%>
    <div class="tab-section" id="tab-2">

      <div class="krow k5">
        <div class="kcard"><div><div class="k-lbl">Tổng hợp đồng</div><div class="k-val"><fmt:formatNumber value="${totalContracts}" pattern="#,###"/></div><div class="k-sub">All time</div></div></div>
        <div class="kcard ok"><div><div class="k-lbl">Đang hiệu lực</div><div class="k-val g"><fmt:formatNumber value="${activeContracts}" pattern="#,###"/></div><div class="k-sub">Active</div></div></div>
        <div class="kcard warn"><div><div class="k-lbl">Pending > 7 ngày</div><div class="k-val r"><fmt:formatNumber value="${overdueContracts}" pattern="#,###"/></div><div class="k-sub">Cần xử lý ngay</div></div></div>
        <div class="kcard"><div><div class="k-lbl">Thời gian TB</div><div class="k-val"><fmt:formatNumber value="${avgDaysToRent}" pattern="#,##0.0"/><span style="font-size:12px;font-weight:400;color:var(--light);"> ngày</span></div><div class="k-sub">Đăng tới ký HĐ</div></div></div>
        <div class="kcard"><div><div class="k-lbl">Xác nhận vào nhà</div><div class="k-val ${moveInRate < 10 ? 'r' : 'g'}"><fmt:formatNumber value="${moveInRate}" pattern="#,##0.0"/>%</div><div class="k-sub">Move-in rate</div></div></div>
      </div>

      <div class="g2">
        <div class="panel">
          <div class="panel-head"><span class="panel-title">Trạng thái hợp đồng</span></div>
          <div class="panel-body">
            <div class="chart-wrap" style="height:160px;"><canvas id="contractStatusChart"></canvas></div>
          </div>
        </div>
        <div class="panel">
          <div class="panel-head"><span class="panel-title">Hợp đồng mới theo tháng</span></div>
          <div class="panel-body">
            <div class="chart-wrap" style="height:160px;"><canvas id="contractByMonthChart"></canvas></div>
          </div>
        </div>
      </div>

      <div class="panel" style="margin-bottom:16px;">
        <div class="panel-head"><span class="panel-title">Danh sách hợp đồng gần đây</span></div>
        <table style="width:100%;border-collapse:collapse;font-size:13px;">
          <thead><tr>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Contract ID</th>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Căn hộ</th>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Quận</th>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Loại thuê</th>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Giá/tháng</th>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Ngày ký</th>
            <th style="padding:10px 16px;text-align:left;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:var(--light);background:var(--cream);border-bottom:1px solid var(--border);">Trạng thái</th>
          </tr></thead>
          <tbody id="recentContractsTbody">
            <tr><td colspan="7" class="no-data">Đang tải...</td></tr>
          </tbody>
        </table>
      </div>

      <div class="panel">
        <div class="panel-head"><span class="panel-title">Tóm tắt rủi ro vận hành</span></div>
        <div class="panel-body">
          <div class="risk-row"><span class="risk-lbl">HĐ pending quá 7 ngày</span><span class="risk-val" style="color:${overdueContracts > 10 ? '#C0392B' : '#2A6B2A'};"><fmt:formatNumber value="${overdueContracts}" pattern="#,###"/></span></div>
          <div class="risk-row"><span class="risk-lbl">Tỷ lệ xác nhận vào nhà</span><span class="risk-val" style="color:${moveInRate < 10 ? '#C0392B' : '#2A6B2A'};"><fmt:formatNumber value="${moveInRate}" pattern="#,##0.0"/>%</span></div>
          <div class="risk-row"><span class="risk-lbl">Thanh toán đang chờ</span><span class="risk-val"><fmt:formatNumber value="${pendingPayments}" pattern="#,###"/></span></div>
          <div class="risk-row"><span class="risk-lbl">Căn hộ chờ duyệt</span><span class="risk-val"><fmt:formatNumber value="${pendingApartments}" pattern="#,###"/></span></div>
        </div>
      </div>

    </div><%-- /tab-2 --%>

    <%-- ══════════════════════════════════════════════════════
         TAB 3: CĂN HỘ
    ══════════════════════════════════════════════════════ --%>
    <div class="tab-section" id="tab-3">

      <div class="krow k4">
        <div class="kcard"><div><div class="k-lbl">Tổng căn hộ</div><div class="k-val"><fmt:formatNumber value="${totalApartments}" pattern="#,###"/></div><div class="k-sub"><fmt:formatNumber value="${approvedApartments}" pattern="#,###"/> đã duyệt</div></div><div class="k-ico">🏢</div></div>
        <div class="kcard warn"><div><div class="k-lbl">Chờ kiểm duyệt</div><div class="k-val r"><fmt:formatNumber value="${pendingApartments}" pattern="#,###"/></div><div class="k-sub">Cần duyệt ưu tiên</div></div></div>
        <div class="kcard ok"><div><div class="k-lbl">Hợp đồng active</div><div class="k-val g"><fmt:formatNumber value="${activeContracts}" pattern="#,###"/></div><div class="k-sub">Đang cho thuê</div></div></div>
        <div class="kcard"><div><div class="k-lbl">Tổng hợp đồng</div><div class="k-val"><fmt:formatNumber value="${totalContracts}" pattern="#,###"/></div><div class="k-sub">All time</div></div></div>
      </div>

      <div class="g62">
        <div class="panel">
          <div class="panel-head"><span class="panel-title">Phân bố căn hộ theo quận</span></div>
          <div class="panel-body" style="padding:0;">
            <div class="maph">
              <svg viewBox="0 0 400 148" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
                <rect width="400" height="148" fill="#EAE4DA"/>
                <ellipse cx="100" cy="74" rx="58" ry="36" fill="#DDD6CC" stroke="#C8C0B4" stroke-width="0.8"/>
                <ellipse cx="230" cy="66" rx="68" ry="42" fill="#DDD6CC" stroke="#C8C0B4" stroke-width="0.8"/>
                <ellipse cx="328" cy="98" rx="44" ry="29" fill="#DDD6CC" stroke="#C8C0B4" stroke-width="0.8"/>
                <ellipse cx="170" cy="120" rx="48" ry="22" fill="#DDD6CC" stroke="#C8C0B4" stroke-width="0.8"/>
                <text x="100" y="71" text-anchor="middle" fill="#888880" font-size="8" font-family="Be Vietnam Pro,sans-serif">Cầu Giấy</text>
                <text x="230" y="63" text-anchor="middle" fill="#888880" font-size="8" font-family="Be Vietnam Pro,sans-serif">Đống Đa</text>
                <text x="328" y="95" text-anchor="middle" fill="#888880" font-size="8" font-family="Be Vietnam Pro,sans-serif">Hoàn Kiếm</text>
                <text x="170" y="117" text-anchor="middle" fill="#888880" font-size="8" font-family="Be Vietnam Pro,sans-serif">Hai Bà Trưng</text>
              </svg>
              <div class="mbub" id="occBub0" style="width:38px;height:38px;left:80px;top:54px;"></div>
              <div class="mbub" id="occBub1" style="width:48px;height:48px;left:205px;top:40px;"></div>
              <div class="mbub" id="occBub2" style="width:30px;height:30px;left:312px;top:82px;"></div>
              <div class="mbub" id="occBub3" style="width:34px;height:34px;left:152px;top:102px;"></div>
            </div>
          </div>
        </div>
        <div class="panel">
          <div class="panel-head"><span class="panel-title">Occupancy rate theo quận</span></div>
          <div class="panel-body" id="occupancyBars"></div>
        </div>
      </div>

      <div class="panel">
        <div class="panel-head"><span class="panel-title">Số căn hộ TB mỗi chủ nhà theo quận</span></div>
        <div class="panel-body">
          <div class="chart-wrap"><canvas id="avgAptChart"></canvas></div>
        </div>
      </div>

    </div><%-- /tab-3 --%>

  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
var REV_DATA   = ${revenueByMonthJson};
var DIST_DATA  = ${revenueByDistrictJson};
var CTR_DATA   = ${contractsByMonthJson};
var OCC_DATA   = ${occupancyJson};
var RTYPE_DATA = ${rentalTypeJson};
var CSTAT_DATA = ${contractStatusJson};
var AVG_DATA   = ${avgAptPerOwnerJson};
var CONTRACTS  = ${recentContractsJson};

function fmtMil(v){ if(v>=1e9)return(v/1e9).toFixed(1)+'T'; if(v>=1e6)return(v/1e6).toFixed(1)+'M'; if(v>=1e3)return(v/1e3).toFixed(0)+'K'; return v; }
function fmtNum(v){ return new Intl.NumberFormat('vi-VN').format(Math.round(v)); }
function fmtDate(s){ return s?s.toString().substring(0,16).replace('T',' '):'—'; }

var ST_COLOR={active:'#2A6B2A',approved:'#2A6B2A',pending:'#B45309',expired:'#888880',ended:'#888880',terminated:'#C0392B',rejected:'#C0392B',cancelled:'#C0392B'};
var ST_LABEL={active:'Hiệu lực',approved:'Đã duyệt',pending:'Chờ duyệt',expired:'Kết thúc',ended:'Kết thúc',terminated:'Đã hủy',rejected:'Từ chối',cancelled:'Đã hủy'};
var PIE_COLORS=['#1A1A18','#C0392B','#2A6B2A','#B45309','#6B3FA0','#2563EB'];

Chart.defaults.font.family="'Be Vietnam Pro','Segoe UI',sans-serif";
Chart.defaults.font.size=11;

function renderBars(containerId, data, limit, colorFn){
  var el=document.getElementById(containerId);
  if(!el) return;
  if(!data||!data.labels||!data.labels.length){ el.innerHTML='<div class="no-data">Chưa có dữ liệu</div>'; return; }
  var labels=data.labels.slice(0,limit||8), vals=data.data.slice(0,limit||8);
  var maxVal=Math.max.apply(null,vals.concat([1]));
  el.innerHTML=labels.map(function(lbl,i){
    var val=vals[i]||0, pct=Math.round(val/maxVal*100);
    var color=colorFn?colorFn(val,i):'#1A1A18';
    var opacity=Math.max(0.3,1-i*0.1);
    return '<div class="brow"><span class="blbl">'+lbl+'</span>'+
      '<div class="btrack"><div class="bfill" style="width:'+pct+'%;background:'+color+';opacity:'+opacity+';"></div></div>'+
      '<span class="bval">'+fmtMil(val)+'</span></div>';
  }).join('');
}

// ── TAB 0 ──────────────────────────────────────────────────────────────
if(REV_DATA&&REV_DATA.labels&&REV_DATA.labels.length){
  var d=REV_DATA.data;
  var gr=d.length>1&&d[0]>0?((d[d.length-1]-d[0])/d[0]*100).toFixed(1):0;
  var gbadge=document.getElementById('revGrowthBadge');
  if(gbadge) gbadge.textContent=(gr>=0?'▲':'▼')+Math.abs(gr)+'% trong kỳ';
  new Chart('revenueChart',{data:{labels:REV_DATA.labels,datasets:[
    {type:'bar',data:d,backgroundColor:'rgba(26,26,24,0.72)',borderRadius:2},
    {type:'line',data:d,borderColor:'#C0392B',borderWidth:1.8,tension:0.4,pointRadius:3,pointBackgroundColor:'#C0392B',fill:false}
  ]},options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},
    scales:{y:{beginAtZero:true,ticks:{callback:fmtMil},grid:{color:'rgba(0,0,0,0.04)'}},x:{grid:{display:false}}}}});
}
if(RTYPE_DATA&&RTYPE_DATA.labels&&RTYPE_DATA.labels.length){
  var total=RTYPE_DATA.data.reduce(function(a,b){return a+b;},0);
  new Chart('rentalTypeChart',{type:'doughnut',
    data:{labels:RTYPE_DATA.labels,datasets:[{data:RTYPE_DATA.data,backgroundColor:PIE_COLORS,borderWidth:0}]},
    options:{responsive:true,maintainAspectRatio:false,cutout:'68%',plugins:{legend:{display:false}}}});
  var leg=document.getElementById('rentalTypeLegend');
  if(leg) leg.innerHTML=RTYPE_DATA.labels.map(function(l,i){
    var pct=total>0?Math.round(RTYPE_DATA.data[i]/total*100):0;
    return '<div class="lgrow"><div class="lgdot" style="background:'+PIE_COLORS[i]+';"></div>'+
      '<span class="lgnm">'+l+'</span><span class="lgpct">'+pct+'%</span></div>';
  }).join('');
}
renderBars('districtBarsOverview',DIST_DATA,5,null);

// ── TAB 1 ──────────────────────────────────────────────────────────────
renderBars('districtBarsRevenue',DIST_DATA,8,null);
if(REV_DATA&&REV_DATA.labels&&REV_DATA.labels.length){
  new Chart('revTrendChart',{type:'line',
    data:{labels:REV_DATA.labels,datasets:[{data:REV_DATA.data,borderColor:'#1A1A18',borderWidth:1.6,tension:0.4,pointRadius:2,fill:true,backgroundColor:'rgba(26,26,24,0.06)'}]},
    options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},
      scales:{y:{beginAtZero:true,ticks:{callback:fmtMil},grid:{color:'rgba(0,0,0,0.04)'}},x:{grid:{display:false}}}}});
}
if(RTYPE_DATA&&RTYPE_DATA.labels&&RTYPE_DATA.labels.length){
  new Chart('rentalTypeChart2',{type:'doughnut',
    data:{labels:RTYPE_DATA.labels,datasets:[{data:RTYPE_DATA.data,backgroundColor:PIE_COLORS,borderWidth:0}]},
    options:{responsive:true,maintainAspectRatio:false,cutout:'60%',
      plugins:{legend:{position:'bottom',labels:{font:{size:10},boxWidth:10}}}}});
}

// ── TAB 2 ──────────────────────────────────────────────────────────────
if(CSTAT_DATA&&CSTAT_DATA.labels&&CSTAT_DATA.labels.length){
  new Chart('contractStatusChart',{type:'doughnut',
    data:{labels:CSTAT_DATA.labels.map(function(l){return ST_LABEL[l]||l;}),
          datasets:[{data:CSTAT_DATA.data,backgroundColor:CSTAT_DATA.labels.map(function(l){return ST_COLOR[l]||'#ccc';}),borderWidth:0}]},
    options:{responsive:true,maintainAspectRatio:false,cutout:'55%',
      plugins:{legend:{position:'right',labels:{font:{size:10},boxWidth:10}}}}});
}
if(CTR_DATA&&CTR_DATA.labels&&CTR_DATA.labels.length){
  new Chart('contractByMonthChart',{type:'bar',
    data:{labels:CTR_DATA.labels,datasets:[{data:CTR_DATA.data,backgroundColor:'rgba(26,26,24,.7)',borderRadius:2}]},
    options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},
      scales:{y:{beginAtZero:true,grid:{color:'rgba(0,0,0,0.04)'}},x:{grid:{display:false}}}}});
}
(function(){
  var tbody=document.getElementById('recentContractsTbody');
  if(!tbody||!CONTRACTS||!CONTRACTS.length){
    if(tbody) tbody.innerHTML='<tr><td colspan="7" class="no-data">Chưa có dữ liệu</td></tr>';
    return;
  }
  tbody.innerHTML=CONTRACTS.map(function(c){
    var stKey=c.status||'';
    return '<tr>'+
      '<td style="padding:10px 16px;color:var(--light);border-bottom:1px solid var(--border);">#HD-'+c.id+'</td>'+
      '<td style="padding:10px 16px;font-weight:600;border-bottom:1px solid var(--border);">'+(c.apt||'—')+'</td>'+
      '<td style="padding:10px 16px;border-bottom:1px solid var(--border);">'+(c.district||'—')+'</td>'+
      '<td style="padding:10px 16px;border-bottom:1px solid var(--border);">'+(c.type||'—')+'</td>'+
      '<td style="padding:10px 16px;border-bottom:1px solid var(--border);">'+(c.rent?fmtNum(c.rent)+'đ':'—')+'</td>'+
      '<td style="padding:10px 16px;color:var(--light);border-bottom:1px solid var(--border);">'+fmtDate(c.date)+'</td>'+
      '<td style="padding:10px 16px;border-bottom:1px solid var(--border);"><span class="st st-'+stKey+'">'+(ST_LABEL[stKey]||stKey)+'</span></td>'+
    '</tr>';
  }).join('');
})();

// ── TAB 3 ──────────────────────────────────────────────────────────────
if(OCC_DATA&&OCC_DATA.labels&&OCC_DATA.labels.length){
  var occMax=Math.max.apply(null,OCC_DATA.data.concat([1]));
  var occHtml=OCC_DATA.labels.slice(0,6).map(function(lbl,i){
    var val=OCC_DATA.data[i]||0, pct=Math.round(val/occMax*100);
    var color=val>=80?'#2A6B2A':val>=70?'#B45309':'#C0392B';
    return '<div class="brow">'+
      '<span class="blbl">'+lbl+'</span>'+
      '<div class="btrack"><div class="bfill" style="width:'+pct+'%;background:'+color+';"></div></div>'+
      '<span class="bval" style="color:'+color+';">'+val+'%</span></div>';
  }).join('');
  occHtml+='<div style="margin-top:12px;padding-top:12px;border-top:1px solid var(--border);font-size:12px;color:var(--light);">Target: <strong style="color:var(--dark);">80%</strong></div>';
  var occEl=document.getElementById('occupancyBars');
  if(occEl) occEl.innerHTML=occHtml;
  ['occBub0','occBub1','occBub2','occBub3'].forEach(function(id,i){
    var el=document.getElementById(id);
    if(el&&OCC_DATA.data[i]!=null) el.textContent=OCC_DATA.data[i]+'%';
  });
}
if(AVG_DATA&&AVG_DATA.labels&&AVG_DATA.labels.length){
  new Chart('avgAptChart',{type:'bar',
    data:{labels:AVG_DATA.labels,datasets:[{data:AVG_DATA.data,backgroundColor:'rgba(26,26,24,.65)',borderRadius:2}]},
    options:{indexAxis:'y',responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},
      scales:{x:{beginAtZero:true,grid:{color:'rgba(0,0,0,0.04)'}},y:{grid:{display:false}}}}});
}

// ── Tab switcher ────────────────────────────────────────────────────────
function switchTab(i,el){
  document.querySelectorAll('.tab-section').forEach(function(t,j){ t.classList.toggle('active',j===i); });
  document.querySelectorAll('.dash-tab').forEach(function(b){ b.classList.toggle('on',b===el); });
}
</script>


<script>
/* Admin nav dropdown */
(function(){
  var btn  = document.getElementById("avatarBtn");
  var drop = document.getElementById("navDrop");
  if (!btn || !drop) return;
  btn.addEventListener("click", function(e){
    e.stopPropagation();
    drop.classList.toggle("open");
  });
  drop.addEventListener("click", function(e){ e.stopPropagation(); });
  document.addEventListener("click", function(){ drop.classList.remove("open"); });
  /* Hamburger */
  var ham  = document.getElementById("hamburger");
  var menu = document.getElementById("navMenu");
  if (ham && menu) {
    ham.addEventListener("click", function(e){
      e.stopPropagation();
      menu.classList.toggle("open");
    });
    document.addEventListener("click", function(){ menu.classList.remove("open"); });
  }
  /* Auto-dismiss alerts */
  document.querySelectorAll(".auto-dismiss").forEach(function(a){
    setTimeout(function(){ a.style.opacity="0"; a.style.transition="opacity .4s"; setTimeout(function(){ a.remove(); },400); }, 4000);
  });
})();
</script>
</body>
</html>
