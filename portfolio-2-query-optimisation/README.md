# Portfolio 2: Query Processing and Optimisation

## ShopEase E-Commerce Platform

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Query Catalogue](#2-query-catalogue)
3. [Optimisation Techniques Applied](#3-optimisation-techniques-applied)
4. [Indexing Strategy](#4-indexing-strategy)
5. [Performance Analysis Summary](#5-performance-analysis-summary)
6. [Views](#6-views)
7. [Conclusions](#7-conclusions)

---

## 1. Introduction

This portfolio demonstrates advanced SQL query design and performance optimisation for the **ShopEase** e-commerce platform. It contains 22 queries of increasing complexity and 4 database views, supported by a comprehensive indexing strategy and execution plan analysis.

The database engine is **PostgreSQL** and all objects reside in the `shopease` schema created in Portfolio 1. The workload covers the full spectrum of SQL features required for real-world e-commerce analytics.

**Files in this portfolio:**

| File | Purpose |
|------|---------|
| `queries.sql` | 22 queries + 4 views covering all SQL complexity levels |
| `indexing-optimisation.sql` | Strategic index creation (B-tree, composite, partial, covering, expression) |
| `execution-plans.md` | EXPLAIN ANALYZE output and analysis for 5 key queries |
| `performance-analysis.md` | Before/after comparison tables for query performance |
| `README.md` | This document — full documentation of the portfolio |

---

## 2. Query Catalogue

### Section 1 — Simple SELECTs

| # | Query | Key Features | Purpose |
|---|-------|-------------|---------|
| Q1 | Top 10 most expensive in-stock products | `WHERE`, `ORDER BY DESC`, `LIMIT`, `JOIN` | Product browsing / merchandising |
| Q2 | Customers registered in last 90 days | Date arithmetic, `INTERVAL` | Marketing — new user targeting |
| Q3 | Keyword product search | `ILIKE`, `OR`, pattern matching | Full-text search use case |

### Section 2 — JOINs

| # | Query | Key Features | Purpose |
|---|-------|-------------|---------|
| Q4 | Orders with customer and shipping details | `INNER JOIN` (3 tables) | Order management dashboard |
| Q5 | Products with review statistics | `LEFT JOIN`, `COALESCE`, `AVG` | Product catalogue enrichment |
| Q6 | Sellers with no sales | `LEFT JOIN` + `IS NULL` (anti-join) | Seller onboarding analysis |
| Q7 | Customer-wishlist reconciliation | `FULL OUTER JOIN` | Data auditing |

### Section 3 — Aggregates with GROUP BY / HAVING

| # | Query | Key Features | Purpose |
|---|-------|-------------|---------|
| Q8 | Monthly revenue summary | `DATE_TRUNC`, `SUM`, `COUNT`, `AVG`, `MAX`, `HAVING` | Financial reporting |
| Q9 | High-value categories | `COUNT`, `AVG`, multiple `HAVING` conditions | Category management |

### Section 4 — Subqueries

| # | Query | Key Features | Purpose |
|---|-------|-------------|---------|
| Q10 | Above-average-price products per category | Correlated subquery in `WHERE` | Pricing analysis |
| Q11 | Customers with above-average order count | Non-correlated subquery in `HAVING` | Customer segmentation |
| Q12 | Wishlist vs. purchase comparison | Correlated subqueries in `SELECT` and `WHERE` | Conversion funnel analysis |

### Section 5 — Window Functions

| # | Query | Key Features | Purpose |
|---|-------|-------------|---------|
| Q13 | Product revenue ranking per category | `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `PARTITION BY` | Category leaderboard |
| Q14 | Month-over-month revenue growth | `LAG()`, percentage calculation | Trend analysis |
| Q15 | Running payment totals by method | `SUM() OVER` with `ROWS` frame | Cash-flow monitoring |
| Q16 | Inter-order gap per customer | `LAG()`, `LEAD()`, `WINDOW` clause | Customer engagement analysis |

### Section 6 — Common Table Expressions

| # | Query | Key Features | Purpose |
|---|-------|-------------|---------|
| Q17 | Customer Lifetime Value (CLV) | Multiple chained CTEs, `NTILE()` | Strategic customer valuation |
| Q18 | Category hierarchy / breadcrumb | **Recursive CTE** | Navigation / UI breadcrumbs |

### Section 7 — Complex Analytical Queries

| # | Query | Key Features | Purpose |
|---|-------|-------------|---------|
| Q19 | Cohort retention analysis | Multi-CTE, `AGE()`, month offsets | Retention / churn analytics |
| Q20 | Top-3 products per category | CTE + `ROW_NUMBER()` for Top-N | Merchandising / buying |
| Q21 | Seller performance dashboard | 6-table join, `CASE`, aggregates | Marketplace management |
| Q22 | Inventory health / reorder alerts | `LATERAL` join, `CASE`, subquery | Supply chain management |

---

## 3. Optimisation Techniques Applied

### 3.1 Join Ordering and Type Selection

- **INNER JOINs** are used when both sides must match (e.g., orders ↔ customers), allowing the planner to freely reorder joins.
- **LEFT JOINs** are used when the "optional" side may be missing (e.g., products with no reviews).
- **Anti-join pattern** (`LEFT JOIN … WHERE pk IS NULL`) in Q6 is typically optimised by PostgreSQL into a Hash Anti Join, which is more efficient than `NOT IN` with nullable columns.

### 3.2 Predicate Pushdown

Filters like `WHERE o.status <> 'cancelled'` are placed as early as possible (on the `orders` table) so that the planner can eliminate rows before performing expensive joins and aggregations.

### 3.3 Aggregate Pushdown

Queries like Q5 group by the product before joining to categories, reducing the number of rows that flow through subsequent joins.

### 3.4 Window Functions vs. Self-Joins

Window functions (`LAG`, `LEAD`, `ROW_NUMBER`) in Q13–Q16 replace what would otherwise require correlated subqueries or self-joins, reducing query complexity from O(n²) to O(n log n).

### 3.5 CTEs for Readability and Reuse

Multi-step analytical queries (Q17, Q19) use CTEs to decompose logic into named, testable stages. PostgreSQL 12+ can inline non-recursive CTEs, so there is no materialisation penalty.

### 3.6 LATERAL Joins

Q22 uses `LEFT JOIN LATERAL` to compute per-product daily sales averages, which is more efficient than a correlated subquery in the `SELECT` list because it allows the planner to push predicates into the subquery.

### 3.7 Partial Indexes

Partial indexes (e.g., `WHERE status <> 'cancelled'`) dramatically reduce index size and scan time for workloads that systematically exclude a subset of rows.

### 3.8 Covering Indexes (INCLUDE)

The covering index on `order_items(product_id, order_id) INCLUDE (quantity, unit_price)` enables **Index-Only Scans**, avoiding heap fetches entirely for revenue calculations.

---

## 4. Indexing Strategy

Full details are in `indexing-optimisation.sql`. Summary:

| Index Type | Count | Examples |
|-----------|-------|---------|
| B-tree (single column) | 9 | `idx_orders_customer_id`, `idx_reviews_product_id` |
| Composite (multi-column) | 3 | `idx_orders_customer_date`, `idx_order_items_product_covering` |
| Partial | 3 | `idx_orders_active`, `idx_inventory_out_of_stock`, `idx_payments_completed` |
| Covering (INCLUDE) | 1 | `idx_order_items_product_covering` |
| Expression | 1 | `idx_orders_month` (on `DATE_TRUNC('month', order_date)`) |
| GIN / trigram | 2 | `idx_products_name_trgm` (optional, requires `pg_trgm`) |

The script also documents **when NOT to index** (small tables, low-selectivity columns, write-heavy tables) and provides a monitoring query using `pg_stat_user_indexes`.

---

## 5. Performance Analysis Summary

See `performance-analysis.md` for the full before/after comparison. Key highlights:

- **Average query speedup: 5–15×** after adding targeted indexes.
- **Index-Only Scans** reduced heap I/O by up to 80% for revenue aggregation queries.
- **Partial indexes** cut index size by 20–30% for queries filtering on order status.
- **Expression index** on `DATE_TRUNC` eliminated expensive sort operations in monthly aggregation queries.

---

## 6. Views

Four views are created to encapsulate commonly used report queries:

| View | Purpose | Key Joins |
|------|---------|-----------|
| `vw_daily_sales_summary` | Daily revenue, order count, units sold | orders ↔ order_items |
| `vw_product_catalogue` | Product listing with stock, rating, seller | products ↔ categories ↔ sellers ↔ inventory ↔ reviews |
| `vw_customer_order_history` | Full order history per customer | customers ↔ orders ↔ shipping ↔ payments |
| `vw_seller_performance` | Seller KPIs (revenue, ratings, returns) | sellers ↔ products ↔ order_items ↔ orders ↔ reviews ↔ return_requests |

Views provide:
- **Abstraction**: application code references the view, not the underlying joins.
- **Security**: column-level access control via `GRANT SELECT` on views.
- **Consistency**: a single source of truth for report definitions.

---

## 7. Conclusions

This portfolio demonstrates that query performance in PostgreSQL can be dramatically improved through:

1. **Thoughtful query design** — choosing the right join types, using window functions instead of self-joins, and decomposing complex logic with CTEs.
2. **Strategic indexing** — targeting the columns and expressions that appear in `WHERE`, `JOIN`, `ORDER BY`, and `GROUP BY` clauses, and using partial and covering indexes to minimise I/O.
3. **Execution plan analysis** — using `EXPLAIN ANALYZE` to identify bottlenecks (sequential scans, large sort operations, hash joins on unindexed columns) and verify that indexes are being used.
4. **Ongoing monitoring** — using `pg_stat_user_indexes` and `pg_stat_user_tables` to identify unused indexes and track table bloat.

The combination of these techniques reduced average query execution time from **12–25 ms to 0.5–3 ms** for the representative workload, demonstrating the importance of database optimisation in production e-commerce systems.
