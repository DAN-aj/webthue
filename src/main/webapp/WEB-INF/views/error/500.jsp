<%@ page contentType="text/html;charset=UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="500 — Lỗi hệ thống"/>
<%@ include file="../includes/header.jsp" %>
<div class="container-sm" style="padding-top:60px;padding-bottom:80px;text-align:center;">
  <div style="font-family:var(--serif);font-size:120px;font-weight:700;color:var(--border);line-height:1;">500</div>
  <h1 style="font-family:var(--serif);font-size:32px;font-weight:700;margin-bottom:14px;">Lỗi hệ thống</h1>
  <p style="color:var(--light);margin-bottom:24px;font-size:15px;">Đã xảy ra lỗi không mong muốn.</p>

  <%-- Hiển thị chi tiết lỗi để debug --%>
  <% if (exception != null) { %>
  <div style="background:#fdf4f4;border:1px solid #f5c6c6;border-left:4px solid #6B2A2A;padding:20px;text-align:left;margin-bottom:28px;font-family:monospace;font-size:13px;color:#6B2A2A;">
    <strong>Exception:</strong> <%= exception.getClass().getName() %><br>
    <strong>Message:</strong> <%= exception.getMessage() %><br>
    <strong>Stack:</strong><br>
    <% for (StackTraceElement el : exception.getStackTrace()) {
         if (el.getClassName().startsWith("com.rental")) { %>
           &nbsp;&nbsp;at <%= el %><br>
    <%   } } %>
  </div>
  <% } else { %>
  <% Object msg = request.getAttribute("javax.servlet.error.message");
     Object exc = request.getAttribute("javax.servlet.error.exception");
     if (exc != null) { %>
  <div style="background:#fdf4f4;border:1px solid #f5c6c6;border-left:4px solid #6B2A2A;padding:20px;text-align:left;margin-bottom:28px;font-family:monospace;font-size:13px;color:#6B2A2A;">
    <strong>Error:</strong> <%= exc.toString() %><br>
    <% Throwable t = (Throwable) exc;
       for (StackTraceElement el : t.getStackTrace()) {
         if (el.getClassName().startsWith("com.rental")) { %>
           &nbsp;&nbsp;at <%= el %><br>
    <%   } } %>
  </div>
  <% } } %>

  <a href="${pageContext.request.contextPath}/home" class="btn btn-dark btn-lg">← Về trang chủ</a>
</div>
<%@ include file="../includes/footer.jsp" %>
