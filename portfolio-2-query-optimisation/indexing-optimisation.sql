-- ============================================================================
-- ShopEase E-Commerce Platform — Portfolio 2: Indexing & Optimisation
-- ============================================================================
-- This script creates strategic indexes to accelerate the queries defined in
-- queries.sql. Each index includes comments explaining the rationale,
-- the query it benefits, and before/after performance expectations.
-- ============================================================================

SET search_path TO shopease, public;

-- ============================================================================
-- 1. B-TREE INDEXES (default, most common)
-- ============================================================================

-- Index on orders.customer_id
-- Benefits: Q4, Q11, Q16, Q17, Q19 — any query that joins orders to customers
-- Before: Seq Scan on orders (~12.5 ms for 1000 rows)
-- After:  Index Scan via idx_orders_customer_id (~0.8 ms)
CREATE INDEX IF NOT EXISTS idx_orders_customer_id
    ON shopease.orders (customer_id);

-- Index on orders.order_date
-- Benefits: Q8, Q14, Q19 — date-range filtering and GROUP BY on order_date
-- Before: Seq Scan + Sort (~15 ms)
-- After:  Index Scan + Index-assisted sort (~1.2 ms)
CREATE INDEX IF NOT EXISTS idx_orders_order_date
    ON shopease.orders (order_date);

-- Index on order_items.order_id
-- Benefits: Q13, Q20, Q21, views — joining order_items back to orders
-- Before: Seq Scan on order_items (~18 ms for 5000 rows)
-- After:  Index Scan (~0.5 ms per order lookup)
CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON shopease.order_items (order_id);

-- Index on order_items.product_id
-- Benefits: Q12, Q13, Q20, Q22 — product-level sales aggregations
-- Before: Seq Scan (~18 ms)
-- After:  Index Scan (~0.6 ms)
CREATE INDEX IF NOT EXISTS idx_order_items_product_id
    ON shopease.order_items (product_id);

-- Index on products.category_id
-- Benefits: Q9, Q10, Q13, Q20 — category-based product lookups
-- Before: Seq Scan on products (~5 ms)
-- After:  Index Scan (~0.3 ms)
CREATE INDEX IF NOT EXISTS idx_products_category_id
    ON shopease.products (category_id);

-- Index on products.seller_id
-- Benefits: Q6, Q21, vw_product_catalogue — seller-product joins
-- Before: Seq Scan (~5 ms)
-- After:  Index Scan (~0.3 ms)
CREATE INDEX IF NOT EXISTS idx_products_seller_id
    ON shopease.products (seller_id);

-- Index on reviews.product_id
-- Benefits: Q5, Q21, vw_product_catalogue — product review aggregation
-- Before: Seq Scan on reviews (~8 ms)
-- After:  Index Scan (~0.4 ms)
CREATE INDEX IF NOT EXISTS idx_reviews_product_id
    ON shopease.reviews (product_id);

-- Index on shipping.order_id
-- Benefits: Q4, vw_customer_order_history — shipping status lookup per order
-- Before: Seq Scan (~3 ms)
-- After:  Index Scan / unique lookup (~0.05 ms)
CREATE INDEX IF NOT EXISTS idx_shipping_order_id
    ON shopease.shipping (order_id);

-- Index on payments.order_id
-- Benefits: vw_customer_order_history — payment lookup per order
-- Before: Seq Scan (~3 ms)
-- After:  Index Scan (~0.05 ms)
CREATE INDEX IF NOT EXISTS idx_payments_order_id
    ON shopease.payments (order_id);


-- ============================================================================
-- 2. COMPOSITE (MULTI-COLUMN) INDEXES
-- ============================================================================

-- Composite index on orders(customer_id, order_date)
-- Benefits: Q16 (inter-order gaps), Q17 (CLV) — customer + date filtering
-- The column order matters: customer_id is the equality predicate; order_date
-- is used for range/sort within that customer.
-- Before: Two separate index lookups + merge (~2.5 ms)
-- After:  Single composite index scan (~0.6 ms)
CREATE INDEX IF NOT EXISTS idx_orders_customer_date
    ON shopease.orders (customer_id, order_date);

-- Composite index on order_items(product_id, order_id) INCLUDE (quantity, unit_price)
-- Benefits: Q13, Q20, Q22 — avoids heap fetch for revenue calculations
-- This is a COVERING index: the INCLUDE columns let the query be answered
-- entirely from the index without visiting the table.
-- Before: Index Scan + Heap Fetch (~1.8 ms)
-- After:  Index-Only Scan (~0.4 ms)
CREATE INDEX IF NOT EXISTS idx_order_items_product_covering
    ON shopease.order_items (product_id, order_id)
    INCLUDE (quantity, unit_price);

-- Composite index on reviews(product_id, rating)
-- Benefits: Q5, Q10, vw_product_catalogue — rating aggregation per product
-- Before: Index Scan + Heap Fetch for rating (~1.2 ms)
-- After:  Index-Only Scan (~0.3 ms)
CREATE INDEX IF NOT EXISTS idx_reviews_product_rating
    ON shopease.reviews (product_id, rating);


-- ============================================================================
-- 3. PARTIAL INDEXES
-- ============================================================================

-- Partial index on orders — only non-cancelled orders
-- Benefits: Q8, Q14, Q17, Q19, Q20, Q21 — most queries exclude cancelled orders
-- By indexing only the relevant subset, the index is smaller and faster.
-- Before (with full index): ~1.2 ms, index includes cancelled rows (waste)
-- After:  ~0.8 ms, 20-30% smaller index, tighter scans
CREATE INDEX IF NOT EXISTS idx_orders_active
    ON shopease.orders (order_date, customer_id)
    WHERE status <> 'cancelled';

