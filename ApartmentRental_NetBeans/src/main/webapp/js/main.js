/* ================================================================
   ChungCu.vn — main.js  (patched v2)
   FIX: navToggle → hamburger; wishlist AJAX; avatar dropdown;
        scroll-reveal dùng đúng class .reveal; AJAX search filter
   ================================================================ */

document.addEventListener('DOMContentLoaded', function () {

  /* ── 1. NAV HAMBURGER (FIX: was 'navToggle', actual id='hamburger') ── */
  var hamburger = document.getElementById('hamburger');
  var navMenu   = document.getElementById('navMenu');
  if (hamburger && navMenu) {
    hamburger.addEventListener('click', function () {
      navMenu.classList.toggle('open');
    });
    document.addEventListener('click', function (e) {
      if (!hamburger.contains(e.target) && !navMenu.contains(e.target)) {
        navMenu.classList.remove('open');
      }
    });
  }

  /* ── 2. AVATAR DROPDOWN (FIX: was broken selector '.dropdown') ── */
  var avatarBtn = document.getElementById('avatarBtn');
  var navDrop   = document.getElementById('navDrop');
  if (avatarBtn && navDrop) {
    avatarBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      navDrop.classList.toggle('open');
    });
    document.addEventListener('click', function () {
      navDrop.classList.remove('open');
    });
  }

  /* ── 3. WISHLIST — AJAX, không reload trang ── */
  initWishlist();

  /* ── 4. PAYMENT METHOD selection ── */
  document.querySelectorAll('.pm-option').forEach(function (opt) {
    opt.addEventListener('click', function () {
      document.querySelectorAll('.pm-option').forEach(function (x) { x.classList.remove('on'); });
      opt.classList.add('on');
      var radio = opt.querySelector('input[type=radio]');
      if (radio) radio.checked = true;
    });
  });

  /* ── 5. GALLERY THUMBS ── */
  document.querySelectorAll('.gal-thumbs img').forEach(function (thumb) {
    thumb.addEventListener('click', function () {
      var full = thumb.getAttribute('data-full') || thumb.src;
      var main = document.getElementById('galMain');
      if (main) main.src = full;
      document.querySelectorAll('.gal-thumbs img').forEach(function (t) { t.classList.remove('on'); });
      thumb.classList.add('on');
    });
  });

  /* ── 6. TABS ── */
  document.querySelectorAll('.tab').forEach(function (tab) {
    tab.addEventListener('click', function () {
      var id = tab.dataset.tab;
      document.querySelectorAll('.tab').forEach(function (t) { t.classList.remove('on'); });
      tab.classList.add('on');
      document.querySelectorAll('[data-panel]').forEach(function (p) { p.style.display = 'none'; });
      var panel = document.querySelector('[data-panel="' + id + '"]');
      if (panel) panel.style.display = '';
    });
  });

  /* ── 7. AUTO-DISMISS alerts ── */
  document.querySelectorAll('.alert[data-auto-dismiss]').forEach(function (a) {
    setTimeout(function () {
      a.style.transition = 'opacity .3s';
      a.style.opacity = '0';
      setTimeout(function () { a.remove(); }, 300);
    }, 4000);
  });

  /* ── 8. CONFIRM dialogs ── */
  document.querySelectorAll('[data-confirm]').forEach(function (el) {
    el.addEventListener('click', function (e) {
      if (!confirm(el.dataset.confirm)) e.preventDefault();
    });
  });

  /* ── 9. SCROLL REVEAL — dùng class .reveal từ CSS ── */
  if ('IntersectionObserver' in window) {
    var revealObs = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          e.target.classList.add('visible');
          revealObs.unobserve(e.target);
        }
      });
    }, { threshold: 0.08 });
    document.querySelectorAll('.reveal').forEach(function (el) {
      revealObs.observe(el);
    });
    /* Prop-card lazy reveal */
    var cardObs = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) {
          e.target.style.opacity = '1';
          e.target.style.transform = 'translateY(0)';
          cardObs.unobserve(e.target);
        }
      });
    }, { threshold: 0.05 });
    document.querySelectorAll('.prop-card').forEach(function (el) {
      el.style.opacity = '0';
      el.style.transform = 'translateY(20px)';
      el.style.transition = 'opacity .45s ease, transform .45s ease';
      cardObs.observe(el);
    });
  }

  /* ── 10. RENTAL TYPE auto-fill ── */
  var rtSel = document.getElementById('rentalType');
  var minRm = document.getElementById('minRentalMonths');
  if (rtSel && minRm) {
    rtSel.addEventListener('change', function () {
      if (rtSel.value === 'short') minRm.value = 1;
      else if (rtSel.value === 'long') minRm.value = 6;
    });
  }

  /* ── 11. RENT PRICE display ── */
  var rentInput = document.getElementById('rentPrice');
  if (rentInput) {
    rentInput.addEventListener('input', function () {
      var val = parseInt(rentInput.value.replace(/\D/g, ''));
      var display = document.getElementById('rentPriceDisplay');
      if (display && !isNaN(val)) {
        display.textContent = val.toLocaleString('vi-VN') + ' đ/tháng';
      }
    });
  }

  /* ── 12. IMAGE URL PREVIEW ── */
  document.querySelectorAll('.image-url-input').forEach(function (input) {
    input.addEventListener('blur', function () {
      var preview = input.nextElementSibling;
      if (preview && preview.tagName === 'IMG') {
        preview.src = input.value;
        preview.onerror = function () { preview.src = ''; };
      }
    });
  });

  /* ── 13. SEARCH — AJAX live filter (list.jsp) ── */
  initAjaxSearch();

  /* ── 14. REVIEW form — AJAX submit ── */
  initReviewForm();

});

