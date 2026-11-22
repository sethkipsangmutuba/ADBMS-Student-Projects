USE ecommerce_adbms;

-- 1. Inspect existing indexes
SELECT
    TABLE_NAME,
    INDEX_NAME,
    NON_UNIQUE,
    SEQ_IN_INDEX,
    COLUMN_NAME,
    INDEX_TYPE
FROM information_schema.statistics
WHERE TABLE_SCHEMA = 'ecommerce_adbms'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- 2. Baseline EXPLAIN (before new indexes)
EXPLAIN
SELECT o.order_id, o.status, o.total_amount, o.ordered_at
FROM orders o
WHERE o.user_id = 1
ORDER BY o.ordered_at DESC;

EXPLAIN
SELECT p.product_id, p.sku, p.name, p.base_price, i.warehouse_code, i.quantity_available
FROM products p
JOIN inventory i ON p.product_id = i.product_id
WHERE p.category_id = 2
  AND p.is_active = TRUE
  AND i.quantity_available <= i.reorder_level;

EXPLAIN
SELECT oi.order_item_id, oi.order_id, oi.product_id, oi.quantity, oi.unit_price
FROM order_items oi
WHERE oi.order_id = 1;

EXPLAIN
SELECT pay.payment_id, pay.order_id, pay.payment_method, pay.payment_status, pay.amount, pay.paid_at
FROM payments pay
WHERE pay.order_id = 1
  AND pay.payment_status = 'completed';

-- 3. Add composite & targeted indexes
CREATE INDEX idx_orders_user_ordered_at
    ON orders (user_id, ordered_at DESC);

CREATE INDEX idx_products_category_active
    ON products (category_id, is_active, base_price);

CREATE INDEX idx_inventory_warehouse_stock
    ON inventory (warehouse_code, quantity_available, reorder_level);

CREATE INDEX idx_payments_order_status
    ON payments (order_id, payment_status, paid_at);

-- 4. Post-tuning EXPLAIN (after new indexes)
EXPLAIN
SELECT o.order_id, o.status, o.total_amount, o.ordered_at
FROM orders o
WHERE o.user_id = 1
ORDER BY o.ordered_at DESC;

EXPLAIN
SELECT p.product_id, p.sku, p.name, p.base_price, i.warehouse_code, i.quantity_available
FROM products p
JOIN inventory i ON p.product_id = i.product_id
WHERE p.category_id = 2
  AND p.is_active = TRUE
  AND i.quantity_available <= i.reorder_level;

EXPLAIN
SELECT oi.order_item_id, oi.order_id, oi.product_id, oi.quantity, oi.unit_price
FROM order_items oi
WHERE oi.order_id = 1;

EXPLAIN
SELECT pay.payment_id, pay.order_id, pay.payment_method, pay.payment_status, pay.amount, pay.paid_at
FROM payments pay
WHERE pay.order_id = 1
  AND pay.payment_status = 'completed';