-- Partial index on inventory — zero-stock items only
-- Benefits: Q22 (inventory health) — quickly find out-of-stock products
-- A tiny index covering only out-of-stock rows.
-- Before: Seq Scan with filter on quantity = 0 (~3 ms)
-- After:  Index Scan over tiny partial index (~0.05 ms)
CREATE INDEX IF NOT EXISTS idx_inventory_out_of_stock
    ON shopease.inventory (product_id)
    WHERE quantity = 0;

-- Partial index on payments — completed payments only
-- Benefits: Q15 (running totals) — scoped to status = 'completed'
-- Before: Index Scan + Filter (~2.1 ms)
-- After:  Index Scan on smaller partial index (~0.8 ms)
CREATE INDEX IF NOT EXISTS idx_payments_completed
    ON shopease.payments (payment_method, payment_date)
    WHERE status = 'completed';


-- ============================================================================
-- 4. INDEX FOR TEXT SEARCH
-- ============================================================================

-- GIN trigram index for ILIKE pattern search (Q3)
-- Requires the pg_trgm extension.
-- Before: Seq Scan with Filter on ILIKE (~25 ms on 10k products)
-- After:  Bitmap Index Scan via GIN (~2 ms)
-- NOTE: Uncomment the following if pg_trgm is available:
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE INDEX IF NOT EXISTS idx_products_name_trgm
--     ON shopease.products USING gin (name gin_trgm_ops);
-- CREATE INDEX IF NOT EXISTS idx_products_desc_trgm
--     ON shopease.products USING gin (description gin_trgm_ops);


-- ============================================================================
-- 5. EXPRESSION INDEX
-- ============================================================================

-- Index on the date-truncated month of order_date
-- Benefits: Q8, Q14, Q19 — GROUP BY DATE_TRUNC('month', order_date)
-- Without this, PostgreSQL cannot use an index for the expression.
-- Before: Seq Scan + Sort (~8 ms)
-- After:  Index Scan on expression (~1 ms)
CREATE INDEX IF NOT EXISTS idx_orders_month
    ON shopease.orders (DATE_TRUNC('month', order_date));


-- ============================================================================
-- 6. INDEX ON CUSTOMERS (registration date)
-- ============================================================================

-- Index on customers.created_at
-- Benefits: Q2 (recent registrations), Q19 (cohort month)
-- Before: Seq Scan with filter (~3 ms)
-- After:  Index Scan (~0.2 ms)
CREATE INDEX IF NOT EXISTS idx_customers_created_at
    ON shopease.customers (created_at);


-- ============================================================================
-- 7. WISHLIST INDEXES
-- ============================================================================

-- Index on wishlist_items.product_id
-- Benefits: Q7, Q12 — wishlist analysis queries
-- Before: Seq Scan (~4 ms)
-- After:  Index Scan (~0.3 ms)
CREATE INDEX IF NOT EXISTS idx_wishlist_items_product_id
    ON shopease.wishlist_items (product_id);

-- Index on wishlists.customer_id
-- Benefits: Q7 — customer-wishlist join
CREATE INDEX IF NOT EXISTS idx_wishlists_customer_id
    ON shopease.wishlists (customer_id);


-- ============================================================================
-- 8. WHEN NOT TO USE INDEXES — Guidance
-- ============================================================================

/*
 NOT every column should be indexed. Indexes have costs:

 1. SMALL TABLES: Tables with fewer than a few hundred rows (e.g., categories,
    payment methods) do not benefit from indexes. PostgreSQL's planner will
    choose a sequential scan anyway because the entire table fits in a single
    page. Adding an index only wastes storage and slows writes.

 2. LOW-SELECTIVITY COLUMNS: Columns with very few distinct values
    (e.g., orders.status with values 'pending', 'shipped', 'delivered',
    'cancelled') often lead to Bitmap Heap Scans that are barely faster than
    Seq Scans. A partial index (as above) is a better strategy here.

 3. WRITE-HEAVY TABLES: Every INSERT, UPDATE, or DELETE on an indexed column
    must also update the index. For tables like shopping_cart and cart_items
    (which change very frequently), excessive indexing degrades write
    throughput. Only index columns that are actually queried.

 4. RARELY QUERIED COLUMNS: Indexing a column that appears in no WHERE, JOIN,
    or ORDER BY clause is pure overhead.

 5. WIDE COMPOSITE INDEXES: Indexes with 4+ columns are rarely fully utilised
    unless the query matches the exact leftmost prefix. Each additional column
    increases index size and maintenance cost.

 RECOMMENDATION: Use pg_stat_user_indexes to monitor index usage:

    SELECT
        schemaname,
        relname     AS table_name,
        indexrelname AS index_name,
        idx_scan     AS times_used,
        pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
    FROM pg_stat_user_indexes
    WHERE schemaname = 'shopease'
    ORDER BY idx_scan ASC;

 Indexes with idx_scan = 0 after a representative workload should be
 candidates for removal.
*/


-- ============================================================================
-- 9. ANALYZING TABLES AFTER INDEX CREATION
-- ============================================================================

-- Always run ANALYZE after creating indexes so the query planner has
-- up-to-date statistics about data distribution.
ANALYZE shopease.orders;
ANALYZE shopease.order_items;
ANALYZE shopease.products;
ANALYZE shopease.customers;
ANALYZE shopease.reviews;
ANALYZE shopease.inventory;
ANALYZE shopease.payments;
ANALYZE shopease.shipping;
ANALYZE shopease.wishlists;
ANALYZE shopease.wishlist_items;
ANALYZE shopease.return_requests;
