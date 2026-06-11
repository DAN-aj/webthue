-- =============================================================
-- indexes_v16.sql  —  Dashboard performance indexes
-- Tương thích MySQL 8.0 mọi bản — dùng PROCEDURE để kiểm tra
-- trước khi tạo, tránh lỗi "Duplicate key name"
-- =============================================================

USE apartment_rental;

DROP PROCEDURE IF EXISTS add_index_if_missing;

DELIMITER $$
CREATE PROCEDURE add_index_if_missing(
    tbl VARCHAR(64), idx VARCHAR(64), ddl TEXT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.statistics
        WHERE table_schema = DATABASE()
          AND table_name   = tbl
          AND index_name   = idx
    ) THEN
        SET @sql = ddl;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

-- contracts: filter status + created_at
CALL add_index_if_missing(
    'contracts',
    'idx_contracts_status_created',
    'ALTER TABLE contracts ADD INDEX idx_contracts_status_created (status, created_at)'
);

-- contracts: join apt_id + filter status
CALL add_index_if_missing(
    'contracts',
    'idx_contracts_apt_status',
    'ALTER TABLE contracts ADD INDEX idx_contracts_apt_status (apt_id, status)'
);

-- apartments: filter status + group district + owner
CALL add_index_if_missing(
    'apartments',
    'idx_apartments_status_district',
    'ALTER TABLE apartments ADD INDEX idx_apartments_status_district (status, district, owner_id)'
);

DROP PROCEDURE IF EXISTS add_index_if_missing;