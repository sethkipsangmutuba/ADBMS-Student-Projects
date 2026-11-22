USE ecommerce_adbms;

-- 1. Basic SELECT queries
SELECT user_id, full_name, email, role FROM users;
SELECT product_id, sku, name, base_price FROM products WHERE is_active = TRUE;
SELECT inventory_id, product_id, warehouse_code, quantity_available FROM inventory;

-- 2. Valid INSERT, UPDATE, and DELETE on a temporary test product
INSERT INTO products (category_id, sku, name, base_price, is_active)
VALUES (2, 'SKU-TEST-999', 'Temporary Test Mug', 650.00, TRUE);

UPDATE products
SET base_price = 700.00
WHERE sku = 'SKU-TEST-999';

SELECT product_id, sku, name, base_price FROM products WHERE sku = 'SKU-TEST-999';

DELETE FROM products
WHERE sku = 'SKU-TEST-999';

-- 3. Constraint check examples (run these individually in MySQL shell to see errors):
-- Negative price test (should fail chk_products_price):
-- INSERT INTO products (category_id, sku, name, base_price, is_active)
-- VALUES (2, 'SKU-BAD-001', 'Invalid Price Item', -50.00, TRUE);
--
-- Duplicate email test (should fail UNIQUE on users.email):
-- INSERT INTO users (full_name, email, role)
-- VALUES ('Duplicate Amina', 'amina.ochieng@example.com', 'customer');