-- ================================================================
-- cc_dwh.sql
-- Database DWH: cc_dwh
-- Chạy 1 lần để khởi tạo toàn bộ schema DWH
-- MySQL 8.0+ | Encoding: UTF-8
--
-- Bao gồm:
--   1. Dimension tables (dim_time, dim_location, dim_user, dim_apartment)
--   2. Fact tables (fact_contracts, fact_payments)
--   3. Aggregation tables (agg_daily_revenue, agg_occupancy_rate)
--   4. ETL infrastructure (etl_watermark, etl_audit_log)
--   5. Views cho Power BI
--   6. Fix stuck ETL jobs (nếu có)
-- ================================================================

DROP DATABASE IF EXISTS cc_dwh;
CREATE DATABASE cc_dwh
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cc_dwh;

-- ────────────────────────────────────────────────────────────────
-- DIMENSION: dim_time
-- ────────────────────────────────────────────────────────────────
CREATE TABLE dim_time (
    date_key     INT         PRIMARY KEY COMMENT 'YYYYMMDD',
    full_date    DATE        NOT NULL UNIQUE,
    day_of_week  TINYINT     NOT NULL COMMENT '1=Mon..7=Sun',
    day_name     VARCHAR(15) NOT NULL,
    week_of_year TINYINT     NOT NULL,
    month_num    TINYINT     NOT NULL,
    month_name   VARCHAR(15) NOT NULL,
    quarter      TINYINT     NOT NULL,
    year_num     SMALLINT    NOT NULL,
    is_weekend   BOOLEAN     DEFAULT FALSE,
    is_holiday   BOOLEAN     DEFAULT FALSE
) ENGINE=InnoDB COMMENT='Chiều thời gian – khởi tạo 2020-2030';

-- ────────────────────────────────────────────────────────────────
-- DIMENSION: dim_location
-- ────────────────────────────────────────────────────────────────
CREATE TABLE dim_location (
    location_key INT AUTO_INCREMENT PRIMARY KEY,
    district     VARCHAR(100) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    region       VARCHAR(50)  NOT NULL COMMENT 'Bắc/Trung/Nam',
    lat          DECIMAL(9,6) NULL,
    lng          DECIMAL(9,6) NULL,
    UNIQUE KEY uq_district_city (district, city)
) ENGINE=InnoDB COMMENT='Chiều địa lý';

-- ────────────────────────────────────────────────────────────────
-- DIMENSION: dim_user (SCD Type 2)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE dim_user (
    user_key       INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT          NOT NULL COMMENT 'Natural key từ OLTP',
    full_name      VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    phone          VARCHAR(20)  NULL,
    role           VARCHAR(20)  NOT NULL,
    status         VARCHAR(20)  NOT NULL,
    effective_date DATE         NOT NULL,
    expiry_date    DATE         NULL,
    is_current     BOOLEAN      DEFAULT TRUE,
    INDEX idx_user_id      (user_id),
    INDEX idx_user_current (user_id, is_current)
) ENGINE=InnoDB COMMENT='Chiều người dùng – SCD Type 2';

-- ────────────────────────────────────────────────────────────────
-- DIMENSION: dim_apartment (SCD Type 2)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE dim_apartment (
    apt_key        INT AUTO_INCREMENT PRIMARY KEY,
    apt_id         INT           NOT NULL COMMENT 'Natural key từ OLTP',
    title          VARCHAR(255)  NOT NULL,
    type           VARCHAR(20)   NOT NULL,
    area           FLOAT         NOT NULL,
    rental_type    VARCHAR(20)   NOT NULL,
    price_month    DECIMAL(15,0) NULL,
    price_day      DECIMAL(15,0) NULL,
    location_key   INT           NOT NULL,
    owner_key      INT           NOT NULL,
    effective_date DATE          NOT NULL,
    expiry_date    DATE          NULL,
    is_current     BOOLEAN       DEFAULT TRUE,
    INDEX idx_apt_id      (apt_id),
    INDEX idx_apt_current (apt_id, is_current),
    CONSTRAINT fk_da_location FOREIGN KEY (location_key) REFERENCES dim_location(location_key),
    CONSTRAINT fk_da_owner    FOREIGN KEY (owner_key)    REFERENCES dim_user(user_key)
) ENGINE=InnoDB COMMENT='Chiều căn hộ – SCD Type 2';

