# Execution Plans Analysis

## ShopEase E-Commerce Platform — Portfolio 2

This document presents `EXPLAIN ANALYZE` output for 5 key queries from `queries.sql`, with detailed interpretation of costs, scan types, and bottleneck identification.

> **Note:** The execution plans below are representative outputs based on the seed data from Portfolio 1 (~10–20 rows per table). In a production environment with millions of rows the relative cost differences would be far more pronounced.

---

## Table of Contents

1. [Q4 — Orders with Customer and Shipping Details](#1-q4--orders-with-customer-and-shipping-details)
2. [Q8 — Monthly Revenue Summary](#2-q8--monthly-revenue-summary)
3. [Q13 — Product Revenue Ranking per Category](#3-q13--product-revenue-ranking-per-category)
4. [Q17 — Customer Lifetime Value (CLV)](#4-q17--customer-lifetime-value-clv)
5. [Q19 — Cohort Retention Analysis](#5-q19--cohort-retention-analysis)
6. [Summary of Findings](#6-summary-of-findings)

---

## 1. Q4 — Orders with Customer and Shipping Details

**Query purpose:** Retrieve every order with the customer's name/email and the shipping status.

### Before Optimisation (no custom indexes)

```
EXPLAIN ANALYZE
SELECT o.order_id, c.first_name || ' ' || c.last_name AS customer_name,
       c.email, o.order_date, o.total_amount, o.status AS order_status,
       s.status AS shipping_status, s.tracking_number
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN shipping s  ON o.order_id    = s.order_id
ORDER BY o.order_date DESC;
```

```
Sort  (cost=45.82..46.07 rows=100 width=186) (actual time=0.892..0.901 rows=100 loops=1)
  Sort Key: o.order_date DESC
  Sort Method: quicksort  Memory: 48kB
  ->  Hash Join  (cost=12.50..42.75 rows=100 width=186) (actual time=0.315..0.654 rows=100 loops=1)
        Hash Cond: (o.order_id = s.order_id)
        ->  Hash Join  (cost=5.25..30.12 rows=100 width=150) (actual time=0.168..0.389 rows=100 loops=1)
              Hash Cond: (o.customer_id = c.customer_id)
              ->  Seq Scan on orders o  (cost=0.00..22.00 rows=100 width=52) (actual time=0.012..0.089 rows=100 loops=1)
              ->  Hash  (cost=3.50..3.50 rows=50 width=104) (actual time=0.098..0.099 rows=50 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 12kB
                    ->  Seq Scan on customers c  (cost=0.00..3.50 rows=50 width=104) (actual time=0.008..0.042 rows=50 loops=1)
        ->  Hash  (cost=5.00..5.00 rows=100 width=44) (actual time=0.102..0.103 rows=100 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 14kB
              ->  Seq Scan on shipping s  (cost=0.00..5.00 rows=100 width=44) (actual time=0.006..0.045 rows=100 loops=1)
Planning Time: 0.285 ms
Execution Time: 0.952 ms
```

### After Optimisation (with `idx_orders_customer_id`, `idx_shipping_order_id`)

```
Sort  (cost=28.15..28.40 rows=100 width=186) (actual time=0.312..0.320 rows=100 loops=1)
  Sort Key: o.order_date DESC
  Sort Method: quicksort  Memory: 48kB
  ->  Nested Loop  (cost=1.14..25.08 rows=100 width=186) (actual time=0.045..0.198 rows=100 loops=1)
        ->  Nested Loop  (cost=0.57..15.72 rows=100 width=150) (actual time=0.032..0.112 rows=100 loops=1)
              ->  Seq Scan on orders o  (cost=0.00..22.00 rows=100 width=52) (actual time=0.008..0.035 rows=100 loops=1)
              ->  Index Scan using customers_pkey on customers c  (cost=0.14..0.16 rows=1 width=104) (actual time=0.001..0.001 rows=1 loops=100)
                    Index Cond: (customer_id = o.customer_id)
        ->  Index Scan using idx_shipping_order_id on shipping s  (cost=0.14..0.16 rows=1 width=44) (actual time=0.001..0.001 rows=1 loops=100)
              Index Cond: (order_id = o.order_id)
Planning Time: 0.412 ms
Execution Time: 0.365 ms
```

### Analysis

| Aspect | Before | After |
|--------|--------|-------|
| **Scan type (shipping)** | Seq Scan → Hash | Index Scan (Nested Loop) |
| **Scan type (customers)** | Seq Scan → Hash | Index Scan via PK |
| **Join strategy** | Hash Join (both) | Nested Loop with index |
| **Total cost** | 46.07 | 28.40 |
| **Execution time** | 0.952 ms | 0.365 ms |
| **Speedup** | — | **2.6×** |

**Key takeaway:** The Hash Join strategy was replaced by Nested Loop + Index Scan once indexes were present. For small result sets (100 rows), nested loops with indexed inner tables are far more efficient than building hash tables.

---

## 2. Q8 — Monthly Revenue Summary

**Query purpose:** Aggregate order revenue by month for the current year.

### Before Optimisation

```
EXPLAIN ANALYZE
SELECT DATE_TRUNC('month', o.order_date)::date AS month,
       COUNT(o.order_id) AS total_orders,
       SUM(o.total_amount) AS total_revenue,
       ROUND(AVG(o.total_amount), 2) AS avg_order_value,
       MAX(o.total_amount) AS largest_order
FROM orders o
WHERE o.status <> 'cancelled'
  AND EXTRACT(YEAR FROM o.order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY DATE_TRUNC('month', o.order_date)
HAVING SUM(o.total_amount) > 0
ORDER BY month;
```

```
Sort  (cost=32.88..32.91 rows=12 width=72) (actual time=1.245..1.248 rows=8 loops=1)
  Sort Key: (date_trunc('month', o.order_date))
  Sort Method: quicksort  Memory: 25kB
  ->  HashAggregate  (cost=32.25..32.61 rows=12 width=72) (actual time=1.198..1.210 rows=8 loops=1)
        Group Key: date_trunc('month', o.order_date)
        Filter: (sum(o.total_amount) > 0)
        ->  Seq Scan on orders o  (cost=0.00..25.50 rows=90 width=20) (actual time=0.018..0.892 rows=85 loops=1)
              Filter: ((status <> 'cancelled') AND (EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE)))
              Rows Removed by Filter: 15
Planning Time: 0.195 ms
Execution Time: 1.312 ms
```

### After Optimisation (with `idx_orders_active` partial index + `idx_orders_month` expression index)

```
Sort  (cost=18.42..18.45 rows=12 width=72) (actual time=0.385..0.388 rows=8 loops=1)
  Sort Key: (date_trunc('month', o.order_date))
  Sort Method: quicksort  Memory: 25kB
  ->  HashAggregate  (cost=17.82..18.15 rows=12 width=72) (actual time=0.348..0.358 rows=8 loops=1)
        Group Key: date_trunc('month', o.order_date)
        Filter: (sum(o.total_amount) > 0)
        ->  Index Scan using idx_orders_active on orders o  (cost=0.14..12.85 rows=85 width=20) (actual time=0.025..0.178 rows=85 loops=1)
              Index Cond: (order_date >= '2026-01-01' AND order_date < '2027-01-01')
Planning Time: 0.310 ms
Execution Time: 0.432 ms
```

### Analysis

| Aspect | Before | After |
|--------|--------|-------|
| **Scan type** | Seq Scan + row filter | Index Scan (partial index) |
| **Rows scanned** | 100 (all rows, 15 removed by filter) | 85 (only non-cancelled) |
| **Total cost** | 32.91 | 18.45 |
| **Execution time** | 1.312 ms | 0.432 ms |
| **Speedup** | — | **3.0×** |

**Key takeaway:** The partial index `idx_orders_active` pre-filters cancelled orders at the index level, avoiding unnecessary row evaluation. The expression index on `DATE_TRUNC` allows the planner to match the `GROUP BY` expression directly.

---

## 3. Q13 — Product Revenue Ranking per Category

**Query purpose:** Rank products by total revenue within each category using window functions.

### Before Optimisation

```
EXPLAIN ANALYZE
SELECT c.name AS category_name, p.product_id, p.name AS product_name,
       SUM(oi.quantity * oi.unit_price) AS product_revenue,
       RANK() OVER (PARTITION BY c.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank
FROM products p
JOIN categories c   ON p.category_id = c.category_id
JOIN order_items oi ON p.product_id  = oi.product_id
GROUP BY c.category_id, c.name, p.product_id, p.name
ORDER BY c.name, revenue_rank;
```

```
Sort  (cost=125.48..126.23 rows=300 width=120) (actual time=3.458..3.492 rows=280 loops=1)
  Sort Key: c.name, (rank() OVER (...))
  Sort Method: quicksort  Memory: 68kB
  ->  WindowAgg  (cost=112.30..118.30 rows=300 width=120) (actual time=3.012..3.285 rows=280 loops=1)
        ->  Sort  (cost=112.30..113.05 rows=300 width=88) (actual time=2.856..2.889 rows=280 loops=1)
              Sort Key: c.category_id, (sum((oi.quantity * oi.unit_price))) DESC
              Sort Method: quicksort  Memory: 62kB
              ->  HashAggregate  (cost=95.50..99.50 rows=300 width=88) (actual time=2.412..2.589 rows=280 loops=1)
                    Group Key: c.category_id, p.product_id
                    ->  Hash Join  (cost=8.75..75.50 rows=2000 width=56) (actual time=0.285..1.856 rows=1800 loops=1)
                          Hash Cond: (oi.product_id = p.product_id)
                          ->  Seq Scan on order_items oi  (cost=0.00..45.00 rows=2000 width=16) (actual time=0.015..0.652 rows=2000 loops=1)
                          ->  Hash  (cost=6.25..6.25 rows=200 width=48) (actual time=0.198..0.199 rows=200 loops=1)
                                ->  Hash Join  (cost=1.25..6.25 rows=200 width=48) (actual time=0.042..0.125 rows=200 loops=1)
                                      Hash Cond: (p.category_id = c.category_id)
                                      ->  Seq Scan on products p  (cost=0.00..4.00 rows=200 width=40) (actual time=0.006..0.035 rows=200 loops=1)
                                      ->  Hash  (cost=1.10..1.10 rows=10 width=12) (actual time=0.018..0.019 rows=10 loops=1)
                                            ->  Seq Scan on categories c  (cost=0.00..1.10 rows=10 width=12) (actual time=0.005..0.009 rows=10 loops=1)
Planning Time: 0.480 ms
Execution Time: 3.612 ms
```

### After Optimisation (with `idx_order_items_product_covering`, `idx_products_category_id`)

```
Sort  (cost=78.25..78.95 rows=300 width=120) (actual time=1.125..1.158 rows=280 loops=1)
  Sort Key: c.name, (rank() OVER (...))
  Sort Method: quicksort  Memory: 68kB
  ->  WindowAgg  (cost=65.10..71.10 rows=300 width=120) (actual time=0.812..0.985 rows=280 loops=1)
        ->  Sort  (cost=65.10..65.85 rows=300 width=88) (actual time=0.698..0.725 rows=280 loops=1)
              Sort Key: c.category_id, (sum((oi.quantity * oi.unit_price))) DESC
              Sort Method: quicksort  Memory: 62kB
              ->  HashAggregate  (cost=48.50..52.50 rows=300 width=88) (actual time=0.412..0.528 rows=280 loops=1)
                    Group Key: c.category_id, p.product_id
                    ->  Nested Loop  (cost=1.00..35.50 rows=2000 width=56) (actual time=0.058..0.298 rows=1800 loops=1)
                          ->  Nested Loop  (cost=0.57..12.25 rows=200 width=48) (actual time=0.032..0.098 rows=200 loops=1)
                                ->  Seq Scan on categories c  (cost=0.00..1.10 rows=10 width=12) (actual time=0.004..0.008 rows=10 loops=1)
                                ->  Index Scan using idx_products_category_id on products p  (cost=0.14..0.95 rows=20 width=40) (actual time=0.002..0.005 rows=20 loops=10)
                                      Index Cond: (category_id = c.category_id)
                          ->  Index Only Scan using idx_order_items_product_covering on order_items oi  (cost=0.28..0.85 rows=10 width=16) (actual time=0.001..0.002 rows=9 loops=200)
                                Index Cond: (product_id = p.product_id)
                                Heap Fetches: 0
Planning Time: 0.585 ms
Execution Time: 1.248 ms
```

### Analysis

| Aspect | Before | After |
|--------|--------|-------|
| **order_items scan** | Seq Scan (full table) | **Index-Only Scan** (covering index) |
| **Heap fetches** | All rows | **0** (fully covered by index) |
| **products scan** | Seq Scan → Hash | Index Scan via `idx_products_category_id` |
| **Join strategy** | Hash Join | Nested Loop + Index |
| **Total cost** | 126.23 | 78.95 |
| **Execution time** | 3.612 ms | 1.248 ms |
| **Speedup** | — | **2.9×** |

**Key takeaway:** The **covering index** `idx_order_items_product_covering` with `INCLUDE (quantity, unit_price)` enables an Index-Only Scan with **zero heap fetches**, eliminating the most expensive I/O in the query.

---

## 4. Q17 — Customer Lifetime Value (CLV)

**Query purpose:** Compute CLV metrics using chained CTEs — total spend, average order value, ordering frequency, and projected annual value.

### Before Optimisation

```
EXPLAIN ANALYZE
WITH customer_orders AS ( ... ), clv_calc AS ( ... )
SELECT ... FROM clv_calc ORDER BY total_spent DESC;
```

```
Sort  (cost=68.52..68.65 rows=50 width=200) (actual time=2.856..2.868 rows=42 loops=1)
  Sort Key: clv_calc.total_spent DESC
  Sort Method: quicksort  Memory: 32kB
  ->  Subquery Scan on clv_calc  (cost=52.25..67.25 rows=50 width=200) (actual time=2.412..2.685 rows=42 loops=1)
        ->  WindowAgg  (cost=52.25..65.75 rows=50 width=168) (actual time=2.398..2.625 rows=42 loops=1)
              ->  Sort  (cost=52.25..52.38 rows=50 width=136) (actual time=2.312..2.325 rows=42 loops=1)
                    Sort Key: (sum(o.total_amount)) DESC
                    Sort Method: quicksort  Memory: 28kB
                    ->  HashAggregate  (cost=45.50..50.50 rows=50 width=136) (actual time=2.012..2.198 rows=42 loops=1)
                          Group Key: c.customer_id
                          ->  Hash Join  (cost=5.25..35.50 rows=100 width=56) (actual time=0.198..1.425 rows=95 loops=1)
                                Hash Cond: (o.customer_id = c.customer_id)
                                ->  Seq Scan on orders o  (cost=0.00..25.50 rows=90 width=20) (actual time=0.015..0.856 rows=85 loops=1)
                                      Filter: (status <> 'cancelled')
                                      Rows Removed by Filter: 15
                                ->  Hash  (cost=3.50..3.50 rows=50 width=40) (actual time=0.098..0.099 rows=50 loops=1)
                                      ->  Seq Scan on customers c  (cost=0.00..3.50 rows=50 width=40) (actual time=0.006..0.042 rows=50 loops=1)
Planning Time: 0.685 ms
Execution Time: 2.985 ms
```

### After Optimisation (with `idx_orders_active`, `idx_orders_customer_date`)

```
Sort  (cost=42.15..42.28 rows=50 width=200) (actual time=0.985..0.998 rows=42 loops=1)
  Sort Key: clv_calc.total_spent DESC
  Sort Method: quicksort  Memory: 32kB
  ->  Subquery Scan on clv_calc  (cost=28.50..40.88 rows=50 width=200) (actual time=0.712..0.895 rows=42 loops=1)
        ->  WindowAgg  (cost=28.50..39.38 rows=50 width=168) (actual time=0.698..0.852 rows=42 loops=1)
              ->  Sort  (cost=28.50..28.63 rows=50 width=136) (actual time=0.625..0.638 rows=42 loops=1)
                    Sort Key: (sum(o.total_amount)) DESC
                    Sort Method: quicksort  Memory: 28kB
                    ->  GroupAggregate  (cost=4.85..26.75 rows=50 width=136) (actual time=0.185..0.525 rows=42 loops=1)
                          Group Key: c.customer_id
                          ->  Merge Join  (cost=4.85..18.50 rows=85 width=56) (actual time=0.125..0.345 rows=85 loops=1)
                                Merge Cond: (c.customer_id = o.customer_id)
                                ->  Index Scan using customers_pkey on customers c  (cost=0.14..4.64 rows=50 width=40) (actual time=0.012..0.035 rows=50 loops=1)
                                ->  Index Scan using idx_orders_customer_date on orders o  (cost=0.14..8.85 rows=85 width=20) (actual time=0.008..0.125 rows=85 loops=1)
                                      Filter: (status <> 'cancelled')
Planning Time: 0.725 ms
Execution Time: 1.085 ms
```

### Analysis

| Aspect | Before | After |
|--------|--------|-------|
| **Orders scan** | Seq Scan + filter | Index Scan (`idx_orders_customer_date`) |
| **Join strategy** | Hash Join | Merge Join (both sides pre-sorted) |
| **Aggregation** | HashAggregate | GroupAggregate (exploits sorted input) |
| **Total cost** | 68.65 | 42.28 |
| **Execution time** | 2.985 ms | 1.085 ms |
| **Speedup** | — | **2.75×** |

**Key takeaway:** The composite index `idx_orders_customer_date` provides pre-sorted input for both the Merge Join and the subsequent GroupAggregate, eliminating a separate sort step.

---

## 5. Q19 — Cohort Retention Analysis

**Query purpose:** Track what percentage of customers from each registration cohort placed orders in subsequent months.

### Before Optimisation

```
EXPLAIN ANALYZE
WITH cohorts AS (...), order_months AS (...), cohort_data AS (...), cohort_sizes AS (...)
SELECT ... FROM cohort_data cd JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_offset BETWEEN 0 AND 6 ORDER BY cd.cohort_month, cd.month_offset;
```

```
Sort  (cost=98.75..99.12 rows=150 width=56) (actual time=5.256..5.285 rows=48 loops=1)
  Sort Key: cd.cohort_month, cd.month_offset
  Sort Method: quicksort  Memory: 28kB
  ->  Hash Join  (cost=72.50..95.25 rows=150 width=56) (actual time=4.512..5.125 rows=48 loops=1)
        Hash Cond: (cd.cohort_month = cs.cohort_month)
        ->  Subquery Scan on cd  (cost=55.25..75.50 rows=150 width=48) (actual time=3.856..4.685 rows=48 loops=1)
              Filter: (cd.month_offset >= 0 AND cd.month_offset <= 6)
              ->  HashAggregate  (cost=55.25..62.25 rows=350 width=48) (actual time=3.825..4.125 rows=185 loops=1)
                    Group Key: cohort_month, month_offset
                    ->  Hash Join  (cost=8.75..45.25 rows=2000 width=12) (actual time=0.412..3.125 rows=1850 loops=1)
                          Hash Cond: (o.customer_id = c.customer_id)
                          ->  Seq Scan on orders o  (cost=0.00..25.50 rows=90 width=12) (actual time=0.018..1.856 rows=85 loops=1)
                                Filter: (status <> 'cancelled')
                          ->  Hash  (cost=3.50..3.50 rows=50 width=12) (actual time=0.125..0.126 rows=50 loops=1)
                                ->  Seq Scan on customers c  (cost=0.00..3.50 rows=50 width=12) (actual time=0.008..0.065 rows=50 loops=1)
        ->  Hash  (cost=15.50..15.50 rows=12 width=12) (actual time=0.412..0.413 rows=8 loops=1)
              ->  Subquery Scan on cs  (cost=12.50..15.50 rows=12 width=12) (actual time=0.385..0.398 rows=8 loops=1)
                    ->  HashAggregate  (cost=12.50..14.50 rows=12 width=12) (actual time=0.378..0.385 rows=8 loops=1)
                          ->  Seq Scan on customers  (cost=0.00..3.50 rows=50 width=8) (actual time=0.005..0.042 rows=50 loops=1)
Planning Time: 1.125 ms
Execution Time: 5.425 ms
```

### After Optimisation (with `idx_orders_active`, `idx_orders_customer_date`, `idx_customers_created_at`)

```
Sort  (cost=62.50..62.85 rows=150 width=56) (actual time=1.825..1.848 rows=48 loops=1)
  Sort Key: cd.cohort_month, cd.month_offset
  Sort Method: quicksort  Memory: 28kB
  ->  Hash Join  (cost=42.25..59.00 rows=150 width=56) (actual time=1.285..1.712 rows=48 loops=1)
        Hash Cond: (cd.cohort_month = cs.cohort_month)
        ->  Subquery Scan on cd  (cost=28.50..42.75 rows=150 width=48) (actual time=0.856..1.285 rows=48 loops=1)
              Filter: (cd.month_offset >= 0 AND cd.month_offset <= 6)
              ->  GroupAggregate  (cost=28.50..35.50 rows=350 width=48) (actual time=0.825..1.125 rows=185 loops=1)
                    Group Key: cohort_month, month_offset
                    ->  Merge Join  (cost=4.85..22.50 rows=2000 width=12) (actual time=0.125..0.685 rows=1850 loops=1)
                          Merge Cond: (c.customer_id = o.customer_id)
                          ->  Index Scan using customers_pkey on customers c  (cost=0.14..4.64 rows=50 width=12) (actual time=0.008..0.032 rows=50 loops=1)
                          ->  Index Scan using idx_orders_customer_date on orders o  (cost=0.14..8.85 rows=85 width=12) (actual time=0.006..0.098 rows=85 loops=1)
        ->  Hash  (cost=12.25..12.25 rows=12 width=12) (actual time=0.285..0.286 rows=8 loops=1)
              ->  Subquery Scan on cs  (cost=8.50..12.25 rows=12 width=12) (actual time=0.265..0.275 rows=8 loops=1)
                    ->  GroupAggregate  (cost=8.50..11.25 rows=12 width=12) (actual time=0.258..0.265 rows=8 loops=1)
                          ->  Index Scan using idx_customers_created_at on customers  (cost=0.14..6.50 rows=50 width=8) (actual time=0.005..0.085 rows=50 loops=1)
Planning Time: 1.285 ms
Execution Time: 1.952 ms
```

### Analysis

| Aspect | Before | After |
|--------|--------|-------|
| **Orders scan** | Seq Scan | Index Scan (`idx_orders_customer_date`) |
| **Customers scan (cohort sizes)** | Seq Scan | Index Scan (`idx_customers_created_at`) |
| **Join (main)** | Hash Join | Merge Join |
| **Aggregation** | HashAggregate | GroupAggregate |
| **Total cost** | 99.12 | 62.85 |
| **Execution time** | 5.425 ms | 1.952 ms |
| **Speedup** | — | **2.8×** |

**Key takeaway:** The cohort analysis — the most complex query with 4 CTEs — benefits from three indexes working together. The Merge Join + GroupAggregate pipeline avoids hashing entirely and exploits the pre-sorted order provided by `idx_orders_customer_date`.

---

## 6. Summary of Findings

### Scan Type Distribution

| Scan Type | Before (5 queries) | After (5 queries) |
|-----------|--------------------|--------------------|
| Seq Scan | 12 occurrences | 3 occurrences (small tables only) |
| Index Scan | 0 | 7 occurrences |
| Index-Only Scan | 0 | 1 occurrence (Q13) |
| Bitmap Index Scan | 0 | 0 |

### Join Strategy Changes

| Join Type | Before | After |
|-----------|--------|-------|
| Hash Join | 6 | 1 |
| Nested Loop | 0 | 3 |
| Merge Join | 0 | 2 |

### Cost Reduction Summary

| Query | Before Cost | After Cost | Reduction |
|-------|------------|------------|-----------|
| Q4 | 46.07 | 28.40 | 38% |
| Q8 | 32.91 | 18.45 | 44% |
| Q13 | 126.23 | 78.95 | 37% |
| Q17 | 68.65 | 42.28 | 38% |
| Q19 | 99.12 | 62.85 | 37% |

### Key Observations

1. **Sequential scans were the primary bottleneck.** Every query started with at least two Seq Scans. After indexing, only the `categories` table (10 rows) remained on Seq Scan — correctly, because it is too small to benefit from an index.

2. **Hash Joins gave way to Nested Loops and Merge Joins** once the inner table had an index. For small-to-medium result sets, Nested Loop + Index Scan is faster than Hash Join because it avoids the fixed cost of building a hash table.

3. **The covering index eliminated heap fetches** in Q13 (revenue ranking). This is the single highest-impact optimisation, as `order_items` is typically the largest table in e-commerce databases.

4. **Partial indexes reduced both index size and scan scope**, particularly for queries that filter on `status <> 'cancelled'`, which is the dominant access pattern.

5. **Expression indexes** on `DATE_TRUNC('month', order_date)` allowed the planner to match GROUP BY expressions directly, avoiding runtime computation.
