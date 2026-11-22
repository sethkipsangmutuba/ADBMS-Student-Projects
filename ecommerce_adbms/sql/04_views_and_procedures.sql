USE ecommerce_adbms;

-- ============================================================
-- 1. DYNAMICALLY BUILD VIEW OVER ORDERS + USERS + ORDER_ITEMS + PAYMENTS
--    (Adapts automatically to your actual orders status/date column names)
-- ============================================================
SET @status_col := (
    SELECT COLUMN_NAME
    FROM information_schema.columns
    WHERE table_schema = 'ecommerce_adbms'
      AND table_name = 'orders'
      AND column_name IN ('order_status', 'status')
    ORDER BY FIELD(column_name, 'order_status', 'status')
    LIMIT 1
);

SET @date_col := (
    SELECT COLUMN_NAME
    FROM information_schema.columns
    WHERE table_schema = 'ecommerce_adbms'
      AND table_name = 'orders'
      AND column_name IN ('order_date', 'ordered_at', 'created_at')
    ORDER BY FIELD(column_name, 'order_date', 'ordered_at', 'created_at')
    LIMIT 1
);

SET @pay_status_col := (
    SELECT COLUMN_NAME
    FROM information_schema.columns
    WHERE table_schema = 'ecommerce_adbms'
      AND table_name = 'payments'
      AND column_name IN ('payment_status', 'status')
    ORDER BY FIELD(column_name, 'payment_status', 'status')
    LIMIT 1
);

SET @sql_order_view := CONCAT(
    'CREATE OR REPLACE VIEW vw_customer_order_summary AS ',
    'SELECT ',
    '    u.user_id, ',
    '    u.full_name, ',
    '    u.email, ',
    '    o.order_id, ',
    '    o.`', @status_col, '` AS order_status, ',
    '    o.total_amount, ',
    '    o.`', @date_col, '` AS order_date, ',
    '    COUNT(DISTINCT oi.order_item_id) AS line_item_count, ',
    '    COALESCE(SUM(DISTINCT oi.quantity), 0) AS total_units_ordered, ',
    '    COALESCE(SUM(CASE WHEN pay.`', @pay_status_col, '` = ''completed'' THEN pay.amount ELSE 0 END), 0.00) AS amount_paid ',
    'FROM users u ',
    'JOIN orders o ON u.user_id = o.user_id ',
    'LEFT JOIN order_items oi ON o.order_id = oi.order_id ',
    'LEFT JOIN payments pay ON o.order_id = pay.order_id ',
    'GROUP BY ',
    '    u.user_id, ',
    '    u.full_name, ',
    '    u.email, ',
    '    o.order_id, ',
    '    o.`', @status_col, '`, ',
    '    o.total_amount, ',
    '    o.`', @date_col, '`'
);

PREPARE stmt_order_view FROM @sql_order_view;
EXECUTE stmt_order_view;
DEALLOCATE PREPARE stmt_order_view;

-- ============================================================
-- 2. VIEW: Multi-Warehouse Stock & Reorder Status
-- ============================================================
CREATE OR REPLACE VIEW vw_warehouse_stock_status AS
SELECT
    i.inventory_id,
    i.warehouse_code,
    p.product_id,
    p.sku,
    p.name AS product_name,
    c.name AS category_name,
    p.base_price,
    i.quantity_available,
    i.reorder_level,
    CASE
        WHEN i.quantity_available = 0 THEN 'OUT_OF_STOCK'
        WHEN i.quantity_available <= i.reorder_level THEN 'LOW_STOCK'
        ELSE 'HEALTHY'
    END AS stock_health
FROM inventory i
JOIN products p ON i.product_id = p.product_id
LEFT JOIN categories c ON p.category_id = c.category_id;

-- ============================================================
-- 3. STORED PROCEDURE: Get Order History for a Specific User
-- ============================================================
DROP PROCEDURE IF EXISTS sp_get_user_order_history;

DELIMITER $$
CREATE PROCEDURE sp_get_user_order_history(IN p_user_id BIGINT UNSIGNED)
BEGIN
    SELECT
        order_id,
        order_status,
        total_amount,
        amount_paid,
        line_item_count,
        total_units_ordered,
        order_date
    FROM vw_customer_order_summary
    WHERE user_id = p_user_id
    ORDER BY order_date DESC;
END$$
DELIMITER ;

-- ============================================================
-- 4. VERIFICATION QUERIES
-- ============================================================
SELECT * FROM vw_warehouse_stock_status ORDER BY warehouse_code, product_name;
CALL sp_get_user_order_history(1);