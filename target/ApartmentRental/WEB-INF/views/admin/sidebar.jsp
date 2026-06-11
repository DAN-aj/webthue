<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<aside class="admin-aside">

  <div class="aside-section" style="padding-top:24px;">Tổng quan</div>
  <a href="${pageContext.request.contextPath}/admin/dashboard"
     class="aside-link ${pageContext.request.requestURI.contains('dashboard')?'on':''}">
    <svg class="aside-icon" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="2" y="2" width="7" height="9" rx="1.5" fill="currentColor" opacity=".9"/>
      <rect x="11" y="2" width="7" height="4" rx="1.5" fill="currentColor" opacity=".9"/>
      <rect x="2" y="13" width="7" height="5" rx="1.5" fill="currentColor" opacity=".9"/>
      <rect x="11" y="8" width="7" height="10" rx="1.5" fill="currentColor" opacity=".9"/>
    </svg>
    Dashboard
  </a>

  <div class="aside-section">Quản lý</div>
  <a href="${pageContext.request.contextPath}/admin/users"
     class="aside-link ${pageContext.request.requestURI.contains('users')?'on':''}">
    <svg class="aside-icon" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="8" cy="6" r="3" fill="currentColor"/>
      <path d="M2 16c0-3.314 2.686-5 6-5s6 1.686 6 5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
      <circle cx="15" cy="6.5" r="2.2" fill="currentColor" opacity=".6"/>
      <path d="M17.5 15c0-2.2-1.2-3.7-3-4.3" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" opacity=".6"/>
    </svg>
    Tài khoản
  </a>

  <a href="${pageContext.request.contextPath}/admin/apartments"
     class="aside-link ${pageContext.request.requestURI.contains('apartment')?'on':''}">
    <svg class="aside-icon" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="3" y="4" width="14" height="14" rx="1.5" stroke="currentColor" stroke-width="1.7"/>
      <path d="M7 18v-5h6v5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>
      <path d="M3 8h14" stroke="currentColor" stroke-width="1.7"/>
      <path d="M3 12h14" stroke="currentColor" stroke-width="1.4" stroke-dasharray="2.5 2"/>
      <path d="M10 2v2" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>
    </svg>
    Tất cả căn hộ
  </a>

  <a href="${pageContext.request.contextPath}/admin/apartments?filter=pending"
     class="aside-link ${pageContext.request.requestURI.contains('apartments') && pageContext.request.queryString != null && pageContext.request.queryString.contains('filter=pending')?'on':''}">
    <svg class="aside-icon" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="10" cy="10" r="7.5" stroke="currentColor" stroke-width="1.7"/>
      <path d="M10 6v4l2.5 2.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    Chờ kiểm duyệt
  </a>

  <a href="${pageContext.request.contextPath}/admin/apartment/edit-requests"
     class="aside-link ${pageContext.request.requestURI.contains('edit-request')?'on':''}">
    <svg class="aside-icon" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="3" y="3" width="14" height="14" rx="2" stroke="currentColor" stroke-width="1.7"/>
      <path d="M7 7h6M7 10h4" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
      <path d="M13 13l2-2-1.5-1.5-2 2V13h1.5z" fill="currentColor"/>
    </svg>
    Yêu cầu chỉnh sửa
    <c:if test="${pendingEditCount > 0}">
      <span style="margin-left:auto;background:#e8a000;color:#fff;font-size:11px;font-weight:700;
                   padding:1px 7px;border-radius:99px;min-width:20px;text-align:center;">
        ${pendingEditCount}
      </span>
    </c:if>
  </a>

  <a href="${pageContext.request.contextPath}/admin/reviews"
     class="aside-link ${pageContext.request.requestURI.contains('review')?'on':''}">
    <svg class="aside-icon" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M10 2l2.4 4.9 5.6.8-4 3.9.9 5.4L10 14.5l-4.9 2.5.9-5.4-4-3.9 5.6-.8L10 2z"
            stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
    </svg>
    Đánh giá
    <c:if test="${pendingReviewCount > 0}">
      <span style="margin-left:auto;background:#e8a000;color:#fff;font-size:11px;font-weight:700;
                   padding:1px 7px;border-radius:99px;min-width:20px;text-align:center;">
        ${pendingReviewCount}
      </span>
    </c:if>
  </a>

  <div class="aside-section">Hệ thống</div>
  <a href="${pageContext.request.contextPath}/admin/etl"
     class="aside-link ${pageContext.request.requestURI.contains('etl')?'on':''}">
    <svg class="aside-icon" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <ellipse cx="10" cy="5.5" rx="7" ry="2.5" stroke="currentColor" stroke-width="1.7"/>
      <path d="M3 5.5v4c0 1.38 3.134 2.5 7 2.5s7-1.12 7-2.5v-4" stroke="currentColor" stroke-width="1.7"/>
      <path d="M3 9.5v4c0 1.38 3.134 2.5 7 2.5s7-1.12 7-2.5v-4" stroke="currentColor" stroke-width="1.7"/>
    </svg>
    ETL Pipeline
  </a>

</aside>
