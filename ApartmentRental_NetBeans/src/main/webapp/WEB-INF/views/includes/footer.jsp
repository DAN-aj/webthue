<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<footer class="site-footer">
  <div class="footer-grid">
    <div>
      <a href="${pageContext.request.contextPath}/home" class="footer-logo">ChungCư<span>.vn</span></a>
      <p class="footer-desc">Nền tảng cho thuê chung cư uy tín hàng đầu Việt Nam. Giao dịch minh bạch, an toàn với hệ thống Escrow và hợp đồng điện tử.</p>
      <div class="footer-social" style="margin-top:20px;">
        <a href="#"><i class="fab fa-facebook-f"></i></a>
        <a href="#"><i class="fab fa-instagram"></i></a>
        <a href="#"><i class="fab fa-youtube"></i></a>
        <a href="#"><i class="fas fa-comment-dots"></i></a>
      </div>
    </div>
    <div class="footer-col">
      <h4>Khám phá</h4>
      <a href="${pageContext.request.contextPath}/apartments">Tất cả căn hộ</a>
      <a href="${pageContext.request.contextPath}/apartments?rentalType=short">Thuê ngắn hạn</a>
      <a href="${pageContext.request.contextPath}/apartments?rentalType=long">Thuê dài hạn</a>
      <a href="${pageContext.request.contextPath}/user/apartment/post">Đăng tin cho thuê</a>
    </div>
    <div class="footer-col">
      <h4>Dịch vụ</h4>
      <a href="#">Hợp đồng điện tử</a>
      <a href="#">Thanh toán Escrow</a>
      <a href="#">Xác thực KYC</a>
      <a href="#">Bảo hiểm thuê nhà</a>
    </div>
    <div class="footer-col">
      <h4>Hỗ trợ</h4>
      <a href="${pageContext.request.contextPath}/faq">Câu hỏi thường gặp</a>
      <a href="${pageContext.request.contextPath}/faq#policy">Chính sách hoàn tiền</a>
      <a href="mailto:hotro@chungcu.vn">Email hỗ trợ</a>
      <a href="tel:19001234">Hotline: 1900 1234</a>
    </div>
  </div>
  <div class="footer-bar">
    <span>© 2025 ChungCư.vn — Bảo lưu mọi quyền.</span>
    <span style="display:flex;gap:20px;color:rgba(255,255,255,.2);font-size:11px;">
      <span><i class="fas fa-shield-halved" style="color:var(--accent);margin-right:5px;"></i>Escrow</span>
      <span><i class="fas fa-id-card" style="color:var(--accent);margin-right:5px;"></i>eKYC</span>
      <span><i class="fas fa-lock" style="color:var(--accent);margin-right:5px;"></i>SSL 256-bit</span>
    </span>
  </div>
</footer>

<script>
(function(){
  /* Hamburger */
  var ham = document.getElementById('hamburger');
  var menu = document.getElementById('navMenu');
  if (ham && menu) {
    ham.addEventListener('click', function(e){
      e.stopPropagation();
      menu.classList.toggle('open');
    });
    document.addEventListener('click', function(){ menu.classList.remove('open'); });
    menu.addEventListener('click', function(e){ e.stopPropagation(); });
  }

  /* Avatar dropdown */
  var avatarBtn = document.getElementById('avatarBtn');
  var navDrop   = document.getElementById('navDrop');
  if (avatarBtn && navDrop) {
    avatarBtn.addEventListener('click', function(e){
      e.stopPropagation();
      navDrop.classList.toggle('open');
    });
    navDrop.addEventListener('click', function(e){ e.stopPropagation(); });
    document.addEventListener('click', function(){ if(navDrop) navDrop.classList.remove('open'); });
  }

  /* Gallery thumbnails */
  var mainImg = document.getElementById('galMain');
  if (mainImg) {
    document.querySelectorAll('.gal-thumbs img').forEach(function(th){
      th.addEventListener('click', function(){
        mainImg.src = this.getAttribute('data-full') || this.src;
        document.querySelectorAll('.gal-thumbs img').forEach(function(t){ t.classList.remove('on'); });
        this.classList.add('on');
      });
    });
  }

  /* Tabs (generic) */
  document.querySelectorAll('.tab[data-tab]').forEach(function(tab){
    tab.addEventListener('click', function(){
      var target = this.dataset.tab;
      var container = this.closest('[data-tabs]') || document.body;
      container.querySelectorAll('.tab').forEach(function(t){ t.classList.remove('on'); });
      container.querySelectorAll('.tab-pane').forEach(function(p){ p.classList.remove('on'); p.style.display='none'; });
      this.classList.add('on');
      var pane = document.getElementById(target);
      if(pane){ pane.classList.add('on'); pane.style.display='block'; }
    });
  });

  /* Confirm dialogs */
  document.querySelectorAll('[data-confirm]').forEach(function(el){
    el.addEventListener('click', function(e){
      if(!confirm(this.dataset.confirm)) e.preventDefault();
    });
  });

  /* Auto-dismiss alerts */
  document.querySelectorAll('.auto-dismiss').forEach(function(a){
    setTimeout(function(){ a.style.opacity='0'; a.style.transition='opacity .4s'; setTimeout(function(){ a.remove(); },400); }, 4000);
  });

  /* Scroll reveal */
  var observer = new IntersectionObserver(function(entries){
    entries.forEach(function(e){ if(e.isIntersecting) e.target.classList.add('visible'); });
  }, {threshold:.1});
  document.querySelectorAll('.reveal').forEach(function(el){ observer.observe(el); });

  /* Rent price preview */
  var rentInput = document.getElementById('rentPrice');
  if(rentInput){
    rentInput.addEventListener('input', function(){
      var v = this.value.replace(/\D/g,'');
      var lbl = document.getElementById('rentPreview');
      if(lbl && v) lbl.textContent = parseInt(v).toLocaleString('vi-VN') + ' ₫/tháng';
    });
  }
})();
</script>
</body>
</html>