/* ================================================================
   WISHLIST — localStorage + AJAX toggle
   ================================================================ */
function initWishlist() {
  var KEY = 'ccvn_wishlist';
  var saved = [];
  try { saved = JSON.parse(localStorage.getItem(KEY) || '[]'); } catch(e) {}

  /* Render trạng thái ban đầu */
  document.querySelectorAll('.prop-fav[data-apt-id]').forEach(function (btn) {
    var id = parseInt(btn.dataset.aptId);
    if (saved.indexOf(id) !== -1) {
      btn.textContent = '♥';
      btn.style.color = '#C84E4E';
      btn.classList.add('fav-active');
    }
  });

  /* Toggle click */
  document.querySelectorAll('.prop-fav[data-apt-id]').forEach(function (btn) {
    btn.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      var id = parseInt(btn.dataset.aptId);
      var idx = saved.indexOf(id);
      if (idx === -1) {
        saved.push(id);
        btn.textContent = '♥';
        btn.style.color = '#C84E4E';
        btn.classList.add('fav-active');
        showToast('Đã thêm vào danh sách yêu thích ♥');
      } else {
        saved.splice(idx, 1);
        btn.textContent = '♡';
        btn.style.color = '';
        btn.classList.remove('fav-active');
        showToast('Đã xóa khỏi danh sách yêu thích');
      }
      try { localStorage.setItem(KEY, JSON.stringify(saved)); } catch(e) {}
    });
  });
}

/* ================================================================
   TOAST notification (nhẹ, không cần lib)
   ================================================================ */
function showToast(msg, type) {
  var t = document.getElementById('ccvn-toast');
  if (!t) {
    t = document.createElement('div');
    t.id = 'ccvn-toast';
    t.style.cssText = [
      'position:fixed;bottom:32px;left:50%;transform:translateX(-50%) translateY(20px)',
      'background:#1A1A18;color:#FDFCFA;padding:12px 24px',
      'font-size:13px;letter-spacing:.3px;z-index:9999',
      'opacity:0;transition:opacity .25s,transform .25s;pointer-events:none',
      'border-left:3px solid #C8A96E;max-width:340px;text-align:center'
    ].join(';');
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.style.opacity = '1';
  t.style.transform = 'translateX(-50%) translateY(0)';
  clearTimeout(t._timeout);
  t._timeout = setTimeout(function () {
    t.style.opacity = '0';
    t.style.transform = 'translateX(-50%) translateY(20px)';
  }, 2800);
}

/* ================================================================
   AJAX SEARCH — debounce keyword, cập nhật URL không reload
   ================================================================ */
function initAjaxSearch() {
  var form = document.querySelector('.search-bar')
             && document.querySelector('.search-bar').closest('form');
  if (!form) return;

  /* Debounce submit khi gõ keyword */
  var kwInput = form.querySelector('input[name="keyword"]');
  if (kwInput) {
    var debTimer;
    kwInput.addEventListener('input', function () {
      clearTimeout(debTimer);
      debTimer = setTimeout(function () { form.submit(); }, 600);
    });
  }

  /* Select thay đổi → submit ngay */
  form.querySelectorAll('select').forEach(function (sel) {
    sel.addEventListener('change', function () { form.submit(); });
  });
}

/* ================================================================
   REVIEW FORM — AJAX submit, không tải lại trang
   ================================================================ */
function initReviewForm() {
  var form = document.getElementById('reviewForm');
  if (!form) return;

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    var btn = form.querySelector('button[type=submit]');
    if (btn) { btn.disabled = true; btn.textContent = 'Đang gửi...'; }

    var data = new FormData(form);
    fetch(form.action, { method: 'POST', body: data })
      .then(function (r) { return r.json(); })
      .then(function (res) {
        if (res.ok) {
          showToast('Đánh giá của bạn đã được ghi nhận ✓');
          var list = document.getElementById('reviewList');
          if (list && res.html) {
            list.insertAdjacentHTML('afterbegin', res.html);
          }
          form.reset();
          document.querySelectorAll('.star-btn').forEach(function (s) {
            s.classList.remove('on');
          });
        } else {
          showToast(res.msg || 'Có lỗi xảy ra, vui lòng thử lại.');
        }
      })
      .catch(function () { showToast('Không thể kết nối, vui lòng thử lại.'); })
      .finally(function () {
        if (btn) { btn.disabled = false; btn.textContent = 'Gửi đánh giá'; }
      });
  });

  /* Star rating UI */
  document.querySelectorAll('.star-btn').forEach(function (star) {
    star.addEventListener('click', function () {
      var val = parseInt(star.dataset.val);
      document.querySelectorAll('.star-btn').forEach(function (s) {
        s.classList.toggle('on', parseInt(s.dataset.val) <= val);
      });
      var inp = document.getElementById('ratingInput');
      if (inp) inp.value = val;
    });
  });
}

/* ================================================================
   LEGACY helpers (giữ lại cho tương thích JSP inline calls)
   ================================================================ */
function formatVND(num) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(num);
}
