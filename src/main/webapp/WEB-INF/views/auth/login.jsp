<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Đăng nhập — ChungCư.vn"/>
<%@ include file="../includes/header.jsp" %>
<div class="auth-page">
  <div class="auth-card">
    <a href="${pageContext.request.contextPath}/home" class="auth-logo">ChungCư<span>.vn</span></a>
    <h1 class="auth-title">Đăng nhập</h1>
    <p class="auth-sub">Chào mừng trở lại. Nhập thông tin tài khoản của bạn.</p>
    <c:if test="${not empty error}">
      <div class="alert alert-error"><i class="fas fa-circle-xmark"></i>${error}</div>
    </c:if>
    <c:if test="${param.success=='registered'}">
      <div class="alert alert-success"><i class="fas fa-circle-check"></i>Đăng ký thành công! Hãy đăng nhập.</div>
    </c:if>
    <div class="auth-demo">
      <strong>Tài khoản demo</strong>
      <div class="demo-acc"><span>Admin</span><span>admin@chungcu.vn / Admin@123</span></div>
      <div class="demo-acc"><span>Owner</span><span>ngankim.owner@gmail.com / 123456</span></div>
      <div class="demo-acc"><span>User</span><span>oanhpm5989@gmail.com / Ho@5989</span></div>

    </div>
    <form method="post" action="${pageContext.request.contextPath}/login">
      <div class="form-group">
        <label class="form-label req">Email</label>
        <input type="email" name="email" class="form-control" placeholder="email@example.com" value="${param.email}" required autofocus>
      </div>
      <div class="form-group">
        <label class="form-label req">Mật khẩu</label>
        <input type="password" name="password" class="form-control" placeholder="••••••••" required>
      </div>
      <c:if test="${not empty param.redirect}">
        <input type="hidden" name="redirect" value="${param.redirect}">
      </c:if>
      <button type="submit" class="btn btn-dark btn-block btn-lg" style="margin-top:8px;">Đăng nhập →</button>
    </form>
    <div class="auth-divider">hoặc</div>
    <div class="auth-footer">Chưa có tài khoản? <a href="${pageContext.request.contextPath}/register">Đăng ký ngay</a></div>
  </div>
</div>
<%@ include file="../includes/footer.jsp" %>
