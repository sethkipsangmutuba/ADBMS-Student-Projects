DROP DATABASE IF EXISTS ecommerce_adbms;
CREATE DATABASE IF NOT EXISTS ecommerce_adbms
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ecommerce_adbms;

CREATE TABLE users (
  user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  role ENUM('customer', 'seller', 'admin') NOT NULL DEFAULT 'customer',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE addresses (
  address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  street VARCHAR(200) NOT NULL,
  city VARCHAR(100) NOT NULL,
  country VARCHAR(100) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_addresses_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE categories (
  category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  parent_category_id BIGINT UNSIGNED NULL,
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NOT NULL,
  sku VARCHAR(60) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  base_price DECIMAL(12, 2) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_products_price CHECK (base_price >= 0.00),
  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE inventory (
  inventory_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  warehouse_code VARCHAR(40) NOT NULL,
  quantity_available INT NOT NULL DEFAULT 0,
  reorder_level INT NOT NULL DEFAULT 10,
  CONSTRAINT uq_inventory_product_warehouse UNIQUE (product_id, warehouse_code),
  CONSTRAINT chk_inventory_qty CHECK (quantity_available >= 0),
  CONSTRAINT chk_inventory_reorder CHECK (reorder_level >= 0),
  CONSTRAINT fk_inventory_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE orders (
  order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  shipping_address_id BIGINT UNSIGNED NOT NULL,
  order_status ENUM('pending', 'paid', 'shipped', 'delivered', 'cancelled') NOT NULL DEFAULT 'pending',
  order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  CONSTRAINT chk_orders_total CHECK (total_amount >= 0.00),
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_orders_address
    FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE order_items (
  order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  unit_price DECIMAL(12, 2) NOT NULL,
  CONSTRAINT chk_order_items_qty CHECK (quantity > 0),
  CONSTRAINT chk_order_items_price CHECK (unit_price >= 0.00),
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  payment_method ENUM('card', 'mobile_money', 'bank_transfer', 'cash_on_delivery') NOT NULL,
  payment_status ENUM('pending', 'completed', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
  amount DECIMAL(12, 2) NOT NULL,
  paid_at TIMESTAMP NULL,
  CONSTRAINT chk_payments_amount CHECK (amount >= 0.00),
  CONSTRAINT fk_payments_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

INSERT INTO users (full_name, email, role) VALUES
  ('Gary Moss', 'gary.moss@gmail.com', 'customer'),
  ('Leon Muuo', 'leon.muuo@gmail.com', 'customer'),
  ('Brian Sigei', 'brian.sigei@gmail.com', 'seller'),
  ('Gregory Oduor', 'gregory.oduor@gmail.com', 'admin');

INSERT INTO addresses (user_id, street, city, country, is_default) VALUES
  (1, '14 Ngong Road', 'Nairobi', 'Kenya', TRUE),
  (1, '88 Nyali Links Road', 'Mombasa', 'Kenya', FALSE),
  (2, '22 Kenyatta Avenue', 'Nakuru', 'Kenya', TRUE),
  (3, '5 Industrial Area Lane', 'Nairobi', 'Kenya', TRUE);

INSERT INTO categories (name, parent_category_id) VALUES
  ('Electronics', NULL),
  ('Home & Kitchen', NULL),
  ('Laptops & Accessories', 1),
  ('Cookware', 2);

INSERT INTO products (category_id, sku, name, base_price, is_active) VALUES
  (3, 'SKU-LAP-001', '14-inch Business Laptop', 75000.00, TRUE),
  (3, 'SKU-MOU-002', 'Wireless Optical Mouse', 1800.00, TRUE),
  (4, 'SKU-POT-003', 'Stainless Steel Sufuria Set', 4500.00, TRUE),
  (2, 'SKU-KTL-004', 'Electric Kettle 1.7L', 2900.00, TRUE);

INSERT INTO inventory (product_id, warehouse_code, quantity_available, reorder_level) VALUES
  (1, 'WH-NBO-01', 25, 5),
  (2, 'WH-NBO-01', 120, 20),
  (3, 'WH-MBA-01', 45, 10),
  (4, 'WH-NBO-01', 60, 15);

INSERT INTO orders (user_id, shipping_address_id, order_status, total_amount) VALUES
  (1, 1, 'paid', 76800.00),
  (2, 3, 'pending', 4500.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
  (1, 1, 1, 75000.00),
  (1, 2, 1, 1800.00),
  (2, 3, 1, 4500.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, paid_at) VALUES
  (1, 'mobile_money', 'completed', 76800.00, CURRENT_TIMESTAMP),
  (2, 'cash_on_delivery', 'pending', 4500.00, NULL);