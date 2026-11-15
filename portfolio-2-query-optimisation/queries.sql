-- ============================================================================
-- ShopEase E-Commerce Platform — Portfolio 2: SQL Queries
-- ============================================================================
-- This file contains 20+ SQL queries of increasing complexity, demonstrating
-- a wide range of PostgreSQL features: filtering, joins, aggregates,
-- subqueries, window functions, CTEs (including recursive), analytical
-- queries, and views.
--
-- All queries reference the shopease schema created in Portfolio 1.
-- ============================================================================

SET search_path TO shopease, public;

-- ============================================================================
-- SECTION 1: Simple SELECTs with WHERE, ORDER BY, LIMIT
-- ============================================================================

-- Q1: Retrieve the 10 most expensive products currently in stock
-- Demonstrates: basic SELECT, WHERE, ORDER BY DESC, LIMIT
SELECT
    p.product_id,
    p.name          AS product_name,
    p.price,
    i.quantity       AS stock_quantity
FROM products p
JOIN inventory i ON p.product_id = i.product_id
WHERE i.quantity > 0
ORDER BY p.price DESC
LIMIT 10;


-- Q2: Find all customers who registered in the last 90 days
-- Demonstrates: date arithmetic, ORDER BY
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    created_at AS registration_date
FROM customers
WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY created_at DESC;


-- Q3: Search products whose name or description matches a keyword (case-insensitive)
-- Demonstrates: ILIKE pattern matching, OR
SELECT
    product_id,
    name,
    price,
    description
FROM products
WHERE name ILIKE '%wireless%'
   OR description ILIKE '%wireless%'
ORDER BY name
LIMIT 20;


-- ============================================================================
-- SECTION 2: JOINs (INNER, LEFT, RIGHT, FULL OUTER)
-- ============================================================================

-- Q4: List every order with customer details and shipping status
-- Demonstrates: INNER JOIN across three tables
SELECT
    o.order_id,
    c.first_name || ' ' || c.last_name  AS customer_name,
    c.email,
    o.order_date,
    o.total_amount,
    o.status        AS order_status,
    s.status        AS shipping_status,
    s.tracking_number
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN shipping s  ON o.order_id    = s.order_id
ORDER BY o.order_date DESC;


-- Q5: Show all products with their reviews (including products with no reviews)
-- Demonstrates: LEFT JOIN, aggregate on optional side
SELECT
    p.product_id,
    p.name                          AS product_name,
    COUNT(r.review_id)              AS review_count,
    COALESCE(ROUND(AVG(r.rating), 2), 0) AS avg_rating
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.name
ORDER BY avg_rating DESC, review_count DESC;


-- Q6: Identify sellers who have never sold a product
-- Demonstrates: LEFT JOIN with IS NULL check (anti-join pattern)
SELECT
    s.seller_id,
    s.company_name,
    s.email
FROM sellers s
LEFT JOIN products p ON s.seller_id = p.seller_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.order_item_id IS NULL
ORDER BY s.company_name;


-- Q7: Full outer join — reconcile customers and their wishlist activity
-- Demonstrates: FULL OUTER JOIN (useful for data auditing)
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    w.wishlist_id,
    COUNT(wi.wishlist_item_id) AS items_in_wishlist
FROM customers c
FULL OUTER JOIN wishlists w      ON c.customer_id = w.customer_id
FULL OUTER JOIN wishlist_items wi ON w.wishlist_id = wi.wishlist_id
GROUP BY c.customer_id, c.first_name, c.last_name, w.wishlist_id
ORDER BY items_in_wishlist DESC;


-- ============================================================================
-- SECTION 3: Aggregate Functions with GROUP BY and HAVING
-- ============================================================================

-- Q8: Monthly revenue summary for the current year
-- Demonstrates: SUM, COUNT, GROUP BY with date_trunc, HAVING
SELECT
    DATE_TRUNC('month', o.order_date)::date AS month,
    COUNT(o.order_id)                       AS total_orders,
    SUM(o.total_amount)                     AS total_revenue,
    ROUND(AVG(o.total_amount), 2)           AS avg_order_value,
    MAX(o.total_amount)                     AS largest_order
