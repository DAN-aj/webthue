-- ================================================================
--  Migration v15: Thêm cột tx_ref vào bảng payments
--  Tương thích MySQL 8.0 mọi bản
-- ================================================================

USE apartment_rental;

-- Thêm cột tx_ref nếu chưa có
DROP PROCEDURE IF EXISTS migrate_v15;

DELIMITER $$
CREATE PROCEDURE migrate_v15()
BEGIN
    -- ADD COLUMN tx_ref
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'payments'
          AND column_name  = 'tx_ref'
    ) THEN
        ALTER TABLE payments
            ADD COLUMN tx_ref VARCHAR(30) NULL
            COMMENT 'Mã tham chiếu VietQR (HD{contractId}T{timestamp})'
            AFTER note;
    END IF;

    -- ADD INDEX idx_payments_tx_ref
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.statistics
        WHERE table_schema = DATABASE()
          AND table_name   = 'payments'
          AND index_name   = 'idx_payments_tx_ref'
    ) THEN
        ALTER TABLE payments ADD INDEX idx_payments_tx_ref (tx_ref);
    END IF;
END$$
DELIMITER ;

CALL migrate_v15();
DROP PROCEDURE IF EXISTS migrate_v15;

-- Verify
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_COMMENT
FROM information_schema.columns
WHERE table_name   = 'payments'
  AND table_schema = DATABASE()
ORDER BY ordinal_position;