-- ────────────────────────────────────────────────────────────────
-- FACT: fact_contracts
-- ────────────────────────────────────────────────────────────────
CREATE TABLE fact_contracts (
    contract_key      INT AUTO_INCREMENT PRIMARY KEY,
    contract_id       INT           NOT NULL UNIQUE COMMENT 'Natural key từ OLTP',
    date_key          INT           NOT NULL,
    apt_key           INT           NOT NULL,
    tenant_key        INT           NOT NULL,
    owner_key         INT           NOT NULL,
    location_key      INT           NOT NULL,
    rental_type       VARCHAR(20)   NOT NULL,
    status            VARCHAR(20)   NOT NULL,
    monthly_rent      DECIMAL(15,0) NOT NULL,
    deposit_amount    DECIMAL(15,0) DEFAULT 0,
    platform_fee      DECIMAL(15,0) NOT NULL,
    contract_days     INT           NOT NULL,
    move_in_confirmed BOOLEAN       DEFAULT FALSE,
    days_to_rent      INT           NULL,
    etl_loaded_at     TIMESTAMP     NOT NULL,
    INDEX idx_fc_date     (date_key),
    INDEX idx_fc_apt      (apt_key),
    INDEX idx_fc_status   (status),
    INDEX idx_fc_location (location_key),
    CONSTRAINT fk_fc_time     FOREIGN KEY (date_key)     REFERENCES dim_time(date_key),
    CONSTRAINT fk_fc_apt      FOREIGN KEY (apt_key)      REFERENCES dim_apartment(apt_key),
    CONSTRAINT fk_fc_tenant   FOREIGN KEY (tenant_key)   REFERENCES dim_user(user_key),
    CONSTRAINT fk_fc_owner    FOREIGN KEY (owner_key)    REFERENCES dim_user(user_key),
    CONSTRAINT fk_fc_location FOREIGN KEY (location_key) REFERENCES dim_location(location_key)
) ENGINE=InnoDB COMMENT='Fact hợp đồng – Event Fact';

-- ────────────────────────────────────────────────────────────────
-- FACT: fact_payments
-- ────────────────────────────────────────────────────────────────
CREATE TABLE fact_payments (
    payment_key    INT AUTO_INCREMENT PRIMARY KEY,
    payment_id     INT           NOT NULL UNIQUE COMMENT 'Natural key từ OLTP',
    date_key       INT           NOT NULL,
    contract_key   INT           NULL,
    apt_key        INT           NOT NULL,
    payer_key      INT           NOT NULL,
    location_key   INT           NOT NULL,
    payment_type   VARCHAR(20)   NOT NULL,
    payment_method VARCHAR(20)   NOT NULL,
    status         VARCHAR(20)   NOT NULL,
    amount         DECIMAL(15,0) NOT NULL,
    platform_share DECIMAL(15,0) NOT NULL COMMENT '5% của amount',
    etl_loaded_at  TIMESTAMP     NOT NULL,
    INDEX idx_fp_date   (date_key),
    INDEX idx_fp_status (status),
    CONSTRAINT fk_fp_time     FOREIGN KEY (date_key)     REFERENCES dim_time(date_key),
    CONSTRAINT fk_fp_apt      FOREIGN KEY (apt_key)      REFERENCES dim_apartment(apt_key),
    CONSTRAINT fk_fp_payer    FOREIGN KEY (payer_key)    REFERENCES dim_user(user_key),
    CONSTRAINT fk_fp_location FOREIGN KEY (location_key) REFERENCES dim_location(location_key)
) ENGINE=InnoDB COMMENT='Fact thanh toán – Transaction Fact';

-- ────────────────────────────────────────────────────────────────
-- AGGREGATION: agg_daily_revenue
-- Pre-computed hàng ngày bởi ETL → dashboard query ~5ms
-- ────────────────────────────────────────────────────────────────
CREATE TABLE agg_daily_revenue (
    revenue_date       DATE          NOT NULL,
    date_key           INT           NOT NULL,
    location_key       INT           NOT NULL,
    district           VARCHAR(100)  NOT NULL COMMENT 'Denormalized để tránh JOIN',
    total_platform_fee DECIMAL(15,0) DEFAULT 0,
    total_revenue      DECIMAL(15,0) DEFAULT 0,
    contract_count     INT           DEFAULT 0,
    etl_loaded_at      TIMESTAMP     NOT NULL,
    PRIMARY KEY (revenue_date, location_key),
    INDEX idx_agg_rev_date (revenue_date),
    INDEX idx_agg_rev_loc  (location_key)
) ENGINE=InnoDB COMMENT='Doanh thu theo ngày và quận – pre-computed';

