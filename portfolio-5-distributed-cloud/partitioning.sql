-- ============================================================================
-- ShopEase E-Commerce Platform — PostgreSQL Declarative Partitioning Script
-- ============================================================================
-- Course      : MIT 8103 Advanced Database Systems
-- Session     : 2026/2027 Academic Session
-- Target RDBMS: PostgreSQL 15+
-- Schema      : shopease
-- Author      : Portfolio 5 — Distributed and Cloud Database Exercise
-- Description : Complete DDL and verification queries demonstrating Range, List,
--               and Hash partitioning strategies alongside Partition Pruning.
-- ============================================================================

SET search_path TO shopease;

-- ============================================================================
-- 1. RANGE PARTITIONING: ORDERS BY ORDER_DATE (QUARTERLY INTERVALS)
-- ============================================================================
-- Business Context: In high-volume e-commerce, 90% of operational queries touch
-- orders created in the last 90 days. Range partitioning allows PostgreSQL to
-- completely prune away years of cold data during operational scans.
-- ============================================================================

-- Drop if exists for clean re-runs
DROP TABLE IF EXISTS shopease.orders_partitioned CASCADE;

-- Master Partitioned Table
CREATE TABLE shopease.orders_partitioned (
    order_id            BIGSERIAL,
    customer_id         INT             NOT NULL,
    shipping_address_id INT             NOT NULL,
    billing_address_id  INT             NOT NULL,
    order_status        VARCHAR(30)     NOT NULL,
    subtotal            NUMERIC(12, 2)  NOT NULL,
    tax_amount          NUMERIC(12, 2)  NOT NULL DEFAULT 0.00,
    shipping_cost       NUMERIC(10, 2)  NOT NULL DEFAULT 0.00,
    total_amount        NUMERIC(12, 2)  NOT NULL,
    order_date          TIMESTAMP       NOT NULL,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Partition key MUST be included in any unique or primary key constraint
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

-- Child Partition: Q3 2025
CREATE TABLE shopease.orders_2025_q3 PARTITION OF shopease.orders_partitioned
    FOR VALUES FROM ('2025-07-01 00:00:00') TO ('2025-10-01 00:00:00');

-- Child Partition: Q4 2025 (Black Friday / Holiday Season)
CREATE TABLE shopease.orders_2025_q4 PARTITION OF shopease.orders_partitioned
    FOR VALUES FROM ('2025-10-01 00:00:00') TO ('2026-01-01 00:00:00');

-- Child Partition: Q1 2026 (Current Active Quarter)
CREATE TABLE shopease.orders_2026_q1 PARTITION OF shopease.orders_partitioned
    FOR VALUES FROM ('2026-01-01 00:00:00') TO ('2026-04-01 00:00:00');

-- Child Partition: Q2 2026 (Upcoming Quarter)
CREATE TABLE shopease.orders_2026_q2 PARTITION OF shopease.orders_partitioned
    FOR VALUES FROM ('2026-04-01 00:00:00') TO ('2026-07-01 00:00:00');

-- Default Partition (Safety net for catch-all dates)
CREATE TABLE shopease.orders_default PARTITION OF shopease.orders_partitioned DEFAULT;

-- Local Indexes on Partitions (created automatically across child partitions)
CREATE INDEX idx_orders_part_cust_date ON shopease.orders_partitioned (customer_id, order_date DESC);
CREATE INDEX idx_orders_part_status ON shopease.orders_partitioned (order_status);


-- ============================================================================
-- 2. LIST PARTITIONING: CUSTOMERS BY GEOGRAPHICAL TERRITORY
-- ============================================================================
-- Business Context: Enforces strict GDPR compliance and localized latency by
-- keeping EU, UK, and North American customer datasets partitioned.
-- ============================================================================

DROP TABLE IF EXISTS shopease.customers_partitioned CASCADE;

CREATE TABLE shopease.customers_partitioned (
    customer_id     BIGSERIAL,
    region          VARCHAR(10)     NOT NULL, -- 'UK', 'EU', 'US', 'OTHER'
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id, region)
) PARTITION BY LIST (region);

-- Partition 1: United Kingdom
CREATE TABLE shopease.customers_uk PARTITION OF shopease.customers_partitioned
    FOR VALUES IN ('UK');

-- Partition 2: European Union (GDPR strict zone)
CREATE TABLE shopease.customers_eu PARTITION OF shopease.customers_partitioned
    FOR VALUES IN ('DE', 'FR', 'IT', 'ES', 'NL', 'IE');

