<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Trợ giúp & FAQ — ChungCư.vn"/>
<%@ include file="includes/header.jsp" %>

<div class="page-strip">
  <div style="padding:60px 80px;">
    <span class="eyebrow">Hỗ trợ khách hàng</span>
    <h1>Câu hỏi thường gặp</h1>
    <p style="color:rgba(255,255,255,.45);font-size:14px;max-width:560px;line-height:1.8;">
      Mọi thắc mắc về thuê căn hộ, hợp đồng, thanh toán và chính sách bảo vệ người dùng đều có tại đây.
    </p>
  </div>
</div>

<div class="container" style="max-width:860px;padding-top:60px;padding-bottom:100px;">

  <%-- Quick contact bar --%>
  <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:2px;background:var(--border);margin-bottom:60px;">
    <div style="background:var(--white);padding:28px;text-align:center;">
      <div style="font-size:28px;margin-bottom:10px;">✉️</div>
      <div style="font-family:var(--serif);font-weight:600;font-size:15px;margin-bottom:4px;">Email hỗ trợ</div>
      <a href="mailto:hotro@chungcu.vn" style="font-size:13px;color:var(--accent);">hotro@chungcu.vn</a>
    </div>
    <div style="background:var(--white);padding:28px;text-align:center;">
      <div style="font-size:28px;margin-bottom:10px;">📞</div>
      <div style="font-family:var(--serif);font-weight:600;font-size:15px;margin-bottom:4px;">Hotline</div>
      <a href="tel:19001234" style="font-size:13px;color:var(--accent);">1900 1234</a>
      <div style="font-size:11px;color:var(--light);margin-top:4px;">Thứ 2–6 · 8:00–18:00</div>
    </div>
    <div style="background:var(--white);padding:28px;text-align:center;">
      <div style="font-size:28px;margin-bottom:10px;">💬</div>
      <div style="font-family:var(--serif);font-weight:600;font-size:15px;margin-bottom:4px;">Chat trực tuyến</div>
      <span style="font-size:13px;color:var(--light);">Sắp ra mắt</span>
    </div>
  </div>

  <%-- FAQ Categories --%>
  <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:40px;" id="faqCats">
    <button class="faq-cat-btn on" onclick="filterFaq('all',this)">Tất cả</button>
    <button class="faq-cat-btn" onclick="filterFaq('account',this)">Tài khoản</button>
    <button class="faq-cat-btn" onclick="filterFaq('rent',this)">Thuê căn hộ</button>
    <button class="faq-cat-btn" onclick="filterFaq('contract',this)">Hợp đồng</button>
    <button class="faq-cat-btn" onclick="filterFaq('payment',this)">Thanh toán</button>
    <button class="faq-cat-btn" onclick="filterFaq('owner',this)">Chủ nhà</button>
    <button class="faq-cat-btn" onclick="filterFaq('policy',this)">Chính sách</button>
  </div>

  <div id="faqList">

    <%-- ACCOUNT --%>
    <div class="faq-section" data-cat="account">
      <h2 class="sec-title" style="margin-bottom:20px;">Tài khoản</h2>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Tôi quên mật khẩu, làm sao lấy lại?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Hiện tại vui lòng liên hệ email <strong>hotro@chungcu.vn</strong> với tiêu đề
          "Lấy lại mật khẩu" kèm email đăng ký. Chúng tôi sẽ xử lý trong vòng 24 giờ.
          Tính năng tự đặt lại mật khẩu qua email sẽ sớm được cập nhật.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Một người có thể tạo nhiều tài khoản không?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Không. Mỗi người chỉ được sử dụng một tài khoản. Tạo nhiều tài khoản vi phạm điều khoản
          sử dụng và có thể bị khóa toàn bộ.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Làm sao cập nhật thông tin cá nhân?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Vào menu avatar ở góc trên phải → <strong>Trang cá nhân</strong> → chỉnh sửa họ tên,
          số điện thoại, avatar và lưu. Email đăng ký không thể thay đổi.
        </div>
      </div>
    </div>

    <%-- RENT --%>
    <div class="faq-section" data-cat="rent">
      <h2 class="sec-title" style="margin-top:40px;margin-bottom:20px;">Thuê căn hộ</h2>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Địa chỉ đầy đủ của căn hộ ở đâu?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Để bảo vệ quyền riêng tư, địa chỉ chi tiết và số điện thoại chủ nhà chỉ hiển thị
          <strong>sau khi hợp đồng được xác nhận và thanh toán</strong>. Trước đó bạn chỉ thấy
          quận/huyện và thành phố.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Tôi có thể xem căn hộ trực tiếp trước khi thuê không?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Có. Sau khi đặt hợp đồng và trước khi thanh toán, bạn liên hệ chủ nhà qua hệ thống
          để sắp xếp xem thực tế. Chúng tôi khuyến nghị luôn xem trực tiếp đối với thuê dài hạn.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Ngắn hạn và dài hạn khác nhau như thế nào?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          <strong>Ngắn hạn:</strong> tính theo ngày, thanh toán một lần toàn bộ, không có tiền cọc riêng.
          <strong>Dài hạn:</strong> tính theo tháng, thanh toán theo kỳ (mỗi 1–3 tháng), có đặt cọc
          thường bằng 1–2 tháng tiền thuê.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Tôi muốn hủy yêu cầu thuê sau khi đã gửi?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Bạn có thể hủy yêu cầu khi hợp đồng còn ở trạng thái <strong>Chờ xác nhận</strong>
          (pending). Vào <em>Hợp đồng của tôi</em> → chi tiết hợp đồng → nhấn
          <em>Hủy yêu cầu</em>. Sau khi chủ nhà đã chấp thuận và bạn đã thanh toán, việc hủy
          theo chính sách hoàn tiền (xem mục Chính sách).
        </div>
      </div>
    </div>

    <%-- CONTRACT --%>
    <div class="faq-section" data-cat="contract">
      <h2 class="sec-title" style="margin-top:40px;margin-bottom:20px;">Hợp đồng</h2>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Vòng đời một hợp đồng thuê diễn ra như thế nào?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          <ol style="padding-left:18px;line-height:2;">
            <li>Người thuê gửi yêu cầu → trạng thái <strong>Chờ xác nhận</strong></li>
            <li>Chủ nhà chấp thuận → <strong>Chờ thanh toán</strong></li>
            <li>Người thuê thanh toán kỳ đầu → <strong>Đang hoạt động</strong></li>
            <li>Thanh toán các kỳ tiếp (dài hạn) cho đến hết thời hạn</li>
            <li>Kết thúc hợp đồng → <strong>Đã hoàn thành</strong></li>
          </ol>
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Hợp đồng có giá trị pháp lý không?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Hợp đồng trên ChungCư.vn là hợp đồng điện tử có xác nhận của cả hai bên.
          Chúng tôi khuyến nghị in ra và ký tay thêm bản cứng đối với thuê dài hạn từ 6 tháng
          trở lên để đảm bảo giá trị pháp lý đầy đủ.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Tiền đặt cọc được xử lý như thế nào khi kết thúc hợp đồng?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Sau khi hợp đồng kết thúc và hai bên xác nhận không có tranh chấp, tiền cọc được
          hoàn lại qua tài khoản ngân hàng trong vòng 5–7 ngày làm việc.
          Nếu có tranh chấp, đội ngũ ChungCư.vn sẽ hòa giải dựa trên điều khoản hợp đồng.
        </div>
      </div>
    </div>

    <%-- PAYMENT --%>
    <div class="faq-section" data-cat="payment">
      <h2 class="sec-title" style="margin-top:40px;margin-bottom:20px;">Thanh toán</h2>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Tôi có thể thanh toán bằng những phương thức nào?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Hiện hỗ trợ: <strong>Chuyển khoản QR ngân hàng</strong> (VCB, TCB, MB, ACB, BIDV, TP, Agribank),
          <strong>Thẻ tín dụng/ghi nợ</strong> (Visa, Mastercard, JCB), và
          <strong>Ví điện tử</strong> (MoMo, ZaloPay, VNPay). Tích hợp cổng thanh toán thực
          sẽ được triển khai trong bản cập nhật tiếp theo.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Phí nền tảng là bao nhiêu?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          ChungCư.vn thu <strong>5%</strong> phí dịch vụ tính trên mỗi giao dịch,
          do <em>chủ nhà</em> chịu (người thuê không phát sinh thêm). Phí này đã hiển thị rõ
          trong trang hợp đồng trước khi xác nhận.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Tôi đã chuyển khoản nhưng hệ thống chưa cập nhật?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Xác nhận thanh toán thủ công thường mất 1–30 phút trong giờ hành chính.
          Nếu sau 2 tiếng vẫn chưa cập nhật, gửi ảnh chụp màn hình giao dịch về
          <strong>hotro@chungcu.vn</strong> kèm mã hợp đồng.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Escrow là gì và tại sao phải dùng?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Escrow là cơ chế giữ tiền trung gian: tiền của bạn được giữ an toàn bởi ChungCư.vn
          và chỉ chuyển đến chủ nhà <strong>sau khi bạn nhận phòng thành công</strong>.
          Điều này bảo vệ người thuê khỏi lừa đảo và bảo vệ chủ nhà khỏi mất tiền ảo.
        </div>
      </div>
    </div>

    <%-- OWNER --%>
    <div class="faq-section" data-cat="owner">
      <h2 class="sec-title" style="margin-top:40px;margin-bottom:20px;">Dành cho chủ nhà</h2>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Đăng tin căn hộ mất bao lâu để được duyệt?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Đội ngũ kiểm duyệt xử lý trong vòng <strong>24 giờ</strong> trong ngày làm việc
          (Thứ 2–6). Bạn sẽ nhận thông báo qua hệ thống khi tin được duyệt hoặc từ chối kèm lý do.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Tôi muốn chỉnh sửa thông tin căn hộ đã đăng?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Vào <em>Trang cá nhân</em> → tab <em>Căn hộ của tôi</em> → nhấn <em>Chỉnh sửa</em>.
          Sau khi gửi, thay đổi cần được admin duyệt lại trước khi hiển thị công khai.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Tôi nhận tiền thuê qua đâu?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Sau khi người thuê xác nhận nhận phòng, số tiền (sau khi trừ phí 5%) được chuyển
          về tài khoản ngân hàng bạn đăng ký trong hồ sơ. Thường mất 1–3 ngày làm việc.
        </div>
      </div>
    </div>

    <%-- POLICY --%>
    <div class="faq-section" data-cat="policy">
      <h2 class="sec-title" style="margin-top:40px;margin-bottom:20px;">Chính sách</h2>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Chính sách hoàn tiền khi hủy hợp đồng?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          <table style="width:100%;border-collapse:collapse;font-size:13px;margin-top:8px;">
            <thead>
              <tr style="background:var(--cream);">
                <th style="padding:10px 14px;text-align:left;border-bottom:1px solid var(--border);font-size:11px;letter-spacing:1px;text-transform:uppercase;color:var(--light);">Thời điểm hủy</th>
                <th style="padding:10px 14px;text-align:left;border-bottom:1px solid var(--border);font-size:11px;letter-spacing:1px;text-transform:uppercase;color:var(--light);">Mức hoàn</th>
              </tr>
            </thead>
            <tbody>
              <tr><td style="padding:10px 14px;border-bottom:1px solid var(--border);color:var(--mid);">Trước 48 giờ nhận phòng</td><td style="padding:10px 14px;border-bottom:1px solid var(--border);color:var(--success);font-weight:600;">Hoàn 100%</td></tr>
              <tr><td style="padding:10px 14px;border-bottom:1px solid var(--border);color:var(--mid);">Trước 24 giờ</td><td style="padding:10px 14px;border-bottom:1px solid var(--border);color:var(--warn);font-weight:600;">Hoàn 50%</td></tr>
              <tr><td style="padding:10px 14px;color:var(--mid);">Sau khi nhận phòng</td><td style="padding:10px 14px;color:var(--danger);font-weight:600;">Không hoàn</td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          Báo cáo chủ nhà hoặc người thuê vi phạm?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Gửi email đến <strong>baocao@chungcu.vn</strong> kèm: mã hợp đồng, mô tả vi phạm,
          và bằng chứng (ảnh/video/tin nhắn). Chúng tôi cam kết xử lý trong 48 giờ và
          bảo mật danh tính người báo cáo.
        </div>
      </div>

      <div class="faq-item">
        <button class="faq-q" onclick="toggleFaq(this)">
          ChungCư.vn có bảo vệ dữ liệu cá nhân không?
          <span class="faq-arrow">▾</span>
        </button>
        <div class="faq-a">
          Có. Chúng tôi mã hóa mọi thông tin nhạy cảm và không chia sẻ dữ liệu cá nhân cho
          bên thứ ba vì mục đích thương mại. Địa chỉ và số điện thoại chỉ hiển thị giữa
          hai bên có hợp đồng hợp lệ.
        </div>
      </div>
    </div>

  </div><%-- end #faqList --%>

  <%-- Still need help --%>
  <div style="margin-top:72px;background:var(--dark);padding:48px;text-align:center;">
    <span class="eyebrow" style="color:rgba(255,255,255,.3);">Vẫn chưa tìm thấy câu trả lời?</span>
    <h2 style="font-family:var(--serif);font-size:28px;font-weight:700;color:var(--white);margin:12px 0 8px;">
      Liên hệ đội ngũ hỗ trợ
    </h2>
    <p style="color:rgba(255,255,255,.4);font-size:14px;margin-bottom:28px;line-height:1.75;">
      Chúng tôi phản hồi trong vòng 4 giờ trong ngày làm việc.
    </p>
    <a href="mailto:hotro@chungcu.vn" class="btn btn-accent btn-lg">
      ✉ Gửi email hỗ trợ
    </a>
  </div>

