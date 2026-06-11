# ApartmentRental — Hướng dẫn cài đặt từ đầu trên máy mới

> Hướng dẫn này dành cho máy chưa có gì. Làm đúng thứ tự từ Bước 1 → Bước 6 là chạy được.

---

## Yêu cầu phần mềm

| Phần mềm | Phiên bản | Tải tại |
|---|---|---|
| JDK | **21** (LTS) | https://adoptium.net — chọn Temurin 21 |
| NetBeans IDE | **21+** | https://netbeans.apache.org — bản Full |
| Apache Tomcat | **10.1.x** ⚠️ | https://tomcat.apache.org — mục 10.1 |
| MySQL Server | **8.0+** | https://dev.mysql.com/downloads/installer |
| MySQL Workbench | bất kỳ | Cài kèm trong MySQL Installer ở trên |

> ⚠️ **Tomcat bắt buộc phải là bản 10.1.x** — không phải 9.x hay 11.x.
> Project dùng `jakarta.*` namespace, chỉ Tomcat 10+ mới hỗ trợ. Sai version sẽ báo lỗi ngay khi deploy.

---

## Bước 1 — Cài JDK 21

1. Vào https://adoptium.net, tải **Temurin 21 LTS**
2. Cài như bình thường (Next → Next → Finish)
3. Kiểm tra cài thành công, mở Command Prompt gõ:
   ```
   java -version
   ```
   Kết quả phải hiện `openjdk version "21..."`

---

## Bước 2 — Cài NetBeans + Tomcat

### NetBeans
1. Vào https://netbeans.apache.org → tải bản **Full** (không phải SE hay PHP)
2. Cài như bình thường

### Tomcat 10.1.x
1. Vào https://tomcat.apache.org → chọn mục **Tomcat 10** ở cột trái
2. Tải file **zip** (ví dụ: `apache-tomcat-10.1.x-windows-x64.zip`)
3. **Giải nén** ra thư mục cố định, ví dụ: `C:\tomcat10` hoặc `D:\tomcat10`
   - Không để trong thư mục có khoảng trắng trong tên (tránh `C:\Program Files`)

### Thêm Tomcat vào NetBeans
1. Mở NetBeans → vào **Tools → Servers → Add Server**
2. Chọn **Apache Tomcat or TomEE** → Next
3. Trỏ **Server Location** đến thư mục Tomcat vừa giải nén (ví dụ: `C:\tomcat10`)
4. Nhấn **Finish**

---

## Bước 3 — Cài MySQL + khởi tạo Database

### Cài MySQL
1. Vào https://dev.mysql.com/downloads/installer, tải **MySQL Installer**
2. Chạy installer, chọn **Custom** hoặc **Developer Default**
3. Đảm bảo cài đủ: **MySQL Server 8.0** và **MySQL Workbench**
4. Đặt mật khẩu cho user `root` — **nhớ mật khẩu này**, dùng ở bước sau

### Khởi tạo Database
Chạy lần lượt **4 file SQL** trong thư mục `sql/` theo đúng thứ tự:

| Thứ tự | File | Tác dụng |
|---|---|---|
| 1 | `apartment_rental.sql` | Tạo database chính + toàn bộ bảng OLTP |
| 2 | `cc_dwh.sql` | Tạo database Data Warehouse |
| 3 | `payment_v15_migration.sql` | Thêm cột `tx_ref` vào bảng payments |
| 4 | `indexes_v16.sql` | Tạo indexes tối ưu hiệu năng |

Cách chạy mỗi file trong MySQL Workbench:
1. Mở Workbench → kết nối `localhost` bằng user `root` + mật khẩu vừa đặt
2. **File → Open SQL Script** → chọn file
3. Nhấn ⚡ **Execute** (hoặc Ctrl+Shift+Enter)
4. Làm lại với file tiếp theo

> Chạy đúng thứ tự 1 → 2 → 3 → 4. File 2, 3, 4 phụ thuộc vào file trước đó.

Kiểm tra sau khi xong, chạy lệnh này trong Workbench:
```sql
USE apartment_rental;
SHOW TABLES;
```
Phải hiện ra danh sách các bảng: `users`, `apartments`, `contracts`, `payments`...

---

## Bước 4 — Cấu hình kết nối Database

Mở file:
```
src/main/java/com/rental/util/DBConnection.java
```

Tìm đoạn này (khoảng dòng 20) và sửa mật khẩu:
```java
String dbHost = "localhost";
String dbPort = "3306";
String dbName = "apartment_rental";
String dbUser = "root";
String dbPass = "1234";   // <- đổi thành mật khẩu root MySQL của bạn
```

Chỉ cần đổi `dbPass`. Các thông số còn lại giữ nguyên nếu cài MySQL mặc định.

---

## Bước 5 — Cấu hình thanh toán VietQR (tùy chọn)

> Bỏ qua bước này nếu chỉ muốn chạy thử UI. Hệ thống vẫn hoạt động bình thường,
> chỉ phần tạo QR thanh toán sẽ không có dữ liệu thật.