FROM orders o
WHERE o.status <> 'cancelled'
  AND EXTRACT(YEAR FROM o.order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY DATE_TRUNC('month', o.order_date)
HAVING SUM(o.total_amount) > 0
ORDER BY month;


-- Q9: Categories with more than 5 products and average price above £50
-- Demonstrates: COUNT, AVG, GROUP BY, HAVING with multiple conditions
SELECT
    c.category_id,
    c.name           AS category_name,
    COUNT(p.product_id) AS product_count,
    ROUND(AVG(p.price), 2) AS avg_price,
    MIN(p.price) AS cheapest,
    MAX(p.price) AS most_expensive
FROM categories c
JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_id, c.name
HAVING COUNT(p.product_id) > 5
   AND AVG(p.price) > 50
ORDER BY avg_price DESC;


-- ============================================================================
-- SECTION 4: Subqueries (Correlated and Non-Correlated)
-- ============================================================================

-- Q10: Products priced above the average for their category (correlated subquery)
-- Demonstrates: correlated subquery in WHERE
SELECT
    p.product_id,
    p.name        AS product_name,
    p.price,
    c.name        AS category_name
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.price > (
    SELECT AVG(p2.price)
    FROM products p2
    WHERE p2.category_id = p.category_id
)
ORDER BY c.name, p.price DESC;


-- Q11: Customers who have placed more orders than the overall average (non-correlated)
-- Demonstrates: non-correlated subquery in HAVING
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) > (
    SELECT AVG(order_cnt)
    FROM (
        SELECT COUNT(order_id) AS order_cnt
        FROM orders
        GROUP BY customer_id
    ) sub
)
ORDER BY order_count DESC;


-- Q12: Products that appear in more wishlists than they have actual orders
-- Demonstrates: subquery in SELECT list and comparison
SELECT
    p.product_id,
    p.name AS product_name,
    (SELECT COUNT(DISTINCT wi.wishlist_id)
     FROM wishlist_items wi
     WHERE wi.product_id = p.product_id) AS wishlist_appearances,
    (SELECT COALESCE(SUM(oi.quantity), 0)
     FROM order_items oi
     WHERE oi.product_id = p.product_id) AS total_units_sold
FROM products p
WHERE (SELECT COUNT(DISTINCT wi.wishlist_id)
       FROM wishlist_items wi
       WHERE wi.product_id = p.product_id)
    > (SELECT COALESCE(SUM(oi.quantity), 0)
       FROM order_items oi
       WHERE oi.product_id = p.product_id)
ORDER BY wishlist_appearances DESC;


-- ============================================================================
-- SECTION 5: Window Functions
-- ============================================================================