</div><%-- end .container --%>

<style>
.faq-cat-btn{padding:8px 18px;border:1px solid var(--border);background:var(--white);color:var(--mid);font-family:var(--sans);font-size:12px;font-weight:500;letter-spacing:.5px;text-transform:uppercase;cursor:pointer;transition:all .15s;}
.faq-cat-btn.on,.faq-cat-btn:hover{background:var(--dark);color:var(--white);border-color:var(--dark);}
.faq-item{border-bottom:1px solid var(--border);}
.faq-q{width:100%;text-align:left;background:none;border:none;padding:18px 0;font-family:var(--sans);font-size:15px;font-weight:500;color:var(--dark);cursor:pointer;display:flex;align-items:center;justify-content:space-between;gap:16px;line-height:1.5;}
.faq-q:hover{color:var(--accent);}
.faq-arrow{font-size:18px;color:var(--light);transition:transform .2s;flex-shrink:0;}
.faq-q.open .faq-arrow{transform:rotate(180deg);}
.faq-a{display:none;padding:0 0 20px;font-size:14px;line-height:1.8;color:var(--mid);}
.faq-a.open{display:block;}
.faq-section{display:block;}
.faq-section.hidden{display:none;}
</style>

<script>
function toggleFaq(btn) {
  btn.classList.toggle('open');
  var ans = btn.nextElementSibling;
  ans.classList.toggle('open');
}
function filterFaq(cat, clickedBtn) {
  document.querySelectorAll('.faq-cat-btn').forEach(function(b){ b.classList.remove('on'); });
  clickedBtn.classList.add('on');
  document.querySelectorAll('.faq-section').forEach(function(sec){
    if (cat === 'all' || sec.dataset.cat === cat) sec.classList.remove('hidden');
    else sec.classList.add('hidden');
  });
}
</script>

<%@ include file="includes/footer.jsp" %>