-- ────────────────────────────────────────────────────────────────
-- AGGREGATION: agg_occupancy_rate
-- Pre-computed hàng ngày bởi ETL → dashboard query ~5ms
-- ────────────────────────────────────────────────────────────────
CREATE TABLE agg_occupancy_rate (
    calc_date        DATE          NOT NULL,
    location_key     INT           NOT NULL,
    district         VARCHAR(100)  NOT NULL,
    total_apartments INT           DEFAULT 0,
    active_contracts INT           DEFAULT 0,
    occupancy_rate   DECIMAL(5,2)  DEFAULT 0.00 COMMENT 'Tỷ lệ % lấp đầy',
    etl_loaded_at    TIMESTAMP     NOT NULL,
    PRIMARY KEY (calc_date, location_key)
) ENGINE=InnoDB COMMENT='Tỷ lệ lấp đầy theo quận – pre-computed hàng ngày';

-- ────────────────────────────────────────────────────────────────
-- ETL INFRASTRUCTURE
-- ────────────────────────────────────────────────────────────────
CREATE TABLE etl_watermark (
    job_name       VARCHAR(50) PRIMARY KEY,
    last_run_at    TIMESTAMP   NOT NULL DEFAULT '2000-01-01 00:00:00',
    last_max_id    INT         DEFAULT 0,
    rows_processed INT         DEFAULT 0,
    status         ENUM('success','failed','running') DEFAULT 'success'
) ENGINE=InnoDB COMMENT='Watermark cho incremental load';

CREATE TABLE etl_audit_log (
    log_id         INT AUTO_INCREMENT PRIMARY KEY,
    job_name       VARCHAR(100) NOT NULL,
    started_at     TIMESTAMP    NOT NULL,
    finished_at    TIMESTAMP    NULL,
    rows_processed INT          DEFAULT 0,
    status         ENUM('running','success','failed') DEFAULT 'running',
    error_message  TEXT,
    INDEX idx_al_job    (job_name),
    INDEX idx_al_status (status),
    INDEX idx_al_started (started_at)
) ENGINE=InnoDB COMMENT='Audit log mỗi lần chạy ETL job';

-- ────────────────────────────────────────────────────────────────
-- FIX STUCK JOBS (chạy khi cần reset)
-- Uncommment để dùng: UPDATE etl_watermark SET status='success' WHERE status='running';
-- ────────────────────────────────────────────────────────────────
-- UPDATE etl_watermark  SET status='success'                     WHERE status='running';
-- UPDATE etl_audit_log  SET status='failed', finished_at=NOW(),
--        error_message='Manually reset – server was restarted'   WHERE status='running';

-- ────────────────────────────────────────────────────────────────
-- VIEWS CHO POWER BI
-- ────────────────────────────────────────────────────────────────

-- v_fact_payments: chuẩn hóa status 'success' → 'completed' cho DAX
CREATE OR REPLACE VIEW v_fact_payments AS
SELECT
    payment_key, payment_id, date_key, contract_key,
    apt_key, payer_key, location_key,
    payment_type, payment_method,
    CASE status WHEN 'success' THEN 'completed' ELSE status END AS status,
    amount, platform_share, etl_loaded_at
FROM fact_payments;

-- v_fact_contracts: chuẩn hóa status cho DAX
CREATE OR REPLACE VIEW v_fact_contracts AS
SELECT
    contract_key, contract_id, date_key, apt_key,
    tenant_key, owner_key, location_key, rental_type,
    CASE status
        WHEN 'expired'    THEN 'completed'
        WHEN 'terminated' THEN 'cancelled'
        ELSE status
    END AS status,
    monthly_rent, deposit_amount, platform_fee,
    contract_days, move_in_confirmed, days_to_rent, etl_loaded_at
FROM fact_contracts;

-- v_agg_daily_revenue: giới hạn 365 ngày cho Power BI
CREATE OR REPLACE VIEW v_agg_daily_revenue AS
SELECT
    revenue_date, date_key, location_key, district,
    total_platform_fee, total_revenue, contract_count, etl_loaded_at
FROM agg_daily_revenue
WHERE revenue_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY);

-- ────────────────────────────────────────────────────────────────
-- VERIFY
-- ────────────────────────────────────────────────────────────────
SELECT table_name, table_comment
FROM information_schema.tables
WHERE table_schema = 'cc_dwh'
ORDER BY table_name;
