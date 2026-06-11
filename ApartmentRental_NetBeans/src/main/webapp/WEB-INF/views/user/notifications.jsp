<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Thông Báo — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>
<div class="page-strip"><div style="padding:60px 80px;"><span class="eyebrow">Tài khoản</span><h1>Thông báo</h1></div></div>
<div class="container" style="max-width:760px;padding-bottom:80px;">
  <c:choose>
    <c:when test="${empty notifications}">
      <div class="empty" style="padding-top:60px;"><i class="fas fa-bell"></i><h3>Không có thông báo nào</h3><p>Các thông báo về hợp đồng, thanh toán sẽ xuất hiện ở đây.</p></div>
    </c:when>
    <c:otherwise>
      <div style="border:1px solid var(--border);">
        <c:forEach var="n" items="${notifications}">
          <div class="noti-item ${!n.read?'unread':''}">
            <div class="noti-icon ${n.type}"><i class="fas ${n.type=='payment'?'fa-coins':n.type=='contract'?'fa-file-contract':'fa-bell'}"></i></div>
            <div style="flex:1;"><div style="font-weight:600;font-size:14px;margin-bottom:4px;">${n.title}</div><div style="font-size:13px;color:var(--mid);line-height:1.6;">${n.message}</div><div style="font-size:11.5px;color:var(--light);margin-top:5px;"><i class="fas fa-clock" style="margin-right:3px;"></i><fmt:formatDate value="${n.createdAt}" pattern="HH:mm · dd/MM/yyyy"/></div></div>
            <c:if test="${!n.read}"><div style="width:8px;height:8px;background:var(--accent);border-radius:50%;flex-shrink:0;margin-top:6px;"></div></c:if>
          </div>
        </c:forEach>
      </div>
    </c:otherwise>
  </c:choose>
</div>
<%@ include file="../includes/footer.jsp" %>
