<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đăng ký — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>
<div class="auth-page">
  <div class="auth-card" style="max-width:520px;">
    <a href="${pageContext.request.contextPath}/home" class="auth-logo">ChungCư<span>.vn</span></a>
    <h1 class="auth-title">Tạo tài khoản</h1>
    <p class="auth-sub">Miễn phí · Không cần thẻ tín dụng · Bắt đầu ngay hôm nay.</p>
    <c:if test="${not empty error}">
      <div class="alert alert-error"><i class="fas fa-circle-xmark"></i>${error}</div>
    </c:if>
    <form method="post" action="${pageContext.request.contextPath}/register">
      <div class="form-group">
        <label class="form-label req">Họ và tên</label>
        <input type="text" name="fullName" class="form-control" placeholder="Nguyễn Văn An" value="${param.fullName}" required>
      </div>
      <div class="form-group">
        <label class="form-label req">Email</label>
        <input type="email" name="email" class="form-control" placeholder="email@example.com" value="${param.email}" required>
      </div>
      <div class="form-group">
        <label class="form-label">Số điện thoại</label>
        <input type="tel" name="phone" class="form-control" placeholder="0901 234 567" value="${param.phone}">
      </div>
      <div class="form-group">
        <label class="form-label req">Mật khẩu</label>
        <input type="password" name="password" class="form-control" placeholder="Tối thiểu 6 ký tự" required>
      </div>
      <div class="form-group">
        <label class="form-label req">Xác nhận mật khẩu</label>
        <input type="password" name="confirmPassword" class="form-control" placeholder="Nhập lại mật khẩu" required>
      </div>
      <button type="submit" class="btn btn-dark btn-block btn-lg" style="margin-top:8px;">Tạo tài khoản →</button>
    </form>
    <div class="auth-divider">hoặc</div>
    <div class="auth-footer">Đã có tài khoản? <a href="${pageContext.request.contextPath}/login">Đăng nhập</a></div>
  </div>
</div>
<%@ include file="../includes/footer.jsp" %>
