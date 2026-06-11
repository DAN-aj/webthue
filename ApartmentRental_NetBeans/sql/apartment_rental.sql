-- ================================================================
-- apartment_rental.sql
-- Database OLTP: apartment_rental
-- Chạy 1 lần để khởi tạo toàn bộ schema + performance indexes
-- MySQL 8.0+ | Encoding: UTF-8
--
-- Bao gồm:
--   1. Schema tất cả bảng OLTP
--   2. Composite indexes tối ưu cho dashboard queries
-- ================================================================

DROP DATABASE IF EXISTS apartment_rental;
CREATE DATABASE apartment_rental
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE apartment_rental;

-- ────────────────────────────────────────────────────────────────
-- 1. USERS
-- ────────────────────────────────────────────────────────────────
CREATE TABLE users (
    user_id    INT AUTO_INCREMENT PRIMARY KEY,
    full_name  VARCHAR(100) NOT NULL,
    email      VARCHAR(100) NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,
    phone      VARCHAR(20),
    cccd       VARCHAR(20),
    role       ENUM('admin', 'user') DEFAULT 'user',
    status     ENUM('active', 'locked') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role  (role)
) ENGINE=InnoDB COMMENT='Tài khoản người dùng';

-- ────────────────────────────────────────────────────────────────
-- 2. APARTMENTS
-- ────────────────────────────────────────────────────────────────
CREATE TABLE apartments (
    apt_id            INT AUTO_INCREMENT PRIMARY KEY,
    owner_id          INT NOT NULL,
    title             VARCHAR(255) NOT NULL,
    address           VARCHAR(255) NOT NULL,
    district          VARCHAR(100),
    city              VARCHAR(100) DEFAULT 'Hà Nội',
    type              ENUM('studio','1br','2br','3br') DEFAULT '1br',
    area              FLOAT NOT NULL CHECK (area > 0),
    floor             INT DEFAULT 1,
    total_floors      INT DEFAULT 1,
    bedrooms          INT DEFAULT 1,
    bathrooms         INT DEFAULT 1,
    furniture         ENUM('Nguyên bản','Cơ bản','Full gỗ','Full') DEFAULT 'Nguyên bản',
    direction         ENUM('ĐB','ĐN','TN','TB'),
    view              ENUM('Hồ','Ngoại khu','Nội khu'),
    amenities         TEXT,
    description       TEXT,
    rent_price        DECIMAL(12,0) NOT NULL COMMENT 'Giá mặc định',
    rent_price_month  DECIMAL(12,0) DEFAULT NULL COMMENT 'Giá thuê dài hạn',
    rent_price_day    DECIMAL(12,0) DEFAULT NULL COMMENT 'Giá thuê ngắn hạn theo ngày',
    deposit_months    INT DEFAULT 2,
    rental_type       ENUM('short','long','both') DEFAULT 'both',
    min_rental_months INT DEFAULT 1,
    payment_period    INT DEFAULT 1,
    status            ENUM('pending','approved','rejected','rented','unavailable') DEFAULT 'pending',
    reject_reason     VARCHAR(500),
    view_count        INT DEFAULT 0,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_apt_owner FOREIGN KEY (owner_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_apt_status            (status),
    INDEX idx_apt_city_district     (city, district),
    INDEX idx_apt_owner             (owner_id),
    INDEX idx_apt_created           (created_at),
    INDEX idx_apt_rent_price        (rent_price_month),
    -- Dashboard: avgAptPerOwner, occupancy
    INDEX idx_apt_status_dist_owner (status, district, owner_id)
) ENGINE=InnoDB COMMENT='Căn hộ cho thuê';

-- ────────────────────────────────────────────────────────────────
-- 3. APARTMENT IMAGES
-- ────────────────────────────────────────────────────────────────
CREATE TABLE apartment_images (
    image_id   INT AUTO_INCREMENT PRIMARY KEY,
    apt_id     INT NOT NULL,
    image_url  VARCHAR(500) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_img_apt FOREIGN KEY (apt_id) REFERENCES apartments(apt_id) ON DELETE CASCADE,
    INDEX idx_img_apt (apt_id)
) ENGINE=InnoDB COMMENT='Ảnh căn hộ';

-- ────────────────────────────────────────────────────────────────
-- 4. CONTRACTS
-- ────────────────────────────────────────────────────────────────
CREATE TABLE contracts (
    contract_id          INT AUTO_INCREMENT PRIMARY KEY,
    apt_id               INT NOT NULL,
    tenant_id            INT NOT NULL,
    owner_id             INT NOT NULL,
    rental_type          ENUM('short','long') NOT NULL,
    start_date           DATE NOT NULL,
    end_date             DATE NOT NULL,
    total_days           INT DEFAULT 0,
    monthly_rent         DECIMAL(12,0) NOT NULL,
    deposit_amount       DECIMAL(12,0) DEFAULT 0,
    platform_fee         DECIMAL(12,0) NOT NULL,
    payment_period       INT DEFAULT 1,
    tenant_cccd          VARCHAR(20),
    status               ENUM('pending','approved','rejected','active','expired','terminated') DEFAULT 'pending',
    notes                TEXT,
    move_in_confirmed    BOOLEAN DEFAULT FALSE,
    move_in_confirmed_at TIMESTAMP NULL,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_con_apt    FOREIGN KEY (apt_id)    REFERENCES apartments(apt_id),
    CONSTRAINT fk_con_tenant FOREIGN KEY (tenant_id) REFERENCES users(user_id),
    CONSTRAINT fk_con_owner  FOREIGN KEY (owner_id)  REFERENCES users(user_id),
    CONSTRAINT chk_dates     CHECK (end_date >= start_date),

    -- Indexes cơ bản
    INDEX idx_con_status  (status),
    INDEX idx_con_apt     (apt_id),
    INDEX idx_con_tenant  (tenant_id),
    INDEX idx_con_owner   (owner_id),
    INDEX idx_con_created (created_at),

    -- Composite indexes tối ưu dashboard (800K+ rows)
    -- SUM(platform_fee) WHERE status IN ('active','expired')
    INDEX idx_con_status_fee         (status, platform_fee),
    -- SUM revenue trong khoảng thời gian
    INDEX idx_con_status_created_fee (status, created_at, platform_fee),
    -- Overdue pending query
    INDEX idx_con_created_status     (created_at, status),
    -- revenueByDistrict JOIN → push condition vào ON clause
    INDEX idx_con_apt_status_fee     (apt_id, status, platform_fee),
    -- GROUP BY rental_type
    INDEX idx_con_rental_type        (rental_type)
) ENGINE=InnoDB COMMENT='Hợp đồng thuê căn hộ';

-- ────────────────────────────────────────────────────────────────
-- 5. PAYMENTS
-- ────────────────────────────────────────────────────────────────
CREATE TABLE payments (
    payment_id       INT AUTO_INCREMENT PRIMARY KEY,
    contract_id      INT NOT NULL,
    payer_id         INT NOT NULL,
    amount           DECIMAL(12,0) NOT NULL,
    payment_type     ENUM('initial','periodic','deposit','penalty') NOT NULL,
    period_month     INT COMMENT 'Kỳ thứ n',
    payment_method   ENUM('bank_qr','card') DEFAULT 'bank_qr',
    transaction_code VARCHAR(100),
    status           ENUM('pending','success','failed') DEFAULT 'pending',
    due_date         DATE,
    paid_date        TIMESTAMP NULL,
    note             VARCHAR(500),
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_pay_con   FOREIGN KEY (contract_id) REFERENCES contracts(contract_id),
    CONSTRAINT fk_pay_payer FOREIGN KEY (payer_id)    REFERENCES users(user_id),
    INDEX idx_pay_status      (status),
    INDEX idx_pay_transaction (transaction_code),
    INDEX idx_pay_contract    (contract_id),
    INDEX idx_pay_payer       (payer_id)
) ENGINE=InnoDB COMMENT='Thanh toán';

-- ────────────────────────────────────────────────────────────────
-- 6. NOTIFICATIONS
-- ────────────────────────────────────────────────────────────────
CREATE TABLE notifications (
    noti_id      INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    title        VARCHAR(255) NOT NULL,
    message      TEXT NOT NULL,
    type         ENUM('info','success','warning','payment','contract') DEFAULT 'info',
    is_read      BOOLEAN DEFAULT FALSE,
    related_id   INT,
    related_type VARCHAR(50),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_noti_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_noti_user_read (user_id, is_read)
) ENGINE=InnoDB COMMENT='Thông báo';

-- ────────────────────────────────────────────────────────────────
-- 7. APARTMENT EDIT REQUESTS
-- ────────────────────────────────────────────────────────────────
CREATE TABLE apartment_edit_requests (
    request_id           INT AUTO_INCREMENT PRIMARY KEY,
    apt_id               INT NOT NULL,
    owner_id             INT NOT NULL,
    new_title            VARCHAR(255),
    new_description      TEXT,
    new_rent_price_month DECIMAL(12,0),
    new_rent_price_day   DECIMAL(12,0),
    new_deposit_months   INT,
    new_payment_period   INT,
    new_amenities        TEXT,
    new_bedrooms         INT,
    new_bathrooms        INT,
    new_area             FLOAT,
    status               ENUM('pending','approved','rejected') DEFAULT 'pending',
    reject_reason        VARCHAR(500),
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at          TIMESTAMP NULL,

    CONSTRAINT fk_edit_apt   FOREIGN KEY (apt_id)   REFERENCES apartments(apt_id),
    CONSTRAINT fk_edit_owner FOREIGN KEY (owner_id) REFERENCES users(user_id),
    INDEX idx_edit_status (status),
    INDEX idx_edit_owner  (owner_id)
) ENGINE=InnoDB COMMENT='Yêu cầu chỉnh sửa căn hộ';

-- ────────────────────────────────────────────────────────────────
-- VERIFY
-- ────────────────────────────────────────────────────────────────
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'apartment_rental'
ORDER BY table_name;

-- ── REVIEWS (đánh giá căn hộ) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
    review_id    INT AUTO_INCREMENT PRIMARY KEY,
    apt_id       INT NOT NULL,
    user_id      INT NOT NULL,
    contract_id  INT NOT NULL,                     -- ràng buộc: phải có hợp đồng thực
    rating       TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment      TEXT NOT NULL,
    status       ENUM('pending','approved','rejected') DEFAULT 'pending',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_user_apt (user_id, apt_id),      -- mỗi người chỉ review 1 lần / căn hộ
    FOREIGN KEY (apt_id)      REFERENCES apartments(apt_id)  ON DELETE CASCADE,
    FOREIGN KEY (user_id)     REFERENCES users(user_id)      ON DELETE CASCADE,
    FOREIGN KEY (contract_id) REFERENCES contracts(contract_id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Đánh giá căn hộ — chỉ người đã thuê mới được viết';