Mở file:
```
src/main/resources/config.properties
```

Điền thông tin ngân hàng nhận tiền:
```properties
# BIN ngân hàng - tra danh sách tại: https://api.vietqr.io/v2/banks
# Ví dụ: MB Bank = 970422 | Vietcombank = 970436 | Techcombank = 970407
bank.bin=970422
bank.account_no=YOUR_ACCOUNT_NUMBER
bank.account_name=NGUYEN VAN A
bank.name=MB Bank

# SePay - đăng ký miễn phí tại https://sepay.vn
# Để trống nếu không cần webhook xác nhận thanh toán tự động
sepay.api_key=YOUR_SEPAY_API_KEY
sepay.webhook_secret=YOUR_SEPAY_WEBHOOK_SECRET

# Thời gian hết hạn QR (phút)
qr.expire_minutes=15
```

---

## Bước 6 — Mở và chạy trong NetBeans

1. **File → Open Project** → chọn thư mục `ApartmentRental_NetBeans`
   - NetBeans tự nhận dạng Maven project, không cần làm gì thêm

2. Chuột phải project → **Properties → Run**
   - **Server**: chọn `Tomcat 10.1`
   - **Context Path**: `/ApartmentRental`
   - Nhấn OK

3. Chuột phải project → **Clean and Build**
   - Lần đầu Maven tải dependencies từ internet, mất khoảng 1–3 phút
   - Phải có kết nối internet cho bước này

4. Nhấn **Run** (hoặc F6)
   - Tomcat khởi động, trình duyệt tự mở

5. Truy cập:
   ```
   http://localhost:8080/ApartmentRental
   ```

---

## Tài khoản mặc định

| Role | Email | Mật khẩu |
|---|---|---|
| Admin | admin@rental.com | 123456 |
| User | user@rental.com | 123456 |

> Kiểm tra bảng `users` trong MySQL Workbench để xem đầy đủ danh sách tài khoản.

---

## Workflow hàng ngày (sau khi đã setup xong)

Mỗi lần muốn chạy, chỉ cần:
1. Đảm bảo MySQL Service đang chạy (kiểm tra trong Services của Windows)
2. Mở NetBeans → mở project → nhấn **Run**
3. Sửa code → NetBeans tự recompile và redeploy, không cần làm gì thêm

---

## Troubleshooting thường gặp

### Lỗi kết nối database khi start
```
HikariPool-1 - Connection is not available
```
Kiểm tra MySQL Service trong Task Manager → Services đang chạy chưa.
Kiểm tra mật khẩu trong `DBConnection.java` có đúng không.

### Lỗi 404 sau khi deploy
Sai phiên bản Tomcat. Phải dùng **Tomcat 10.1.x**, không phải 9.x.

### Lỗi ClassNotFoundException: com.mysql.cj.jdbc.Driver
Chuột phải project → **Clean and Build** lại để Maven tải MySQL driver.

### Lỗi BUILD FAILED khi Clean and Build
Mất kết nối internet lần đầu build. Kết nối lại và thử **Clean and Build** lần nữa.

### Port 8080 đã bị chiếm
Kiểm tra bằng lệnh:
```
netstat -ano | findstr 8080
```
Tắt ứng dụng đang dùng port 8080 (có thể là Docker đang chạy) rồi Run lại.

### Docker cũ và NetBeans cùng chạy
2 cái không thể cùng dùng port 8080. Chọn 1 trong 2:
- Tắt Docker trước khi Run NetBeans: `docker compose down`
- Hoặc đổi port Docker sang 8081 trong `docker-compose.yml`: `"8081:8080"`

---

## Cấu trúc project

```
ApartmentRental_NetBeans/
├── pom.xml                          Maven dependencies
├── nb-configuration.xml             NetBeans config (server = Tomcat)
├── README.md                        File này
├── sql/
│   ├── apartment_rental.sql         Schema OLTP (chạy trước)
│   ├── cc_dwh.sql                   Schema Data Warehouse
│   ├── payment_v15_migration.sql    Migration v15 (thêm tx_ref)
│   └── indexes_v16.sql              Performance indexes (chạy sau cùng)
└── src/main/
    ├── java/com/rental/
    │   ├── dao/                     Truy vấn database
    │   ├── model/                   Entity classes (User, Apartment...)
    │   ├── servlet/                 HTTP request handlers
    │   ├── filter/                  Auth + Encoding filters
    │   ├── etl/                     ETL pipeline cho Data Warehouse
    │   └── util/
    │       ├── DBConnection.java    <- Sửa mật khẩu DB tại đây
    │       ├── AppConfig.java       Đọc config.properties
    │       └── VietQRService.java   Tạo QR thanh toán
    ├── resources/
    │   └── config.properties        <- Cấu hình ngân hàng, SePay
    └── webapp/
        ├── WEB-INF/
        │   ├── web.xml              Servlet mappings
        │   └── views/               JSP pages
        ├── css/
        ├── js/
        └── index.jsp
```