-- Q13: Rank products by total revenue within each category
-- Demonstrates: SUM as window input, RANK(), DENSE_RANK(), ROW_NUMBER()
SELECT
    c.name            AS category_name,
    p.product_id,
    p.name            AS product_name,
    SUM(oi.quantity * oi.unit_price) AS product_revenue,
    RANK()       OVER (PARTITION BY c.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank,
    DENSE_RANK() OVER (PARTITION BY c.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS dense_revenue_rank,
    ROW_NUMBER() OVER (PARTITION BY c.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS row_num
FROM products p
JOIN categories c   ON p.category_id = c.category_id
JOIN order_items oi ON p.product_id  = oi.product_id
GROUP BY c.category_id, c.name, p.product_id, p.name
ORDER BY c.name, revenue_rank;


-- Q14: Month-over-month revenue growth using LAG
-- Demonstrates: LAG(), percentage calculation over ordered window
SELECT
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month_revenue,
    CASE
        WHEN LAG(monthly_revenue) OVER (ORDER BY month) IS NULL THEN NULL
        ELSE ROUND(
            (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
            / LAG(monthly_revenue) OVER (ORDER BY month) * 100, 2
        )
    END AS growth_pct
FROM (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        SUM(total_amount) AS monthly_revenue
    FROM orders
    WHERE status <> 'cancelled'
    GROUP BY DATE_TRUNC('month', order_date)
) monthly
ORDER BY month;


-- Q15: Running total of payments received, partitioned by payment method
-- Demonstrates: SUM() OVER with ROWS frame, running/cumulative total
SELECT
    payment_id,
    payment_method,
    amount,
    payment_date,
    SUM(amount) OVER (
        PARTITION BY payment_method
        ORDER BY payment_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM payments
WHERE status = 'completed'
ORDER BY payment_method, payment_date;


-- Q16: For each customer, show the gap (in days) between consecutive orders
-- Demonstrates: LEAD() / LAG() for inter-row comparison
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    LAG(o.order_date)  OVER w AS previous_order_date,
    LEAD(o.order_date) OVER w AS next_order_date,
    o.order_date - LAG(o.order_date) OVER w AS days_since_last_order
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WINDOW w AS (PARTITION BY c.customer_id ORDER BY o.order_date)
ORDER BY c.customer_id, o.order_date;


-- ============================================================================
-- SECTION 6: Common Table Expressions (CTEs) including Recursive
-- ============================================================================

-- Q17: Customer Lifetime Value (CLV) analysis using CTE
-- Demonstrates: multiple CTEs chained together
WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        c.email,
        COUNT(o.order_id)     AS total_orders,
        SUM(o.total_amount)   AS total_spent,
        MIN(o.order_date)     AS first_order,
        MAX(o.order_date)     AS last_order
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status <> 'cancelled'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
),
clv_calc AS (
    SELECT
        *,
        ROUND(total_spent / NULLIF(total_orders, 0), 2) AS avg_order_value,
        (last_order - first_order)                       AS customer_tenure_days,
        ROUND(total_orders::numeric / GREATEST(
            EXTRACT(EPOCH FROM (last_order - first_order)) / 86400 / 30, 1
        ), 2)                                            AS orders_per_month
    FROM customer_orders
)
SELECT
    customer_id,
    customer_name,
    email,
    total_orders,
    total_spent,
    avg_order_value,
    customer_tenure_days,
    orders_per_month,
    ROUND(avg_order_value * orders_per_month * 12, 2) AS projected_annual_clv,
    NTILE(5) OVER (ORDER BY total_spent DESC) AS clv_quintile
FROM clv_calc
ORDER BY total_spent DESC;


-- Q18: Recursive CTE — build category hierarchy / breadcrumb path
-- Demonstrates: recursive CTE with base case and recursive step
-- (Assumes categories may have a parent_category_id for nesting)
WITH RECURSIVE category_tree AS (
    -- Base case: top-level categories (no parent)
    SELECT
        category_id,
        name,
        parent_category_id,
        name::text AS full_path,
        1          AS depth
    FROM categories
    WHERE parent_category_id IS NULL

    UNION ALL

    -- Recursive step: children join their parents
    SELECT
        c.category_id,
        c.name,
        c.parent_category_id,
        ct.full_path || ' > ' || c.name,
        ct.depth + 1
    FROM categories c
    JOIN category_tree ct ON c.parent_category_id = ct.category_id
)
SELECT
    category_id,
    name,
    full_path,
    depth
FROM category_tree
ORDER BY full_path;


-- ============================================================================
-- SECTION 7: Complex Analytical Queries
-- ============================================================================

-- Q19: Cohort analysis — retention by registration month
-- Tracks what % of customers from each sign-up cohort placed orders in
-- subsequent months.
WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', created_at)::date AS cohort_month
    FROM customers
),
order_months AS (
    SELECT
        o.customer_id,
        DATE_TRUNC('month', o.order_date)::date AS order_month
    FROM orders o
    WHERE o.status <> 'cancelled'
),
cohort_data AS (
    SELECT
        co.cohort_month,
        EXTRACT(MONTH FROM AGE(om.order_month, co.cohort_month))::int
            + EXTRACT(YEAR FROM AGE(om.order_month, co.cohort_month))::int * 12
            AS month_offset,
        COUNT(DISTINCT co.customer_id) AS active_customers
    FROM cohorts co
    JOIN order_months om ON co.customer_id = om.customer_id
    GROUP BY co.cohort_month, month_offset
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    cd.cohort_month,
    cs.cohort_size,
    cd.month_offset,
    cd.active_customers,
    ROUND(100.0 * cd.active_customers / cs.cohort_size, 2) AS retention_pct
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_offset BETWEEN 0 AND 6
ORDER BY cd.cohort_month, cd.month_offset;


-- Q20: Top-3 best-selling products per category (Top-N per group)
-- Demonstrates: CTE + ROW_NUMBER for Top-N extraction
WITH product_sales AS (
    SELECT
        p.category_id,
        cat.name       AS category_name,
        p.product_id,
        p.name         AS product_name,
        SUM(oi.quantity)                    AS units_sold,
        SUM(oi.quantity * oi.unit_price)    AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY p.category_id
            ORDER BY SUM(oi.quantity) DESC
        ) AS rn
    FROM products p
    JOIN categories cat ON p.category_id = cat.category_id
    JOIN order_items oi ON p.product_id  = oi.product_id
    JOIN orders o       ON oi.order_id   = o.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY p.category_id, cat.name, p.product_id, p.name
)
SELECT
    category_name,
    product_name,
    units_sold,
    revenue,
    rn AS rank_in_category
FROM product_sales
WHERE rn <= 3
ORDER BY category_name, rn;


-- Q21: Seller performance dashboard
-- Demonstrates: multiple joins, aggregates, CASE expressions
SELECT
    s.seller_id,
    s.company_name,
    COUNT(DISTINCT p.product_id)    AS products_listed,
    COUNT(DISTINCT o.order_id)      AS orders_fulfilled,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    ROUND(AVG(r.rating), 2)         AS avg_product_rating,
    COUNT(rr.return_id)             AS return_requests,
    CASE
        WHEN COUNT(DISTINCT o.order_id) = 0 THEN 'Inactive'
        WHEN AVG(r.rating) >= 4.5           THEN 'Top Performer'
        WHEN AVG(r.rating) >= 3.5           THEN 'Good'
        WHEN AVG(r.rating) >= 2.5           THEN 'Average'
        ELSE                                     'Needs Improvement'
    END AS performance_tier
FROM sellers s
LEFT JOIN products p        ON s.seller_id  = p.seller_id
LEFT JOIN order_items oi    ON p.product_id = oi.product_id
LEFT JOIN orders o          ON oi.order_id  = o.order_id AND o.status <> 'cancelled'
LEFT JOIN reviews r         ON p.product_id = r.product_id
LEFT JOIN return_requests rr ON o.order_id  = rr.order_id
GROUP BY s.seller_id, s.company_name
ORDER BY total_revenue DESC NULLS LAST;


-- Q22: Inventory health — low stock alerts with reorder recommendations
-- Demonstrates: CASE, subquery for threshold calculation
SELECT
    p.product_id,
    p.name             AS product_name,
    i.quantity          AS current_stock,
    daily_sales.avg_daily_units,
    CASE
        WHEN i.quantity = 0                           THEN 'OUT OF STOCK'
        WHEN i.quantity < daily_sales.avg_daily_units * 7  THEN 'CRITICAL (< 7 days)'
        WHEN i.quantity < daily_sales.avg_daily_units * 14 THEN 'LOW (< 14 days)'
        WHEN i.quantity < daily_sales.avg_daily_units * 30 THEN 'MODERATE (< 30 days)'
        ELSE 'HEALTHY'
    END AS stock_status,
    GREATEST(CEIL(daily_sales.avg_daily_units * 30) - i.quantity, 0) AS reorder_quantity
FROM products p
JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN LATERAL (
    SELECT COALESCE(
        ROUND(SUM(oi.quantity)::numeric / GREATEST(
            EXTRACT(EPOCH FROM (CURRENT_DATE - MIN(o.order_date))) / 86400, 1
        ), 2), 0
    ) AS avg_daily_units
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE oi.product_id = p.product_id
      AND o.status <> 'cancelled'
) daily_sales ON TRUE
ORDER BY
    CASE
        WHEN i.quantity = 0 THEN 1
        WHEN i.quantity < daily_sales.avg_daily_units * 7 THEN 2
        WHEN i.quantity < daily_sales.avg_daily_units * 14 THEN 3
        ELSE 4
    END,
    i.quantity;


-- ============================================================================
-- SECTION 8: Views for Frequently Used Report Queries
-- ============================================================================

-- V1: Daily sales summary view
CREATE OR REPLACE VIEW shopease.vw_daily_sales_summary AS
SELECT
    o.order_date::date                 AS sale_date,
    COUNT(DISTINCT o.order_id)         AS total_orders,
    COUNT(DISTINCT o.customer_id)      AS unique_customers,
    SUM(o.total_amount)                AS total_revenue,
    ROUND(AVG(o.total_amount), 2)      AS avg_order_value,
    SUM(oi.quantity)                   AS total_units_sold
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY o.order_date::date;


-- V2: Product catalogue view with stock and rating info
CREATE OR REPLACE VIEW shopease.vw_product_catalogue AS
SELECT
    p.product_id,
    p.name           AS product_name,
    c.name           AS category_name,
    s.company_name   AS seller_name,
    p.price,
    i.quantity        AS stock_quantity,
    COALESCE(ROUND(AVG(r.rating), 2), 0)  AS avg_rating,
    COUNT(r.review_id) AS review_count
FROM products p
JOIN categories c  ON p.category_id = c.category_id
JOIN sellers s     ON p.seller_id   = s.seller_id
LEFT JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN reviews r   ON p.product_id = r.product_id
GROUP BY p.product_id, p.name, c.name, s.company_name, p.price, i.quantity;


-- V3: Customer order history view
CREATE OR REPLACE VIEW shopease.vw_customer_order_history AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.status AS order_status,
    sh.status AS shipping_status,
    p.payment_method,
    p.status AS payment_status
FROM customers c
JOIN orders o    ON c.customer_id = o.customer_id
LEFT JOIN shipping sh ON o.order_id = sh.order_id
LEFT JOIN payments p  ON o.order_id = p.order_id;


-- V4: Seller performance summary view
CREATE OR REPLACE VIEW shopease.vw_seller_performance AS
SELECT
    s.seller_id,
    s.company_name,
    COUNT(DISTINCT p.product_id)        AS total_products,
    COUNT(DISTINCT o.order_id)          AS total_orders,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue,
    COALESCE(ROUND(AVG(r.rating), 2), 0) AS avg_rating,
    COUNT(DISTINCT rr.return_id)        AS total_returns
FROM sellers s
LEFT JOIN products p         ON s.seller_id  = p.seller_id
LEFT JOIN order_items oi     ON p.product_id = oi.product_id
LEFT JOIN orders o           ON oi.order_id  = o.order_id AND o.status <> 'cancelled'
LEFT JOIN reviews r          ON p.product_id = r.product_id
LEFT JOIN return_requests rr ON o.order_id   = rr.order_id
GROUP BY s.seller_id, s.company_name;
