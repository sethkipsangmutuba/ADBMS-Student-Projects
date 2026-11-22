# Block 1 Report: Data Modeling & Relational Foundations

## Group Members
- Gary Moss
- Leon Muuo
- Brian Sigei
- Gregory Oduor

## Schema Overview & Justification
The `ecommerce_adbms` database models a normalized e-commerce system across eight core tables:
- `users`: Stores account identity, unique email addresses, and role permissions (`customer`, `seller`, `admin`).
- `addresses`: Separates shipping addresses from `users` (`1:N` relationship) so users can maintain multiple addresses and mark a default address without repeating address fields.
- `categories`: Uses a self-referencing `parent_category_id` foreign key to support hierarchical product categories and subcategories.
- `products`: Stores catalog items with unique SKUs, pricing (`base_price`), active status, and a link to `categories`.
- `inventory`: Separates stock quantities and reorder thresholds per warehouse (`WH-NBO-01`, `WH-MBA-01`) with a unique constraint on `(product_id, warehouse_code)` so stock can be tracked across multiple locations.
- `orders`: Captures customer order headers, shipping address references, order status, order timestamps, and order totals.
- `order_items`: Resolves the many-to-many relationship between `orders` and `products` while snapshotting `unit_price` at order time so historical order totals remain accurate even if product catalog prices change later.
- `payments`: Tracks payment methods, payment statuses, amounts, and payment timestamps linked to `orders`.

## Key Integrity Constraints
- **Primary & Foreign Keys**: Enforce entity identity and relational links across all eight tables.
- **`UNIQUE` Constraints**: Prevent duplicate user emails, duplicate product SKUs, duplicate category names, and duplicate `(product_id, warehouse_code)` inventory records.
- **`CHECK` Constraints**: Prevent negative prices, negative inventory quantities, negative reorder levels, negative order totals, negative payment amounts, and zero/negative quantities in `order_items`.
- **Referential Actions (`ON DELETE` / `ON UPDATE`)**: `addresses` and `order_items` cascade deletes from their parent (`users` and `orders` respectively), while `products`, `inventory`, `orders`, and `payments` restrict accidental deletion of referenced catalog, order, or payment records.

## Milestone Reflection Log
### 1. CLI Tools Not Recognized in PowerShell (`git` and `mysql`)
- **What changed**: Added `C:\Program Files\Git\cmd` and `C:\Program Files\MySQL\MySQL Server 8.0\bin` to Windows environment variables (`PATH`) and restarted VS Code.
- **What failed**: Running `git --version` and `mysql --version` in the VS Code PowerShell terminal returned `CommandNotFoundException` (`ObjectNotFound`).
- **Why it failed**: Both tools were already installed on the machine, but their installation directories were not included in the Windows `PATH`.
- **Alternative approach**: Verified the executable paths using `Get-ChildItem` in PowerShell, updated Windows `PATH` permanently, and restarted VS Code so the terminal loaded the updated environment.

### 2. Re-Running Schema Script Hit Existing Table Error (`ERROR 1050`)
- **What changed**: Added `DROP DATABASE IF EXISTS ecommerce_adbms;` at the start of `sql/01_schema_and_seed.sql` and ran `01_schema_and_seed.sql` and `02_basic_queries.sql` cleanly in sequence.
- **What failed**: Re-running `sql/01_schema_and_seed.sql` after updating sample user data failed with `ERROR 1050 (42S01): Table 'users' already exists`, and piping commands with `>>` instead of running them separately/piping properly caused extra prompts.
- **Why it failed**: `CREATE DATABASE IF NOT EXISTS` kept the existing database and tables intact without dropping prior objects first.
- **Alternative approach**: Added an explicit `DROP DATABASE IF EXISTS ecommerce_adbms;` reset statement at the top of the setup script for clean local re-runs and executed the SQL scripts sequentially against `mysql -u root -p`.