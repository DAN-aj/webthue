<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${not empty pageTitle ? pageTitle : 'ChungCu.vn — Thue Chung Cu Uy Tin'}</title>
  <%-- Font Awesome 6: CDN trước, fallback local nếu Edge Tracking Prevention block --%>
  <link rel="stylesheet" id="fa-cdn"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"
        crossorigin="anonymous" referrerpolicy="no-referrer">
  <script>
    (function(){
      var fa = document.getElementById('fa-cdn');
      fa.onerror = function(){
        var fb = document.createElement('link');
        fb.rel  = 'stylesheet';
        fb.href = '${pageContext.request.contextPath}/css/fa-icons.css';
        document.head.appendChild(fb);
        fa.remove();
      };
      /* Fallback bổ sung: sau 2s kiểm tra icon có render đúng không */
      setTimeout(function(){
        var t = document.createElement('i');
        t.className = 'fas fa-home';
        t.style.cssText = 'position:absolute;visibility:hidden;top:-999px';
        document.body.appendChild(t);
        var ok = window.getComputedStyle(t,'::before').content;
        document.body.removeChild(t);
        if(!ok || ok==='none' || ok==='""'){
          if(!document.getElementById('fa-local')){
            var l=document.createElement('link');
            l.id='fa-local'; l.rel='stylesheet';
            l.href='${pageContext.request.contextPath}/css/fa-icons.css';
            document.head.appendChild(l);
          }
        }
      }, 2000);
    })();
  </script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400;1,600&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet">
  <style>

/* ============================================================
   ChungCư.vn — Design System
   Based on NHÀVUI index.html
   Palette: cream/dark/accent(gold) · Serif: Playfair Display · Sans: DM Sans
   ============================================================ */


:root {
  --cream:   #F5F0E8;
  --dark:    #1A1A18;
  --mid:     #4A4A42;
  --light:   #9A9A8E;
  --accent:  #C8A96E;
  --white:   #FDFCFA;
  --border:  #E2DDD4;
  --serif:   'Playfair Display', Georgia, serif;
  --sans:    'DM Sans', -apple-system, BlinkMacSystemFont, sans-serif;
  --success: #2A6B2A;
  --danger:  #6B2A2A;
  --warn:    #856404;
  --r: 0px; /* square edges — editorial style */
}

*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth;font-size:16px}
body{font-family:var(--sans);background:var(--white);color:var(--dark);overflow-x:hidden;-webkit-font-smoothing:antialiased}
a{text-decoration:none;color:inherit}
img{display:block;max-width:100%}
ul{list-style:none}
input,select,textarea,button{font-family:var(--sans)}
.container{max-width:1280px;margin:0 auto;padding:0 80px}
.container-sm{max-width:900px;margin:0 auto;padding:0 80px}

/* ── TYPOGRAPHY ── */
h1,h2,h3{font-family:var(--serif);line-height:1.1;letter-spacing:-.02em}
.eyebrow{font-size:11px;font-weight:500;letter-spacing:3px;text-transform:uppercase;color:var(--accent);display:block;margin-bottom:12px}