-- Partition 3: United States & Canada
CREATE TABLE shopease.customers_na PARTITION OF shopease.customers_partitioned
    FOR VALUES IN ('US', 'CA');

-- Partition 4: Rest of World (Default)
CREATE TABLE shopease.customers_row PARTITION OF shopease.customers_partitioned DEFAULT;


-- ============================================================================
-- 3. HASH PARTITIONING: INVENTORY BY PRODUCT_ID
-- ============================================================================
-- Business Context: Distributes concurrent inventory lock updates uniformly
-- across 4 discrete physical table segments to maximize IO parallelism.
-- ============================================================================

DROP TABLE IF EXISTS shopease.inventory_partitioned CASCADE;

CREATE TABLE shopease.inventory_partitioned (
    inventory_id        BIGSERIAL,
    product_id          INT             NOT NULL,
    quantity_in_stock   INT             NOT NULL DEFAULT 0,
    warehouse_location  VARCHAR(100),
    last_restocked      TIMESTAMP,
    PRIMARY KEY (inventory_id, product_id)
) PARTITION BY HASH (product_id);

CREATE TABLE shopease.inventory_hash_0 PARTITION OF shopease.inventory_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE shopease.inventory_hash_1 PARTITION OF shopease.inventory_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE shopease.inventory_hash_2 PARTITION OF shopease.inventory_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE shopease.inventory_hash_3 PARTITION OF shopease.inventory_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 3);


-- ============================================================================
-- 4. SAMPLE SEEDING FOR PARTITIONED OBJECTS
-- ============================================================================

INSERT INTO shopease.orders_partitioned (customer_id, shipping_address_id, billing_address_id, order_status, subtotal, tax_amount, shipping_cost, total_amount, order_date)
VALUES
    (1, 1, 1, 'delivered', 89.99, 18.00, 4.99, 112.98, '2025-08-15 11:20:00'),
    (2, 2, 2, 'delivered', 3499.00, 699.80, 0.00, 4198.80, '2025-11-28 09:15:00'), -- Black Friday
    (3, 3, 3, 'delivered', 249.50, 49.90, 9.99, 309.39, '2025-12-22 14:00:00'), -- Christmas
    (1, 1, 1, 'processing', 109.99, 22.00, 4.99, 136.98, '2026-02-10 16:30:00'), -- Q1 2026
    (4, 4, 4, 'pending', 99.00, 19.80, 0.00, 118.80, '2026-03-01 10:05:00');   -- Q1 2026


-- ============================================================================
-- 5. PARTITION PRUNING DEMONSTRATION & PROOF
-- ============================================================================
-- Enable partition pruning explicitly in PostgreSQL (default is on)
SET enable_partition_pruning = on;

-- Demonstration Query 1: Filter on Order Date in February 2026
-- Notice in the EXPLAIN output that PostgreSQL scans ONLY `orders_2026_q1`!
-- `orders_2025_q3`, `orders_2025_q4`, and `orders_2026_q2` are pruned (never read from disk).
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, total_amount, order_date
FROM shopease.orders_partitioned
WHERE order_date >= '2026-02-01 00:00:00' AND order_date < '2026-03-01 00:00:00';

-- Demonstration Query 2: Territory Scan for UK Customers
-- PostgreSQL planner completely ignores the EU, NA, and ROW partitions.
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, first_name, email
FROM shopease.customers_partitioned
WHERE region = 'UK';


-- ============================================================================
-- 6. ZERO-DOWNTIME DATA LIFECYCLE MANAGEMENT (ATTACH / DETACH)
-- ============================================================================
-- Scenario: Q3 2025 is now over 6 months old and needs to be archived to cold storage.

-- Step 1: Detach the partition concurrently without blocking active read/write traffic
ALTER TABLE shopease.orders_partitioned 
    DETACH PARTITION shopease.orders_2025_q3 CONCURRENTLY;

-- `orders_2025_q3` is now a standalone table!
-- Step 2: It can be exported to AWS S3 / Parquet, compressed, or dropped at leisure:
-- COMMENT ON TABLE shopease.orders_2025_q3 IS 'Archived to S3 glacier storage';
-- DROP TABLE shopease.orders_2025_q3;

-- Step 3: Preparing for future Q3 2026 by attaching a new pre-created partition:
CREATE TABLE shopease.orders_2026_q3 (
    LIKE shopease.orders_partitioned INCLUDING ALL
);

ALTER TABLE shopease.orders_partitioned 
    ATTACH PARTITION shopease.orders_2026_q3
    FOR VALUES FROM ('2026-07-01 00:00:00') TO ('2026-10-01 00:00:00');
