-- ================================================================
-- SETUP_ALL.sql
-- Chạy file này 1 lần duy nhất để khởi tạo toàn bộ database
-- 
-- Cách chạy:
--   MySQL Workbench → Open SQL Script → chọn file này → Execute (⚡)
--   hoặc: mysql -u root -p < SETUP_ALL.sql
--
-- Thứ tự:
--   1. apartment_rental.sql   → OLTP schema (bảng chính)
--   2. cc_dwh.sql             → Data Warehouse schema
--   3. payment_v15_migration.sql → Thêm cột tx_ref vào payments
--   4. indexes_v16.sql        → Index tối ưu hiệu năng
-- ================================================================

SOURCE apartment_rental.sql;
SOURCE cc_dwh.sql;
SOURCE payment_v15_migration.sql;
SOURCE indexes_v16.sql;

SELECT 'Database setup complete!' AS status;
