# ApartmentRental — Hướng dẫn chạy trên NetBeans + Tomcat + MySQL

## Yêu cầu phần mềm

| Phần mềm | Phiên bản tối thiểu | Ghi chú |
|---|---|---|
| JDK | 21 | Eclipse Temurin / Oracle JDK đều được |
| NetBeans IDE | 21+ | Có Maven built-in |
| Apache Tomcat | **10.1.x** | **Bắt buộc 10.x** — Jakarta EE 10 |
| MySQL Server | 8.0+ | |
| MySQL Workbench | bất kỳ | Để import SQL |

> ⚠️ **Tomcat phải là bản 10.1.x** (không phải 9.x) vì project dùng `jakarta.*` namespace.

---

## Bước 1 — Khởi tạo Database

1. Mở **MySQL Workbench**, kết nối server `localhost:3306`
2. Vào menu **File → Open SQL Script** → chọn từng file theo thứ tự:

```
sql/apartment_rental.sql        ← Chạy trước (tạo DB + bảng chính)
sql/cc_dwh.sql                  ← Chạy sau (Data Warehouse)
sql/payment_v15_migration.sql   ← Thêm cột tx_ref
sql/indexes_v16.sql             ← Tạo indexes tối ưu
```

3. Nhấn **⚡ Execute** sau mỗi file (hoặc dùng Ctrl+Shift+Enter)

> Sau khi chạy xong, kiểm tra: `USE apartment_rental; SHOW TABLES;`

---

## Bước 2 — Cấu hình kết nối Database

Mở file:
```
src/main/java/com/rental/util/DBConnection.java
```

Tìm đoạn dưới và sửa nếu cần:
```java
String dbHost = "localhost";
String dbPort = "3306";
String dbName = "apartment_rental";
String dbUser = "root";
String dbPass = "1234";   // ← đổi thành mật khẩu MySQL của bạn
```

---

## Bước 3 — Cấu hình thanh toán VietQR / SePay

Mở file:
```
src/main/resources/config.properties
```

Điền thông tin ngân hàng của bạn:
```properties
bank.bin=970422              # BIN ngân hàng (tra tại api.vietqr.io/v2/banks)
bank.account_no=1234567890   # Số tài khoản nhận tiền
bank.account_name=NGUYEN VAN A
bank.name=MB Bank

sepay.api_key=...            # Lấy từ sepay.vn (để trống nếu test offline)
sepay.webhook_secret=...

qr.expire_minutes=15
```

> Nếu chỉ muốn test UI mà không cần thanh toán thật, có thể để nguyên giá trị mặc định.

---

## Bước 4 — Thêm Tomcat vào NetBeans

1. Vào **Tools → Servers → Add Server**
2. Chọn **Apache Tomcat or TomEE**
3. Trỏ đến thư mục cài Tomcat 10.1 (ví dụ: `C:\tomcat10`)
4. Nhấn **Finish**

---

## Bước 5 — Mở và chạy project

1. **File → Open Project** → chọn thư mục `ApartmentRental_NetBeans`
2. NetBeans nhận dạng Maven project tự động
3. Chuột phải project → **Clean and Build**
4. Chuột phải project → **Run** (chọn Tomcat 10.1 nếu hỏi)
5. Trình duyệt tự mở: `http://localhost:8080/ApartmentRental`

---

## Tài khoản mặc định (sau khi import SQL)

| Role | Email | Mật khẩu |
|---|---|---|
| Admin | admin@rental.com | 123456 |
| User | user@rental.com | 123456 |

> Kiểm tra trong bảng `users` của MySQL để xem tài khoản thực tế.

---

## Troubleshooting thường gặp

### Lỗi kết nối database
```
HikariPool: Connection is not available
```
→ Kiểm tra MySQL đang chạy, mật khẩu đúng trong `DBConnection.java`

### Lỗi 404 sau khi deploy
→ Đảm bảo deploy vào Tomcat **10.1.x** (không phải 9.x)

### Lỗi `ClassNotFoundException: com.mysql.cj.jdbc.Driver`
→ Chuột phải project → **Clean and Build** lại để Maven tải driver

### Tomcat không start
→ Kiểm tra port 8080 chưa bị chiếm: `netstat -ano | findstr 8080`

---

## Cấu trúc project

```
ApartmentRental_NetBeans/
├── pom.xml                         Maven config
├── nb-configuration.xml            NetBeans config (dùng Tomcat)
├── src/main/
│   ├── java/com/rental/
│   │   ├── dao/                    Data Access Objects
│   │   ├── model/                  Entity classes
│   │   ├── servlet/                HTTP Servlets
│   │   ├── filter/                 Auth + Encoding filters
│   │   ├── etl/                    ETL pipeline (Data Warehouse)
│   │   └── util/                   DBConnection, AppConfig, VietQR
│   ├── resources/
│   │   └── config.properties       ← Cấu hình ngân hàng, SePay
│   └── webapp/
│       ├── WEB-INF/
│       │   ├── web.xml
│       │   └── views/              JSP pages
│       ├── css/
│       ├── js/
│       └── index.jsp
└── sql/
    ├── apartment_rental.sql        Schema OLTP
    ├── cc_dwh.sql                  Schema Data Warehouse
    ├── payment_v15_migration.sql   Migration v15
    └── indexes_v16.sql             Performance indexes
```
