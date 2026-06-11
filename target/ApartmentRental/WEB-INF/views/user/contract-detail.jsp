<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Hop Dong #${contract.contractId} — ChungCu.vn"/>
<%@ include file="../includes/header.jsp" %>

<div class="page-strip">
  <div style="padding:60px 80px;">
    <span class="eyebrow">Hop dong #${contract.contractId}</span>
    <h1>Chi tiet hop dong</h1>
  </div>
</div>

<div class="container" style="max-width:960px;padding-bottom:80px;">

  <%-- Thong bao --%>
  <c:if test="${param.success=='requested'}">
    <div class="alert alert-success auto-dismiss" style="margin-top:24px;">
      Da gui yeu cau thue! Cho chu nha xac nhan trong 24 gio.
    </div>
  </c:if>
  <c:if test="${param.success=='confirmed'}">
    <div class="alert alert-success auto-dismiss" style="margin-top:24px;">
      🏠 Da xac nhan nhan nha thanh cong! Hop dong hoan tat. Escrow se giai phong tien trong 24 gio.
    </div>
  </c:if>
  <c:if test="${param.success=='approved'}">
    <div class="alert alert-success auto-dismiss" style="margin-top:24px;">
      Da xac nhan yeu cau! Nguoi thue se tien hanh thanh toan.
    </div>
  </c:if>
  <c:if test="${param.error=='use_form'}">
    <div class="alert alert-warning auto-dismiss" style="margin-top:24px;">
      Vui long su dung nut "Chap nhan yeu cau" tren trang nay de xac nhan hop dong.
    </div>
  </c:if>

  <%-- ESCROW STEPPER --%>
  <div style="background:var(--white);border:1px solid var(--border);padding:28px 32px;margin-top:36px;margin-bottom:24px;">
    <p style="font-size:10.5px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:22px;">
      Trang thai Escrow
    </p>
    <c:set var="s" value="${contract.status}"/>
    <div style="display:flex;align-items:flex-start;">

      <div style="flex:1;text-align:center;">
        <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--success);color:#fff;font-size:14px;">✓</div>
        <span style="font-size:10px;color:var(--light);text-transform:uppercase;letter-spacing:1px;">Gui yeu cau</span>
      </div>

      <div style="flex:1;height:2px;margin-top:18px;
        <c:choose>
          <c:when test="${s!='pending'}">background:var(--success);</c:when>
          <c:otherwise>background:var(--border);</c:otherwise>
        </c:choose>
      "></div>

      <div style="flex:1;text-align:center;">
        <c:choose>
          <c:when test="${contract.moveInConfirmed}">
            <%-- Đã xác nhận nhận nhà → xanh lá --%>
            <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--success);color:#fff;font-size:14px;">🏠</div>
          </c:when>
          <c:when test="${s=='active'}">
            <%-- Đang active nhưng chưa xác nhận nhận nhà → vàng cam, đang chờ --%>
            <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--accent);color:#fff;font-size:14px;">🏠</div>
          </c:when>
          <c:otherwise>
            <%-- Chưa đến bước này → xám --%>
            <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--border);color:var(--light);font-size:14px;">🏠</div>
          </c:otherwise>
        </c:choose>
        <span style="font-size:10px;color:var(--light);text-transform:uppercase;letter-spacing:1px;">Nhan nha</span>
      </div>

      <div style="flex:1;height:2px;margin-top:18px;
        <c:choose>
          <c:when test="${s=='active'||s=='expired'}">background:var(--success);</c:when>
          <c:otherwise>background:var(--border);</c:otherwise>
        </c:choose>
      "></div>

      <div style="flex:1;text-align:center;">
        <c:choose>
          <c:when test="${s=='active'||s=='expired'}">
            <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--success);color:#fff;font-size:14px;">🔒</div>
          </c:when>
          <c:otherwise>
            <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--border);color:var(--light);font-size:14px;">🔒</div>
          </c:otherwise>
        </c:choose>
        <span style="font-size:10px;color:var(--light);text-transform:uppercase;letter-spacing:1px;">Giu tien Escrow</span>
      </div>

      <div style="flex:1;height:2px;margin-top:18px;
        <c:choose>
          <c:when test="${s=='active'||s=='expired'}">background:var(--success);</c:when>
          <c:otherwise>background:var(--border);</c:otherwise>
        </c:choose>
      "></div>

      <div style="flex:1;text-align:center;">
        <c:choose>
          <c:when test="${s=='expired'}">
            <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--success);color:#fff;font-size:14px;">🏠</div>
          </c:when>
          <c:when test="${s=='active'}">
            <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--accent);color:#fff;font-size:14px;">🏠</div>
          </c:when>
          <c:otherwise>
            <div style="width:38px;height:38px;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;background:var(--border);color:var(--light);font-size:14px;">🏠</div>
          </c:otherwise>
        </c:choose>
        <span style="font-size:10px;color:var(--light);text-transform:uppercase;letter-spacing:1px;">Nhan nha</span>
      </div>

    </div>
  </div>

  <div style="display:grid;grid-template-columns:1fr 300px;gap:24px;align-items:start;">

    <%-- LEFT --%>
    <div>
      <%-- Anh can ho --%>
      <div style="display:flex;gap:16px;background:var(--cream);border:1px solid var(--border);padding:18px;margin-bottom:20px;">
        <img src="https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=200"
             alt="" style="width:110px;height:74px;object-fit:cover;flex-shrink:0;">
        <div>
          <div style="font-family:var(--serif);font-size:16px;font-weight:700;margin-bottom:6px;">${contract.aptTitle}</div>
          <a href="${pageContext.request.contextPath}/apartment/${contract.aptId}"
             style="font-size:12px;color:var(--accent);letter-spacing:1px;text-transform:uppercase;">Xem can ho</a>
        </div>
      </div>

      <%-- Thong tin hop dong va cac ben --%>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px;">

        <%-- Hop dong --%>
        <div style="background:var(--white);border:1px solid var(--border);padding:22px;">
          <p style="font-size:10px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:14px;">Hop dong</p>
          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Loai thue</span>
            <span style="font-weight:600;font-size:13px;">${contract.rentalTypeLabel}</span>
          </div>
          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Bat dau</span>
            <span style="font-weight:600;font-size:13px;"><fmt:formatDate value="${contract.startDate}" pattern="dd/MM/yyyy"/></span>
          </div>
          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Ket thuc</span>
            <span style="font-weight:600;font-size:13px;"><fmt:formatDate value="${contract.endDate}" pattern="dd/MM/yyyy"/></span>
          </div>
          <%-- Don gia: ngay hoac thang tuy loai thue --%>
          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">
              <c:choose>
                <c:when test="${contract.rentalType=='short'}">Don gia / ngay</c:when>
                <c:otherwise>Don gia / thang</c:otherwise>
              </c:choose>
            </span>
            <span style="font-weight:700;font-family:var(--serif);font-size:15px;color:var(--accent);">
              <fmt:formatNumber value="${contract.monthlyRent}" pattern="#,###"/>
              <c:choose>
                <c:when test="${contract.rentalType=='short'}"> d/ngay</c:when>
                <c:otherwise> d/thang</c:otherwise>
              </c:choose>
            </span>
          </div>

          <%-- So ngay / so thang --%>
          <c:choose>
            <c:when test="${contract.rentalType=='short'}">
              <div class="ps-row">
                <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">So ngay thue</span>
                <span style="font-weight:600;font-size:13px;">${contract.totalDays} ngay</span>
              </div>
            </c:when>
            <c:otherwise>
              <div class="ps-row">
                <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Thoi han</span>
                <span style="font-weight:600;font-size:13px;">${contract.totalDays} ngay</span>
              </div>
            </c:otherwise>
          </c:choose>

          <%-- Tong tien thue (quan trong voi chu nha) --%>
          <div class="ps-row" style="background:#fdf8ee;margin:4px -4px;padding:10px 4px;border-bottom:1px solid var(--border);">
            <span style="font-size:11px;color:var(--accent);text-transform:uppercase;letter-spacing:.5px;font-weight:700;">Tong tien thue</span>
            <span style="font-weight:700;font-family:var(--serif);font-size:16px;color:var(--dark);">
              <fmt:formatNumber value="${contract.totalRent}" pattern="#,###"/> d
            </span>
          </div>

          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Tien coc</span>
            <span style="font-weight:600;font-size:13px;"><fmt:formatNumber value="${contract.depositAmount}" pattern="#,###"/> d</span>
          </div>
          <div class="ps-row" style="border:none;">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Phi nen tang</span>
            <span style="font-weight:600;font-size:13px;"><fmt:formatNumber value="${contract.platformFee}" pattern="#,###"/> d</span>
          </div>
        </div>

        <%-- Cac ben --%>
        <div style="background:var(--white);border:1px solid var(--border);padding:22px;">
          <p style="font-size:10px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:14px;">Cac ben</p>
          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Nguoi thue</span>
            <span style="font-weight:600;font-size:13px;">${contract.tenantName}</span>
          </div>
          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">CCCD</span>
            <span style="font-size:12px;">${contract.tenantCccd}</span>
          </div>
          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">SDT nguoi thue</span>
            <c:choose>
              <c:when test="${contract.status=='active' || contract.status=='expired'}">
                <span style="font-size:13px;">${contract.tenantPhone}</span>
              </c:when>
              <c:otherwise>
                <span style="font-size:13px;font-style:italic;color:var(--light);">An</span>
              </c:otherwise>
            </c:choose>
          </div>
          <div class="ps-row">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">Chu nha</span>
            <span style="font-weight:600;font-size:13px;">${contract.ownerName}</span>
          </div>
          <div class="ps-row" style="border:none;">
            <span style="font-size:11px;color:var(--light);text-transform:uppercase;letter-spacing:.5px;">SDT chu nha</span>
            <c:choose>
              <c:when test="${contract.status=='active' || contract.status=='expired'}">
                <span style="font-size:13px;">${contract.ownerPhone}</span>
              </c:when>
              <c:otherwise>
                <span style="font-size:13px;font-style:italic;color:var(--light);">An</span>
              </c:otherwise>
            </c:choose>
          </div>
        </div>

      </div>

      <%-- Lich su thanh toan --%>
      <c:if test="${not empty payments}">
        <div style="background:var(--white);border:1px solid var(--border);">
          <div class="table-head"><h3>Lich su giao dich Escrow</h3></div>
          <table>
            <thead>
              <tr>
                <th>Loai</th><th>So tien</th><th>Phuong thuc</th>
                <th>Ma GD</th><th>Ngay</th><th>TT</th>
              </tr>
            </thead>
            <tbody>
              <c:forEach var="p" items="${payments}">
                <tr>
                  <td>
                    <c:choose>
                      <c:when test="${p.paymentType=='initial'}">Dot dau</c:when>
                      <c:when test="${p.paymentType=='periodic'}">Ky ${p.periodMonth}</c:when>
                      <c:otherwise>${p.paymentType}</c:otherwise>
                    </c:choose>
                  </td>
                  <td style="font-family:var(--serif);font-size:15px;font-weight:700;">
                    <fmt:formatNumber value="${p.amount}" pattern="#,###"/> d
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${p.paymentMethod=='bank_qr'}">Ngan hang QR</c:when>
                      <c:when test="${p.paymentMethod=='card'}">The</c:when>
                      <c:otherwise>${p.paymentMethod}</c:otherwise>
                    </c:choose>
                  </td>
                  <td><code style="font-size:11px;">${p.transactionCode}</code></td>
                  <td style="font-size:12px;">
                    <fmt:formatDate value="${p.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${p.status=='success'}">
                        <span class="badge badge-green">Thanh cong</span>
                      </c:when>
                      <c:when test="${p.status=='pending'}">
                        <span class="badge badge-amber">Dang xu ly</span>
                      </c:when>
                      <c:otherwise>
                        <span class="badge badge-red">That bai</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </c:if>
    </div>

    <%-- RIGHT SIDEBAR --%>
    <div>
      <div style="background:var(--white);border:1px solid var(--border);padding:26px;margin-bottom:12px;">

        <%-- Trang thai --%>
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;padding-bottom:14px;border-bottom:1px solid var(--border);">
          <span style="font-size:10px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:var(--light);">Trang thai</span>
          <c:choose>
            <c:when test="${contract.status=='pending'}">
              <span class="badge badge-amber" style="font-size:12px;padding:6px 14px;">Cho xac nhan</span>
            </c:when>
            <c:when test="${contract.status=='approved'}">
              <span class="badge badge-accent" style="font-size:12px;padding:6px 14px;">Can thanh toan</span>
            </c:when>
            <c:when test="${contract.status=='active'}">
              <span class="badge badge-green" style="font-size:12px;padding:6px 14px;">Dang hieu luc</span>
            </c:when>
            <c:when test="${contract.status=='expired'}">
              <span class="badge badge-dark" style="font-size:12px;padding:6px 14px;">Het han</span>
            </c:when>
            <c:when test="${contract.status=='rejected'}">
              <span class="badge badge-red" style="font-size:12px;padding:6px 14px;">Bi tu choi</span>
            </c:when>
            <c:when test="${contract.status=='terminated'}">
              <span class="badge badge-red" style="font-size:12px;padding:6px 14px;">Cham dut</span>
            </c:when>
            <c:otherwise>
              <span class="badge badge-dark" style="font-size:12px;padding:6px 14px;">${contract.status}</span>
            </c:otherwise>
          </c:choose>
        </div>

        <c:set var="cu" value="${sessionScope.loggedUser}"/>

        <%-- Chu nha: duyet / tu choi --%>
        <c:if test="${contract.ownerId == cu.userId && contract.status == 'pending'}">
          <div class="alert alert-warn" style="margin-bottom:14px;">
            <strong>${contract.tenantName}</strong> muon thue can ho cua ban.
          </div>
          <form action="${pageContext.request.contextPath}/user/contract/approve/${contract.contractId}"
                method="post" style="margin-bottom:8px;">
            <button type="submit" class="btn btn-approve btn-block"
                    onclick="return confirm('Xác nhận chấp nhận yêu cầu thuê này?')">
              ✓ Chap nhan yeu cau
            </button>
          </form>
          <form action="${pageContext.request.contextPath}/user/contract/reject/${contract.contractId}"
                method="post">
            <button type="submit" class="btn btn-reject btn-block"
                    onclick="return confirm('Tu choi yeu cau nay?')">
              ✕ Tu choi
            </button>
          </form>
        </c:if>

        <%-- Nguoi thue: thanh toan lan dau --%>
        <c:if test="${contract.tenantId == cu.userId && contract.status == 'approved'}">
          <div class="escrow-bar" style="margin-bottom:14px;">
            Chu nha da xac nhan! Tien hanh thanh toan de kich hoat hop dong.
          </div>
          <a href="${pageContext.request.contextPath}/user/payment/checkout/${contract.contractId}?type=initial"
             class="btn btn-accent btn-block btn-lg">
            Thanh toan Escrow
          </a>
          <div style="text-align:center;margin-top:8px;font-size:12px;color:var(--light);">
            <fmt:formatNumber value="${contract.initialPayment}" pattern="#,###"/> d tong cong
          </div>
        </c:if>

        <%-- Nguoi thue: active state --%>
        <c:if test="${contract.tenantId == cu.userId && contract.status == 'active'}">

          <%-- Nút xác nhận nhận nhà: chỉ hiện khi CHƯA xác nhận --%>
          <c:if test="${!contract.moveInConfirmed}">
            <div style="border:1px solid var(--border);padding:14px;margin-bottom:12px;background:var(--cream);">
              <p style="font-size:12px;color:var(--light);margin-bottom:8px;line-height:1.6;">
                Đến xem nhà và đồng ý nhận? Bấm xác nhận để kích hoạt hợp đồng 
                và giải phóng Escrow cho chủ nhà.
              </p>
              <form action="${pageContext.request.contextPath}/user/contract/confirm/${contract.contractId}"
                    method="post"
                    onsubmit="return confirm('Xác nhận đã đến nhận nhà và đồng ý thuê?')">
                <button type="submit"
                        style="width:100%;padding:14px;background:var(--success);color:white;border:none;
                               font-family:var(--sans);font-size:14px;font-weight:600;cursor:pointer;">
                  🏠 Xác nhận đã nhận nhà →
                </button>
              </form>
            </div>
          </c:if>

          <%-- Đã xác nhận nhận nhà rồi → hiện badge --%>
          <c:if test="${contract.moveInConfirmed}">
            <div class="alert alert-success" style="margin-bottom:12px;">
              ✅ Đã xác nhận nhận nhà. Hợp đồng đang có hiệu lực.
            </div>
          </c:if>

          <%-- Thanh toán các kỳ định kỳ: chỉ dài hạn VÀ đã xác nhận nhận nhà --%>
          <c:if test="${contract.rentalType == 'long' && contract.moveInConfirmed}">
            <a href="${pageContext.request.contextPath}/user/payment/checkout/${contract.contractId}?type=periodic"
               class="btn btn-dark btn-block" style="margin-bottom:12px;">
              Thanh toán tiền thuê kỳ tiếp
            </a>
          </c:if>

          <%-- Nút hủy hợp đồng (theo UC - Luồng C) --%>
          <c:if test="${!contract.moveInConfirmed}">
            <div style="border-top:1px solid var(--border);padding-top:12px;margin-top:8px;">
              <form action="${pageContext.request.contextPath}/user/contract/cancel/${contract.contractId}"
                    method="post"
                    onsubmit="return confirm('Hủy hợp đồng? Tiền cọc sẽ không được hoàn. Tiền thuê kỳ đầu sẽ được hoàn lại trong 3 ngày làm việc.')">
                <button type="submit"
                        style="width:100%;padding:10px;background:transparent;color:var(--warn);
                               border:1px solid var(--warn);font-size:13px;cursor:pointer;">
                  Hủy hợp đồng
                </button>
              </form>
            </div>
          </c:if>

        </c:if>

        <%-- Het han thực sự --%>
        <c:if test="${contract.status == 'expired'}">
          <div class="alert alert-success">✅ Hợp đồng đã hoàn tất. Escrow đã giải phóng.</div>
        </c:if>

      </div>

      <a href="${pageContext.request.contextPath}/user/contracts"
         class="btn btn-outline btn-block btn-sm">Ve danh sach hop dong</a>
    </div>

  </div>
</div>

<%@ include file="../includes/footer.jsp" %>