/* ── BUTTONS ── */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:8px;font-family:var(--sans);font-size:13px;font-weight:500;letter-spacing:.3px;cursor:pointer;transition:all .2s;border:1px solid transparent;white-space:nowrap}
.btn-dark{padding:12px 28px;background:var(--dark);color:var(--white);border-color:var(--dark)}
.btn-dark:hover{background:var(--accent);border-color:var(--accent)}
.btn-outline{padding:12px 28px;background:transparent;color:var(--dark);border-color:var(--border)}
.btn-outline:hover{background:var(--dark);color:var(--white);border-color:var(--dark)}
.btn-accent{padding:12px 28px;background:var(--accent);color:var(--dark);border-color:var(--accent)}
.btn-accent:hover{background:#b0924f;border-color:#b0924f}
.btn-ghost-white{padding:9px 20px;background:transparent;color:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.1)}
.btn-ghost-white:hover{color:var(--white);border-color:rgba(255,255,255,.4)}
.btn-sm{padding:8px 18px;font-size:12px}
.btn-xs{padding:6px 14px;font-size:11px}
.btn-lg{padding:16px 40px;font-size:14px}
.btn-block{width:100%}
.btn-approve{padding:8px 20px;background:#2A6B2A;color:white;border:none;font-family:var(--sans);font-size:13px;cursor:pointer;font-weight:500}
.btn-approve:hover{background:#1e4d1e}
.btn-reject{padding:8px 20px;background:transparent;color:#6B2A2A;border:1px solid #6B2A2A;font-family:var(--sans);font-size:13px;cursor:pointer;font-weight:500}
.btn-reject:hover{background:#6B2A2A;color:white}

/* ── NAV ── */
.site-nav{position:sticky;top:0;z-index:200;display:flex;align-items:center;justify-content:space-between;padding:0 80px;height:72px;background:rgba(253,252,250,.95);backdrop-filter:blur(12px);border-bottom:1px solid var(--border)}
.nav-logo{font-family:var(--serif);font-size:22px;font-weight:700;letter-spacing:-.5px;color:var(--dark)}
.nav-logo span{color:var(--accent)}
.nav-links{display:flex;gap:36px}
.nav-links a{font-size:13px;font-weight:500;letter-spacing:.5px;text-transform:uppercase;color:var(--mid);transition:color .2s}
.nav-links a:hover,.nav-links a.active{color:var(--dark)}
.nav-links a.nav-cta{color:var(--accent)}
.nav-end{display:flex;gap:12px;align-items:center}
.nav-hamburger{display:none;background:none;border:none;cursor:pointer;font-size:22px;color:var(--dark)}

/* Avatar dropdown */
.nav-dropdown{position:relative}
.nav-avatar-btn{display:flex;align-items:center;gap:9px;background:none;border:1px solid var(--border);cursor:pointer;padding:6px 14px 6px 7px;color:var(--dark);font-size:13px;font-weight:500;letter-spacing:.04em;transition:all .2s}
.nav-avatar-btn:hover{border-color:var(--dark)}
.nav-avatar-btn img{width:28px;height:28px;border-radius:50%;object-fit:cover}
.nav-avatar-btn .ch{font-size:9px;color:var(--light);margin-left:2px;transition:transform .2s}
.nav-dropdown.open .ch{transform:rotate(180deg)}
.dropdown-body{display:none;position:absolute;top:calc(100% + 8px);right:0;min-width:240px;background:var(--white);border:1px solid var(--border);box-shadow:0 16px 48px rgba(26,26,24,.1);z-index:400;padding:8px 0}
.nav-dropdown.open .dropdown-body{display:block}
.dd-head{padding:14px 18px 10px;border-bottom:1px solid var(--border);margin-bottom:4px}
.dd-name{font-family:var(--serif);font-size:15px;font-weight:600}
.dd-email{font-size:12px;color:var(--light);margin-top:2px}
.dropdown-body a{display:flex;align-items:center;gap:10px;padding:10px 18px;font-size:13px;color:var(--mid);transition:background .15s}
.dropdown-body a:hover{background:var(--cream);color:var(--dark)}
.dropdown-body a i{width:16px;font-size:12px;color:var(--light)}
.dropdown-body a.dd-accent{color:var(--accent)}
.dropdown-body hr{border:none;border-top:1px solid var(--border);margin:4px 0}

/* ── SEC BAR ── */
#sec-bar{background:var(--cream);border-bottom:1px solid var(--border);padding:8px 80px;display:flex;align-items:center;justify-content:center;gap:10px;font-size:12px;color:var(--mid)}
#sec-bar i{color:var(--accent)}
.sec-close{background:none;border:none;cursor:pointer;color:var(--light);font-size:18px;margin-left:12px;line-height:1}
.sec-close:hover{color:var(--dark)}

/* ── PAGE STRIP (dark header) ── */
.page-strip{background:var(--dark);color:var(--white);padding:60px 80px}
.page-strip .eyebrow{color:rgba(255,255,255,.3)}
.page-strip h1{font-family:var(--serif);font-size:clamp(28px,4vw,48px);font-weight:700;color:var(--white);margin-bottom:8px;letter-spacing:-.03em}
.page-strip p{color:rgba(255,255,255,.45);font-size:14px;max-width:540px;line-height:1.75}

/* ── SEARCH BAR (dark bg) ── */
.search-section{background:var(--dark);padding:40px 80px}
.search-bar{display:grid;grid-template-columns:2fr 1.2fr 1fr 1fr auto;gap:1px;background:rgba(255,255,255,.1)}
.search-field{background:rgba(255,255,255,.06);padding:18px 24px;border:none}
.search-field label{display:block;font-size:10px;letter-spacing:2px;text-transform:uppercase;color:var(--accent);margin-bottom:6px}
.search-field input,.search-field select{background:transparent;border:none;outline:none;color:var(--white);font-family:var(--sans);font-size:15px;width:100%}
.search-field select option{background:var(--dark);color:var(--white)}
.search-btn{background:var(--accent);border:none;padding:0 40px;color:var(--dark);font-family:var(--sans);font-size:13px;font-weight:600;letter-spacing:1px;text-transform:uppercase;cursor:pointer;transition:all .2s;flex-shrink:0}
.search-btn:hover{background:var(--white)}

/* ── SECTION ── */
.section{padding:100px 80px}
.section-bg{background:var(--cream)}
.section-header{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:60px}
.section-eyebrow{font-size:11px;letter-spacing:3px;text-transform:uppercase;color:var(--accent);margin-bottom:12px;display:block}
.section-title{font-family:var(--serif);font-size:clamp(32px,3.5vw,48px);font-weight:700;line-height:1.15}
.section-title em{font-style:italic}
.section-link{font-size:13px;font-weight:500;letter-spacing:.5px;text-transform:uppercase;color:var(--mid);border-bottom:1px solid var(--border);padding-bottom:2px;white-space:nowrap;transition:all .2s}
.section-link:hover{color:var(--dark);border-color:var(--dark)}

/* ── PROPERTY GRID ── */
.prop-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:2px;background:var(--border)}
.prop-grid.two-col{grid-template-columns:repeat(2,1fr)}
.prop-card{background:var(--white);cursor:pointer;transition:transform .3s}
.prop-card:hover{transform:translateY(-4px)}
.prop-card:hover .prop-img img{transform:scale(1.04)}
.prop-img{overflow:hidden;aspect-ratio:3/2;position:relative}
.prop-img img{width:100%;height:100%;object-fit:cover;transition:transform .6s}
.prop-tag{position:absolute;top:16px;left:16px;background:var(--dark);color:var(--white);font-size:10px;letter-spacing:1.5px;text-transform:uppercase;padding:5px 10px;font-weight:500}
.prop-tag.short{background:var(--accent);color:var(--dark)}
.prop-tag.both{background:#2A6B2A;color:white}
.prop-verified{position:absolute;top:16px;right:16px;background:rgba(253,252,250,.92);color:#2A6B2A;font-size:10px;font-weight:600;padding:4px 10px;letter-spacing:.04em;display:flex;align-items:center;gap:4px;text-transform:uppercase}
.prop-fav{position:absolute;bottom:16px;right:16px;width:34px;height:34px;background:rgba(253,252,250,.9);display:flex;align-items:center;justify-content:center;cursor:pointer;border:none;font-size:15px}
.prop-fav:hover{color:#C84E4E}
.prop-body{padding:24px;border:1px solid var(--border);border-top:none}
.prop-location{font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--light);margin-bottom:8px}
.prop-name{font-family:var(--serif);font-size:20px;font-weight:600;line-height:1.25;margin-bottom:12px;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.prop-meta{display:flex;gap:18px;font-size:13px;color:var(--mid);margin-bottom:16px;flex-wrap:wrap}
.prop-footer{display:flex;justify-content:space-between;align-items:center;padding-top:16px;border-top:1px solid var(--border)}
.prop-price{font-family:var(--serif);font-size:22px;font-weight:600}
.prop-price small{font-family:var(--sans);font-size:12px;font-weight:400;color:var(--light)}
.prop-rating{font-size:12px;color:var(--light);display:flex;align-items:center;gap:4px}
.prop-rating i{color:var(--accent);font-size:11px}

/* ── FEATURED LAYOUT ── */
.featured-grid{display:grid;grid-template-columns:1.6fr 1fr;gap:2px;background:var(--border)}
.featured-main{position:relative;overflow:hidden;aspect-ratio:4/3}
.featured-main img{width:100%;height:100%;object-fit:cover}
.featured-overlay{position:absolute;bottom:0;left:0;right:0;padding:40px;background:linear-gradient(0deg,rgba(26,26,24,.85) 0%,transparent 100%);color:var(--white)}
.featured-tag{font-size:10px;letter-spacing:2px;text-transform:uppercase;background:var(--accent);color:var(--dark);padding:5px 10px;display:inline-block;margin-bottom:12px;font-weight:600}
.featured-title{font-family:var(--serif);font-size:28px;font-weight:700;line-height:1.2;margin-bottom:8px}
.featured-sub{font-size:14px;color:rgba(255,255,255,.7)}
.featured-side{display:grid;grid-template-rows:1fr 1fr;gap:2px;background:var(--border)}
.side-card{position:relative;overflow:hidden}
.side-card img{width:100%;height:100%;object-fit:cover;transition:transform .6s}
.side-card:hover img{transform:scale(1.05)}
.side-overlay{position:absolute;bottom:0;left:0;right:0;padding:20px 24px;background:linear-gradient(0deg,rgba(26,26,24,.8) 0%,transparent 100%);color:var(--white)}
.side-price{font-family:var(--serif);font-size:20px;font-weight:600}
.side-name{font-size:13px;color:rgba(255,255,255,.75)}

/* ── STATS BAR ── */
.stats-section{background:var(--dark);padding:80px;display:grid;grid-template-columns:repeat(4,1fr);gap:1px;background:var(--dark)}
.stat-item{padding:48px 40px;border-left:1px solid rgba(255,255,255,.08)}
.stat-item:first-child{border-left:none}
.stat-num{font-family:var(--serif);font-size:52px;font-weight:700;color:var(--white);line-height:1}
.stat-num span{color:var(--accent)}
.stat-label{font-size:13px;color:rgba(255,255,255,.5);margin-top:8px;text-transform:uppercase;letter-spacing:1.5px}

/* ── STEPS ── */
.how-section{background:var(--cream);padding:100px 80px}
.steps{display:grid;grid-template-columns:repeat(4,1fr);gap:40px;margin-top:60px}
.step{position:relative}
.step-num{font-family:var(--serif);font-size:80px;font-weight:700;color:var(--border);line-height:1;margin-bottom:-20px}
.step-title{font-family:var(--serif);font-size:20px;font-weight:600;margin-bottom:12px}
.step-desc{font-size:14px;line-height:1.7;color:var(--mid)}

/* ── FORMS ── */
.form-card{background:var(--white);border:1px solid var(--border);padding:48px}
.form-title{font-family:var(--serif);font-size:30px;font-weight:700;margin-bottom:8px;letter-spacing:-.02em}
.form-sub{color:var(--mid);font-size:14px;margin-bottom:36px;line-height:1.7}
.form-group{margin-bottom:22px}
.form-label{display:block;font-size:11px;font-weight:500;letter-spacing:2px;text-transform:uppercase;color:var(--mid);margin-bottom:8px}
.form-label.req::after{content:' *';color:#C84E4E}
.form-control{width:100%;padding:14px 16px;border:1px solid var(--border);background:var(--cream);font-family:var(--sans);font-size:15px;color:var(--dark);transition:border-color .2s;outline:none;border-radius:0;-webkit-appearance:none}
.form-control:focus{border-color:var(--dark)}
textarea.form-control{resize:vertical;min-height:100px}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.form-hint{font-size:12px;color:var(--light);margin-top:5px;line-height:1.6}
.checkbox-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(170px,1fr));gap:10px}
.chk-item{display:flex;align-items:center;gap:9px;font-size:14px;cursor:pointer;color:var(--mid)}
.chk-item input[type=checkbox]{width:15px;height:15px;cursor:pointer;accent-color:var(--dark)}

/* ── AUTH ── */
.auth-page{min-height:calc(100vh - 72px);display:flex;align-items:center;justify-content:center;background:var(--cream);padding:40px 20px}
.auth-card{background:var(--white);border:1px solid var(--border);padding:52px 48px;width:100%;max-width:480px}
.auth-logo{font-family:var(--serif);font-size:20px;font-weight:700;letter-spacing:-.02em;color:var(--dark);margin-bottom:36px;display:block}
.auth-logo span{color:var(--accent)}
.auth-title{font-family:var(--serif);font-size:30px;font-weight:700;margin-bottom:8px}
.auth-sub{color:var(--mid);font-size:14px;margin-bottom:36px;line-height:1.7}
.auth-demo{background:var(--cream);border:1px solid var(--border);border-left:3px solid var(--accent);padding:16px 18px;margin-bottom:28px;font-size:13px}
.auth-demo strong{display:block;font-size:11px;font-weight:600;letter-spacing:2px;text-transform:uppercase;color:var(--mid);margin-bottom:8px}
.demo-acc{display:flex;justify-content:space-between;padding:5px 0;border-bottom:1px solid var(--border);color:var(--mid);font-size:12.5px}
.demo-acc:last-child{border-bottom:none}
.auth-divider{display:flex;align-items:center;gap:12px;margin:24px 0;color:var(--light);font-size:11px;letter-spacing:2px;text-transform:uppercase}
.auth-divider::before,.auth-divider::after{content:'';flex:1;height:1px;background:var(--border)}
.auth-footer{margin-top:20px;font-size:14px;color:var(--mid);text-align:center}
.auth-footer a{color:var(--dark);font-weight:500;border-bottom:1px solid var(--border)}
.auth-footer a:hover{border-color:var(--dark)}

/* ── ALERTS ── */
.alert{padding:14px 18px;font-size:13.5px;margin-bottom:22px;display:flex;align-items:flex-start;gap:10px;border-left:3px solid}
.alert i{flex-shrink:0;margin-top:1px}
.alert-error{background:#fdf4f4;color:var(--danger);border:1px solid #f5c6c6;border-left:3px solid var(--danger)}
.alert-success{background:#f0f7f3;color:var(--success);border:1px solid #c2ddd0;border-left:3px solid var(--success)}
.alert-warn{background:#fdf8f0;color:var(--warn);border:1px solid #f0d9b0;border-left:3px solid var(--accent)}
.alert-info{background:var(--cream);color:var(--mid);border:1px solid var(--border);border-left:3px solid var(--dark)}

/* ── BADGES ── */
.badge{display:inline-block;padding:4px 10px;font-size:11px;letter-spacing:.5px;text-transform:uppercase;font-weight:500}
.badge-green{background:#E8F4E8;color:var(--success)}
.badge-amber{background:#FEF3CD;color:var(--warn)}
.badge-red{background:#F4E8E8;color:var(--danger)}
.badge-dark{background:var(--cream);color:var(--mid)}
.badge-accent{background:#FDF8EE;color:var(--accent)}

/* ── TABLES ── */
.table-wrap{overflow-x:auto;border:1px solid var(--border)}
table{width:100%;border-collapse:collapse;font-size:14px}
th{font-size:11px;letter-spacing:1.5px;text-transform:uppercase;color:var(--light);padding:14px 24px;text-align:left;border-bottom:1px solid var(--border);background:var(--cream);font-weight:500}
td{padding:16px 24px;border-bottom:1px solid var(--border);color:var(--mid)}
tr:last-child td{border-bottom:none}
tr:hover td{background:var(--cream)}
.table-head{padding:20px 24px;border-bottom:1px solid var(--border);display:flex;justify-content:space-between;align-items:center;background:var(--white)}
.table-head h3{font-family:var(--serif);font-size:20px;font-weight:600}

/* ── TABS ── */
.tabs{display:flex;border-bottom:1px solid var(--border);margin-bottom:36px;overflow-x:auto}
.tab{padding:13px 22px;font-size:12px;font-weight:500;letter-spacing:1px;text-transform:uppercase;color:var(--light);cursor:pointer;border-bottom:2px solid transparent;margin-bottom:-1px;transition:all .2s;background:none;border-left:none;border-right:none;border-top:none;white-space:nowrap}
.tab:hover{color:var(--dark)}
.tab.on{color:var(--dark);border-bottom-color:var(--dark)}

/* ── APARTMENT DETAIL ── */
.breadcrumb{display:flex;align-items:center;gap:8px;font-size:11.5px;color:var(--light);padding:22px 0;border-bottom:1px solid var(--border);margin-bottom:40px;text-transform:uppercase;letter-spacing:1.5px}
.breadcrumb a{transition:color .2s}
.breadcrumb a:hover{color:var(--dark)}
.breadcrumb i{font-size:9px}
.detail-layout{display:grid;grid-template-columns:1fr 360px;gap:64px;align-items:start}
.gal-main{overflow:hidden;aspect-ratio:16/9;position:relative;cursor:pointer}
.gal-main img{width:100%;height:100%;object-fit:cover;transition:transform .6s}
.gal-main:hover img{transform:scale(1.03)}
.gal-count{position:absolute;bottom:16px;right:16px;background:rgba(26,26,24,.65);color:var(--white);font-size:11px;padding:5px 12px;letter-spacing:1px}
.gal-thumbs{display:flex;gap:3px;margin-top:3px;overflow-x:auto}
.gal-thumbs img{width:90px;height:62px;object-fit:cover;cursor:pointer;opacity:.5;transition:opacity .2s;flex-shrink:0;border-bottom:2px solid transparent}
.gal-thumbs img:hover,.gal-thumbs img.on{opacity:1;border-bottom-color:var(--dark)}
.apt-headline{font-family:var(--serif);font-size:clamp(26px,4vw,42px);font-weight:700;letter-spacing:-.03em;margin-bottom:14px;line-height:1.1}
.apt-specs{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;margin:28px 0;padding:28px;background:var(--cream)}
.spec-num{font-family:var(--serif);font-size:28px;font-weight:600}
.spec-label{font-size:12px;color:var(--light);text-transform:uppercase;letter-spacing:1px;margin-top:4px}
.apt-desc{font-size:16px;line-height:1.85;color:var(--mid);margin-bottom:32px}
.amenity-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}
.amenity-item{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--mid);padding:10px 14px;background:var(--cream)}
.detail-sidebar{position:sticky;top:88px}
.price-card{border:1px solid var(--border);padding:32px}
.price-main{font-family:var(--serif);font-size:38px;font-weight:700;line-height:1}
.price-main small{font-family:var(--sans);font-size:14px;font-weight:400;color:var(--light)}
.price-deposit{font-size:14px;color:var(--mid);margin-top:8px;padding-top:16px;border-top:1px solid var(--border);margin-bottom:24px}
.owner-row{display:flex;align-items:center;gap:12px;padding:20px 0;border-bottom:1px solid var(--border);margin-bottom:20px}
.owner-ava{width:44px;height:44px;border-radius:50%;background:var(--cream);display:flex;align-items:center;justify-content:center;font-family:var(--serif);font-size:18px;font-weight:700;flex-shrink:0}
.owner-name{font-weight:600;font-size:15px}
.owner-meta-txt{font-size:12px;color:var(--light);margin-top:2px}
.addr-hidden{display:flex;align-items:center;gap:8px;background:var(--cream);padding:11px 14px;border:1px dashed var(--border);color:var(--light);font-size:12.5px;margin-bottom:20px}
.addr-hidden i{color:var(--accent)}
.escrow-bar{display:flex;align-items:flex-start;gap:12px;padding:14px 16px;background:#f0f7f3;border:1px solid #c2ddd0;border-left:3px solid var(--success);font-size:13px;color:#1e4733;margin-bottom:16px}
.escrow-bar strong{display:block;margin-bottom:2px;font-weight:700}
.sec-tip{display:flex;align-items:flex-start;gap:10px;padding:13px 15px;background:var(--cream);border:1px solid var(--border);border-left:3px solid var(--accent);font-size:12.5px;color:var(--mid);margin-bottom:14px}
.sec-tip i{color:var(--accent);flex-shrink:0;margin-top:1px}
.chat-btn{width:100%;padding:12px;border:1px dashed var(--border);background:var(--cream);color:var(--mid);font-size:12px;letter-spacing:1px;text-transform:uppercase;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;transition:all .2s;margin-bottom:10px}
.chat-btn:hover{border-color:var(--dark);color:var(--dark)}

/* ── CONTRACT CARD ── */
.contract-card{background:var(--white);border:1px solid var(--border);padding:24px;margin-bottom:2px;display:flex;gap:20px;align-items:flex-start;transition:background .2s}
.contract-card:hover{background:var(--cream)}
.contract-card img{width:110px;height:76px;object-fit:cover;flex-shrink:0}
.cc-title{font-family:var(--serif);font-size:18px;font-weight:600;margin-bottom:6px}
.cc-meta{display:flex;flex-wrap:wrap;gap:16px;font-size:12px;color:var(--light);margin:8px 0;text-transform:uppercase;letter-spacing:.5px}
.cc-meta i{color:var(--accent)}
.cc-actions{display:flex;gap:8px;margin-top:14px;flex-wrap:wrap;align-items:center}

/* ── PAYMENT ── */
.pay-layout{display:grid;grid-template-columns:1fr 380px;gap:48px;align-items:start}
.pay-methods{border:1px solid var(--border)}
.pm-option{display:flex;align-items:center;gap:14px;padding:18px 22px;cursor:pointer;transition:background .2s;border-bottom:1px solid var(--border)}
.pm-option:last-of-type{border-bottom:none}
.pm-option:hover,.pm-option.on{background:var(--cream)}
.pm-option input[type=radio]{width:15px;height:15px;accent-color:var(--dark);flex-shrink:0}
.pm-icon{font-size:22px;flex-shrink:0}
.pm-title{font-size:14px;font-weight:500;color:var(--dark)}
.pm-desc{font-size:12px;color:var(--light);margin-top:3px}
.pm-arrow{font-size:10px;color:var(--light);transition:transform .2s;margin-left:auto}
.pm-option.on .pm-arrow{transform:rotate(180deg)}
.qr-panel,.card-panel,.wallet-panel{display:none;padding:28px;background:var(--cream);border-top:1px solid var(--border)}
.qr-panel.on,.card-panel.on,.wallet-panel.on{display:block}
.bank-tabs{display:flex;flex-wrap:wrap;border:1px solid var(--border);background:var(--white);margin-bottom:24px}
.bank-tab{padding:8px 16px;font-size:12px;font-weight:500;border:none;background:none;cursor:pointer;letter-spacing:.5px;text-transform:uppercase;color:var(--light);border-right:1px solid var(--border);transition:all .15s}
.bank-tab:last-child{border-right:none}
.bank-tab:hover,.bank-tab.on{background:var(--dark);color:var(--white)}
.qr-bank-name{font-family:var(--serif);font-size:15px;font-weight:600;text-align:center;margin-bottom:14px}
.qr-frame{width:180px;height:180px;display:block;margin:0 auto 20px;border:1px solid var(--border);padding:10px;background:var(--white)}
.qr-detail{display:grid;grid-template-columns:auto 1fr;gap:8px 16px;font-size:13px;margin-bottom:16px;align-items:center}
.qr-detail span{color:var(--light);font-size:11px;text-transform:uppercase;letter-spacing:1px}
.qr-detail strong{color:var(--dark);font-weight:600}
.qr-timer{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--mid);background:var(--white);padding:10px 16px;border:1px solid var(--border)}
.qr-timer i{color:var(--accent)}
.card-visual{background:linear-gradient(135deg,#1a1a18,#3a3a32);color:#fff;padding:24px;margin-bottom:22px;position:relative;height:160px;display:flex;flex-direction:column;justify-content:space-between;overflow:hidden}
.card-visual::before{content:'';position:absolute;top:-40px;right:-40px;width:180px;height:180px;border-radius:50%;background:rgba(200,169,110,.08)}
.cc-chip{width:38px;height:28px;background:linear-gradient(135deg,#d4a843,#f0c862);border-radius:4px}
.cc-num{font-size:17px;letter-spacing:.18em;font-weight:300;font-family:monospace}
.cc-foot{display:flex;justify-content:space-between;align-items:flex-end}
.cc-lbl{font-size:9px;letter-spacing:1.5px;text-transform:uppercase;opacity:.5;margin-bottom:3px}
.cc-val{font-size:13px;font-weight:500;letter-spacing:.5px}
.card-fields{display:flex;flex-direction:column;gap:14px}
.card-row{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.card-security{display:flex;align-items:center;gap:8px;font-size:11.5px;color:var(--light);padding:12px 0;border-top:1px solid var(--border)}
.wallet-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:20px}
.wallet-item{border:1px solid var(--border);padding:18px 12px;text-align:center;cursor:pointer;transition:all .15s;background:var(--white)}
.wallet-item:hover,.wallet-item.on{border-color:var(--dark);background:var(--cream)}
.w-logo{font-size:28px;margin-bottom:8px}
.w-name{font-size:12px;font-weight:500;letter-spacing:.5px;text-transform:uppercase;color:var(--mid)}
.wallet-deep{display:none;text-align:center;padding:20px;background:var(--white);border:1px solid var(--border)}
.pay-summary{background:var(--white);border:1px solid var(--border);margin-bottom:14px}
.ps-img{width:100%;height:180px;object-fit:cover}
.ps-body{padding:22px}
.ps-title{font-family:var(--serif);font-size:17px;font-weight:600;margin-bottom:16px;line-height:1.3}
.ps-row{display:flex;justify-content:space-between;padding:9px 0;font-size:13px;color:var(--mid);border-bottom:1px solid var(--border)}
.ps-row:last-of-type{border-bottom:none}
.ps-total{font-family:var(--serif);font-size:18px;font-weight:700;color:var(--dark);border-top:1px solid var(--dark) !important;border-bottom:none !important;padding-top:14px;margin-top:6px}
.pay-trust{margin-top:20px}
.trust-line{display:flex;align-items:center;gap:9px;font-size:12px;color:var(--light);padding:7px 0;border-bottom:1px solid var(--border)}
.trust-line:last-child{border-bottom:none}
.trust-line i{color:var(--accent);width:14px}
.tip-box{display:flex;align-items:flex-start;gap:10px;padding:14px 16px;background:var(--cream);border:1px solid var(--border);border-left:3px solid var(--accent);font-size:13px;color:var(--mid);margin-top:16px}
.tip-box i{color:var(--accent);flex-shrink:0;margin-top:1px}

/* ── NOTIFICATIONS ── */
.noti-item{display:flex;gap:16px;align-items:flex-start;padding:18px;border-bottom:1px solid var(--border);transition:background .2s}
.noti-item:hover,.noti-item.unread{background:var(--cream)}
.noti-icon{width:38px;height:38px;display:flex;align-items:center;justify-content:center;flex-shrink:0;font-size:14px}
.noti-icon.payment{background:#f0f7f3;color:var(--success)}
.noti-icon.contract{background:#fdf8ee;color:var(--accent)}
.noti-icon.info{background:var(--cream);color:var(--mid)}

/* ── ADMIN ── */
.admin-shell{display:flex;min-height:calc(100vh - 72px)}
.admin-aside{width:250px;background:var(--dark);color:var(--white);flex-shrink:0;display:flex;flex-direction:column}
.aside-logo{padding:28px 28px 20px;border-bottom:1px solid rgba(255,255,255,.08);font-family:var(--serif);font-size:18px;font-weight:700;letter-spacing:-.3px}
.aside-logo span{color:var(--accent)}
.aside-section{padding:20px 28px 8px;font-size:9.5px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,.2)}
.aside-link{display:flex;align-items:center;gap:11px;padding:12px 28px;color:rgba(255,255,255,.5);font-size:13px;font-weight:500;letter-spacing:.5px;text-transform:uppercase;border-left:3px solid transparent;transition:all .2s}
.aside-link:hover,.aside-link.on{background:rgba(255,255,255,.05);color:var(--white);border-left-color:var(--accent)}
.aside-link i{width:16px;font-size:12px}
.aside-icon{width:16px;height:16px;min-width:16px;flex-shrink:0;color:currentColor;display:block;}
.admin-main{flex:1;padding:48px;background:var(--cream);overflow-x:hidden;min-width:0}
.admin-header{margin-bottom:40px;padding-bottom:24px;border-bottom:1px solid var(--border)}
.admin-header h1{font-family:var(--serif);font-size:36px;font-weight:700;letter-spacing:-.03em}
.admin-header p{color:var(--mid);margin-top:8px;font-size:14px}
.stat-cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:2px;background:var(--border);margin-bottom:36px;border:1px solid var(--border)}
.stat-card{background:var(--white);padding:28px;display:flex;align-items:center;gap:18px}
.stat-icon{width:46px;height:46px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.stat-icon.blue{background:#eef2ff;color:#3b5bdb}
.stat-icon.orange{background:#fff8ee;color:#b05a00}
.stat-icon.green{background:#f0f7f3;color:var(--success)}
.stat-icon.gold{background:#fdf8ee;color:var(--accent)}
.stat-num-sm{font-family:var(--serif);font-size:30px;font-weight:700;line-height:1;letter-spacing:-.03em}
.stat-label-sm{color:var(--light);font-size:10.5px;margin-top:6px;text-transform:uppercase;letter-spacing:1.5px}
.review-card{background:var(--white);border:1px solid var(--border);margin-bottom:16px;overflow:hidden}
.review-card-grid{display:grid;grid-template-columns:160px 1fr}
.review-card-img{aspect-ratio:4/3;overflow:hidden}
.review-card-img img{width:100%;height:100%;object-fit:cover}
.review-card-body{padding:24px;display:flex;flex-direction:column;justify-content:space-between}
.review-card-title{font-family:var(--serif);font-size:18px;font-weight:600;margin-bottom:8px}
.review-meta{font-size:13px;color:var(--mid);line-height:1.7}
.review-actions{display:flex;gap:10px;margin-top:16px;flex-wrap:wrap}

/* ── EMPTY STATE ── */
.empty{text-align:center;padding:72px 24px;color:var(--light)}
.empty i{font-size:40px;display:block;margin-bottom:18px;opacity:.2}
.empty h3{font-family:var(--serif);font-size:24px;font-weight:600;margin-bottom:10px;color:var(--dark)}
.empty p{font-size:14px;line-height:1.75;max-width:360px;margin:0 auto 28px}

/* ── FOOTER ── */
.site-footer{background:var(--dark);color:var(--white);padding:80px 80px 0}
.footer-grid{display:grid;grid-template-columns:2fr 1fr 1fr 1fr;gap:60px;padding-bottom:60px;border-bottom:1px solid rgba(255,255,255,.08)}
.footer-logo{font-family:var(--serif);font-size:22px;font-weight:700;color:var(--white);margin-bottom:16px;display:block}
.footer-logo span{color:var(--accent)}
.footer-desc{font-size:14px;line-height:1.8;color:rgba(255,255,255,.4);max-width:260px}
.footer-col h4{font-size:11px;letter-spacing:2px;text-transform:uppercase;color:var(--accent);margin-bottom:20px}
.footer-col a{display:block;font-size:14px;color:rgba(255,255,255,.5);margin-bottom:10px;transition:color .15s}
.footer-col a:hover{color:var(--white)}
.footer-bar{padding:28px 0;display:flex;justify-content:space-between;align-items:center;font-size:13px;color:rgba(255,255,255,.2);flex-wrap:wrap;gap:12px;letter-spacing:.5px}
.footer-social{display:flex;gap:8px}
.footer-social a{width:36px;height:36px;border:1px solid rgba(255,255,255,.12);display:flex;align-items:center;justify-content:center;color:rgba(255,255,255,.35);font-size:14px;transition:all .2s}
.footer-social a:hover{border-color:var(--white);color:var(--white)}

/* ── UTILS ── */
.text-accent{color:var(--accent)}.text-success{color:var(--success)}.text-danger{color:var(--danger)}.text-muted{color:var(--light)}
.mt-1{margin-top:8px}.mt-2{margin-top:16px}.mt-3{margin-top:24px}.mt-4{margin-top:36px}
.mb-1{margin-bottom:8px}.mb-2{margin-bottom:16px}.mb-3{margin-bottom:24px}.mb-4{margin-bottom:36px}
.divider{border:none;border-top:1px solid var(--border);margin:28px 0}
.sec-title{font-family:var(--serif);font-size:18px;font-weight:600;margin-bottom:20px;display:flex;align-items:center;gap:14px;color:var(--dark);letter-spacing:-.01em}
.sec-title::after{content:'';flex:1;height:1px;background:var(--border)}
.auto-dismiss{}

/* ── ADMIN ICON FIX — fa- icons inside admin sidebar/buttons stay small ── */
.aside-link .fas, .aside-link .far, .aside-link .fab,
.aside-link i { width:16px; font-size:13px; flex-shrink:0; }
/* fa- icons inside table action buttons */
.btn-approve i, .btn-reject i,
button i.fas, button i.far { font-size:12px; }
/* Inline action icons in td cells */
td i.fas, td i.far { font-size:13px; }
/* General icon cap inside admin main */
.admin-main i.fas, .admin-main i.far, .admin-main i.fab { font-size:13px; max-width:16px; }
/* Stat cards icon is intentionally larger */
.stat-icon i.fas, .stat-icon i.far { font-size:18px; max-width:unset; }
/* Alert icons */
.alert i.fas { font-size:14px; }

/* ── REVEAL ANIMATION ── */
.reveal{opacity:0;transform:translateY(28px);transition:opacity .7s ease,transform .7s ease}
.reveal.visible{opacity:1;transform:none}

/* ── RESPONSIVE ── */
@media(max-width:1024px){
  .detail-layout,.pay-layout{grid-template-columns:1fr}
  .detail-sidebar{position:static}
  .steps{grid-template-columns:1fr 1fr}
  .footer-grid{grid-template-columns:1fr 1fr;gap:40px}
  .admin-aside{width:220px}
  .stats-section{grid-template-columns:1fr 1fr;padding:60px 40px}
  .featured-grid{grid-template-columns:1fr}
}
@media(max-width:768px){
  .container,.container-sm{padding:0 24px}
  .site-nav{padding:0 24px}
  #sec-bar{padding:8px 24px}
  .page-strip,.section,.section-bg,.how-section,.search-section{padding-left:24px;padding-right:24px}
  .section{padding-top:60px;padding-bottom:60px}
  .how-section{padding-top:60px;padding-bottom:60px}
  .site-footer{padding-left:24px;padding-right:24px}
  .nav-links{display:none;position:fixed;top:72px;left:0;right:0;background:var(--white);border-bottom:1px solid var(--border);flex-direction:column;padding:8px 0;z-index:199}
  .nav-links.open{display:flex}
  .nav-links a{height:auto;padding:14px 24px;border-bottom:1px solid var(--border)}
  .nav-hamburger{display:block}
  .hero-grid{grid-template-columns:1fr}
  .hero-right-half{display:none}
  .prop-grid{grid-template-columns:1fr}
  .search-bar{grid-template-columns:1fr}
  .steps{grid-template-columns:1fr}
  .form-row{grid-template-columns:1fr}
  .wallet-grid{grid-template-columns:1fr 1fr}
  .contract-card{flex-direction:column}
  .contract-card img{width:100%;height:180px}
  .admin-shell{flex-direction:column}
  .admin-aside{width:100%}
  .admin-main{padding:24px}
  .footer-grid{grid-template-columns:1fr;gap:28px}
  .stat-cards{grid-template-columns:1fr 1fr}
  .auth-card{padding:36px 24px}
  .apt-specs{grid-template-columns:1fr 1fr 1fr}
  .amenity-grid{grid-template-columns:1fr 1fr}
  .featured-grid{grid-template-columns:1fr}
}
@media(max-width:480px){
  .stat-cards{grid-template-columns:1fr}
  .wallet-grid{grid-template-columns:1fr 1fr}
  .apt-specs{grid-template-columns:1fr}
  .pay-layout{grid-template-columns:1fr}
  .stats-section{grid-template-columns:1fr 1fr}
}
  
/* Font Awesome Stub - Unicode fallback for Edge Tracking Prevention */
/* Sử dụng khi CDN bị block. Các icon quan trọng được map sang Unicode. */

.fas, .far, .fab, .fa {
  font-family: sans-serif;
  font-style: normal;
  font-weight: normal;
  display: inline-block;
  speak: never;
}

/* Navigation & UI */
.fa-bars::before           { content: "☰"; }
.fa-xmark::before          { content: "✕"; }
.fa-chevron-down::before   { content: "▾"; }
.fa-chevron-right::before  { content: "›"; }
.fa-arrow-left::before     { content: "←"; }

/* User */
.fa-user::before               { content: "👤"; font-style:normal; }
.fa-bell::before               { content: "🔔"; font-style:normal; }
.fa-right-to-bracket::before   { content: "→"; }
.fa-right-from-bracket::before { content: "↩"; }
.fa-gauge-high::before         { content: "📊"; font-style:normal; }

/* Property */
.fa-home::before               { content: "🏠"; font-style:normal; }
.fa-building::before           { content: "🏢"; font-style:normal; }
.fa-key::before                { content: "🔑"; font-style:normal; }
.fa-location-dot::before       { content: "📍"; font-style:normal; }
.fa-expand::before             { content: "⤡"; }
.fa-bed::before                { content: "🛏"; font-style:normal; }
.fa-bath::before               { content: "🚿"; font-style:normal; }
.fa-layer-group::before        { content: "⬛"; }
.fa-eye::before                { content: "👁"; font-style:normal; }
.fa-images::before             { content: "🖼"; font-style:normal; }
.fa-lock::before               { content: "🔒"; font-style:normal; }
.fa-map-location-dot::before   { content: "🗺"; font-style:normal; }

/* Amenities */
.fa-wifi::before               { content: "📶"; font-style:normal; }
.fa-snowflake::before          { content: "❄"; }
.fa-shirt::before              { content: "👕"; font-style:normal; }
.fa-temperature-low::before    { content: "🧊"; font-style:normal; }
.fa-tv::before                 { content: "📺"; font-style:normal; }
.fa-utensils::before           { content: "🍴"; font-style:normal; }
.fa-sun::before                { content: "☀"; }
.fa-elevator::before           { content: "🛗"; font-style:normal; }
.fa-square-parking::before     { content: "🅿"; font-style:normal; }
.fa-dumbbell::before           { content: "🏋"; font-style:normal; }
.fa-water-ladder::before       { content: "🏊"; font-style:normal; }
.fa-bell-concierge::before     { content: "🔔"; font-style:normal; }
.fa-tree::before               { content: "🌳"; font-style:normal; }
.fa-fire-burner::before        { content: "🔥"; font-style:normal; }
.fa-briefcase::before          { content: "💼"; font-style:normal; }
.fa-video::before              { content: "📷"; font-style:normal; }
.fa-paw::before                { content: "🐾"; font-style:normal; }
.fa-circle-check::before       { content: "✓"; color: inherit; }

/* Security & Trust */
.fa-shield-halved::before      { content: "🛡"; font-style:normal; }
.fa-id-card::before            { content: "🪪"; font-style:normal; }

/* Contract & Payment */
.fa-file-contract::before      { content: "📄"; font-style:normal; }
.fa-coins::before              { content: "💰"; font-style:normal; }
.fa-receipt::before            { content: "🧾"; font-style:normal; }
.fa-credit-card::before        { content: "💳"; font-style:normal; }
.fa-landmark::before           { content: "🏦"; font-style:normal; }
.fa-wallet::before             { content: "👛"; font-style:normal; }
.fa-clock::before              { content: "⏰"; font-style:normal; }
.fa-calendar::before           { content: "📅"; font-style:normal; }
.fa-calendar-days::before      { content: "📅"; font-style:normal; }
.fa-check::before              { content: "✓"; }

/* Alerts */
.fa-triangle-exclamation::before { content: "⚠"; }
.fa-circle-xmark::before         { content: "✕"; }
.fa-circle-info::before          { content: "ℹ"; }

/* Admin */
.fa-users::before              { content: "👥"; font-style:normal; }
.fa-plus::before               { content: "+"; font-weight:bold; }
.fa-plus-circle::before        { content: "⊕"; }
.fa-trash::before              { content: "🗑"; font-style:normal; }
.fa-floppy-disk::before        { content: "💾"; font-style:normal; }
.fa-paper-plane::before        { content: "✉"; }
.fa-external-link-alt::before  { content: "↗"; }
.fa-filter::before             { content: "▼"; font-size:.7em; }
.fa-chart-bar::before          { content: "📊"; font-style:normal; }
.fa-search::before             { content: "🔍"; font-style:normal; }

/* Misc */
.fa-phone::before              { content: "📞"; font-style:normal; }
.fa-envelope::before           { content: "✉"; }
.fa-comment-dots::before       { content: "💬"; font-style:normal; }

/* Social */
.fa-facebook-f::before  { content: "f"; font-weight:bold; }
.fa-instagram::before   { content: "ig"; font-size:.7em; }
.fa-youtube::before     { content: "▶"; }

  </style>
</head>
<body>

<div id="sec-bar">
  <i class="fas fa-shield-halved"></i>
  <span>Không chuyển khoản ngoài hệ thống. Mọi giao dịch an toàn qua Escrow ChungCư.vn.</span>
  <button class="sec-close" onclick="this.parentElement.remove()">×</button>
</div>

<nav class="site-nav">
  <a href="${pageContext.request.contextPath}/home" class="nav-logo">
    ChungCư<span>.vn</span>
  </a>
  <ul class="nav-links" id="navMenu">
    <li><a href="${pageContext.request.contextPath}/apartments">Tìm kiếm</a></li>
    <li><a href="${pageContext.request.contextPath}/apartments?rentalType=short">Ngắn hạn</a></li>
    <li><a href="${pageContext.request.contextPath}/apartments?rentalType=long">Dài hạn</a></li>
    <li><a href="${pageContext.request.contextPath}/faq">Hỗ trợ</a></li>
    <c:if test="${not empty sessionScope.loggedUser}">
      <li><a href="${pageContext.request.contextPath}/user/apartment/post" class="nav-cta">+ Đăng tin</a></li>
    </c:if>
  </ul>
  <div class="nav-end">
    <c:choose>
      <c:when test="${not empty sessionScope.loggedUser}">
        <a href="${pageContext.request.contextPath}/user/notifications"
           style="width:38px;height:38px;display:flex;align-items:center;justify-content:center;color:var(--mid);font-size:18px;"
           title="Thông báo"><i class="fas fa-bell"></i></a>
        <div class="nav-dropdown" id="navDrop">
          <button class="nav-avatar-btn" id="avatarBtn">
            <span style="width:28px;height:28px;border-radius:50%;background:var(--dark);color:var(--accent);display:flex;align-items:center;justify-content:center;font-family:var(--serif);font-weight:700;font-size:13px;flex-shrink:0;">${sessionScope.loggedUser.firstLetter}</span>
            <span style="max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${sessionScope.loggedUser.fullName}</span>
            <i class="fas fa-chevron-down ch" style="font-size:10px;"></i>
          </button>
          <div class="dropdown-body">
            <div class="dd-head">
              <div class="dd-name">${sessionScope.loggedUser.fullName}</div>
              <div class="dd-email">${sessionScope.loggedUser.email}</div>
            </div>
            <a href="${pageContext.request.contextPath}/user/profile"><i class="fas fa-user"></i>Trang cá nhân</a>
            <a href="${pageContext.request.contextPath}/user/contracts"><i class="fas fa-file-contract"></i>Hợp đồng của tôi</a>
            <a href="${pageContext.request.contextPath}/user/payment/history"><i class="fas fa-receipt"></i>Lịch sử thanh toán</a>
            <a href="${pageContext.request.contextPath}/user/apartment/post" class="dd-accent"><i class="fas fa-plus-circle"></i>Đăng căn hộ</a>
            <c:choose>
              <c:when test="${sessionScope.loggedUser.admin}">
                <hr>
                <a href="${pageContext.request.contextPath}/admin/dashboard"><i class="fas fa-gauge-high"></i>Quản trị hệ thống</a>
                <a href="${pageContext.request.contextPath}/logout" style="color:#c0392b;font-weight:600;"><i class="fas fa-right-from-bracket" style="color:#c0392b;"></i>Đăng xuất</a>
              </c:when>
              <c:otherwise>
                <hr>
                <a href="${pageContext.request.contextPath}/logout" style="color:#c0392b;"><i class="fas fa-right-from-bracket" style="color:#c0392b;"></i>Đăng xuất</a>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </c:when>
      <c:otherwise>
        <a href="${pageContext.request.contextPath}/login"    class="btn btn-outline btn-sm">Đăng nhập</a>
        <a href="${pageContext.request.contextPath}/register" class="btn btn-dark   btn-sm">Đăng ký</a>
      </c:otherwise>
    </c:choose>
    <button class="nav-hamburger" id="hamburger"><i class="fas fa-bars"></i></button>
  </div>
</nav>
