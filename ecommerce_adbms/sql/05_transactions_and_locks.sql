USE ecommerce_adbms;

SET @valid_pm := (
    SELECT SUBSTRING_INDEX(
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(COLUMN_TYPE, '''', 2),
            '''', -1
        ),
        ',', 1
    )
    FROM information_schema.columns
    WHERE table_schema = 'ecommerce_adbms'
      AND table_name = 'payments'
      AND column_name = 'payment_method'
    LIMIT 1
);

SET @pm_value := COALESCE(NULLIF(@valid_pm, ''), 'card');

START TRANSACTION;

SELECT quantity_available
INTO @current_stock
FROM inventory
WHERE product_id = 1
  AND warehouse_code = 'WH-NBO-01'
FOR UPDATE;

SELECT base_price
INTO @unit_price
FROM products
WHERE product_id = 1
  AND is_active = TRUE;

SET @qty_to_buy = 1;

UPDATE inventory
SET quantity_available = quantity_available - @qty_to_buy
WHERE product_id = 1
  AND warehouse_code = 'WH-NBO-01'
  AND quantity_available >= @qty_to_buy;

INSERT INTO orders (user_id, shipping_address_id, order_status, total_amount)
VALUES (1, 1, 'paid', @unit_price * @qty_to_buy);

SET @new_order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (@new_order_id, 1, @qty_to_buy, @unit_price);

SET @ins_pay := CONCAT(
    'INSERT INTO payments (order_id, payment_method, payment_status, amount, paid_at) ',
    'VALUES (', @new_order_id, ', ''', @pm_value, ''', ''completed'', ', (@unit_price * @qty_to_buy), ', NOW())'
);
PREPARE stmt_pay FROM @ins_pay;
EXECUTE stmt_pay;
DEALLOCATE PREPARE stmt_pay;

COMMIT;

SELECT @new_order_id AS created_order_id, @pm_value AS payment_method_used, 'COMMITTED' AS tx_status;

START TRANSACTION;

UPDATE inventory
SET quantity_available = quantity_available + 500
WHERE product_id = 1
  AND warehouse_code = 'WH-NBO-01';

SELECT product_id, warehouse_code, quantity_available AS during_uncommitted_tx
FROM inventory
WHERE product_id = 1
  AND warehouse_code = 'WH-NBO-01';

ROLLBACK;

SELECT product_id, warehouse_code, quantity_available AS after_rollback
FROM inventory
WHERE product_id = 1
  AND warehouse_code = 'WH-NBO-01';
