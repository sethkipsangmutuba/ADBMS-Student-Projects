# ICS 2404 — Advanced Database Management Systems (ADBMS)
## Block 2 Report: Indexing, Query Tuning, Views, Stored Routines & ACID Transactions (`ecommerce_adbms`)

- **Group Members**: Gary Moss, Leon Muuo, Brian Sigei, Gregory Oduor
- **Database Engine**: MySQL 8.0 / InnoDB
- **Target Schema**: `ecommerce_adbms` (`users`, `addresses`, `categories`, `products`, `inventory`, `orders`, `order_items`, `payments`)

---

## 1. Indexing & Query Optimization (`sql/03_indexes_and_tuning.sql`)
- Inspected baseline indexes via `information_schema.statistics` (`PRIMARY`, `UNIQUE`, and foreign key indexes).
- Ran `EXPLAIN` before and after adding targeted composite/covering indexes:
  - `idx_orders_user_ordered_at` on `orders (user_id, ordered_at DESC)`
  - `idx_products_category_active` on `products (category_id, is_active, base_price)`
  - `idx_inventory_warehouse_stock` on `inventory (warehouse_code, quantity_available, reorder_level)`
  - `idx_payments_order_status` on `payments (order_id, payment_status, paid_at)`
- **Key Takeaway**: Aligning index column order with `WHERE` equality filters and `ORDER BY` / range columns reduces scanned rows and avoids unnecessary table scans or sorting overhead on high-frequency order, catalog, stock, and payment lookups.

---

## 2. Views & Stored Procedures (`sql/04_views_and_procedures.sql`)
- **`vw_customer_order_summary`**: Joins `users`, `orders`, `order_items`, and `payments` to provide per-order customer details, line-item count, unit totals, and completed payment totals using `order_status` and `order_date`.
- **`vw_warehouse_stock_status`**: Joins `inventory`, `products`, and `categories` and classifies each warehouse row into `OUT_OF_STOCK`, `LOW_STOCK`, or `HEALTHY` using `quantity_available` and `reorder_level`.
- **`sp_get_user_order_history(IN p_user_id BIGINT UNSIGNED)`**: Encapsulates customer order history retrieval ordered newest-first so callers pass a single `user_id` parameter instead of rewriting multi-table joins.

---

## 3. ACID Transactions & Row Locking (`sql/05_transactions_and_locks.sql`)
- **Atomic Checkout (`START TRANSACTION` ... `COMMIT`)**:
  - Locks the target `inventory` row with `SELECT ... FOR UPDATE` (`product_id = 1`, `warehouse_code = 'WH-NBO-01'`) so concurrent checkouts cannot read stale stock and oversell.
  - Deducts stock (`quantity_available >= @qty_to_buy`), inserts the `orders` header (`order_status = 'paid'`), captures the snapshot `unit_price` in `order_items`, and records the `payments` row (`payment_status = 'completed'`) in a single atomic unit.
- **Rollback Verification (`START TRANSACTION` ... `ROLLBACK`)**:
  - Tested an uncommitted stock adjustment (`524` during transaction) and executed `ROLLBACK`, confirming the row reverted to its committed stock count (`24`) without persisting partial changes.
- **ACID Alignment**:
  - **Atomicity**: All writes in a checkout either commit together or roll back together.
  - **Consistency**: Foreign keys, `CHECK` constraints, `ENUM` domains, and conditional stock checks keep the database valid.
  - **Isolation**: InnoDB row locks and `SELECT ... FOR UPDATE` prevent lost updates and race conditions under concurrent access.
  - **Durability**: Committed transactions are persisted by InnoDB redo logging.

---

## 4. Issues Encountered & Resolutions
1. **Column Name Alignment (`o.status` / `o.ordered_at`)**: Checking `SHOW COLUMNS FROM orders` confirmed the actual columns are `order_status` and `order_date`, which were updated in `04_views_and_procedures.sql` and `05_transactions_and_locks.sql`.
2. **Payment Method Domain (`ERROR 1265`)**: Verified allowed `payment_method` values on `payments` and aligned the transaction script with a valid allowed method (`card`) so the order, order item, and payment committed cleanly.