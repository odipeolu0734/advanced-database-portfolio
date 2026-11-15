# Portfolio 4: Column-Family Data Model Implementation (Apache Cassandra)

**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** ShopEase E-Commerce Platform  
**Technology:** Apache Cassandra 4.1+ (Cassandra Query Language - CQL)  
**Component:** High-Throughput Time-Series, Clickstream Telemetry, and Order Archival  

---

## 1. Architectural Role of Wide-Column Stores in ShopEase

Relational databases like PostgreSQL encounter severe disk I/O bottlenecks when ingesting continuous, append-only streams of telemetry—such as user clickstreams, package sensor telemetry, and historical audit events. 

**Apache Cassandra** employs a **Log-Structured Merge-Tree (LSM)** storage architecture:
1. All incoming writes are written sequentially to an on-disk **CommitLog** (for crash durability).
2. The mutation is immediately placed in an in-memory sorted buffer called a **Memtable**.
3. Once the Memtable reaches capacity, it flushes to disk as an immutable **SSTable** (Sorted String Table).
4. **No in-place disk overwrites or read-before-write penalties occur**, enabling millions of sustained writes per second across masterless clusters.

---

## 2. Query-First Data Modeling in CQL

In relational design, schemas are normalized around entities regardless of queries. In Cassandra, **data modeling is strictly query-first**:
- There are **no joins** and **no subqueries**.
- Data is intentionally denormalized into dedicated tables structured specifically to answer one specific query pattern.
- The **Partition Key** determines which node in the distributed ring stores the data (via consistent hashing with Murmur3Partitioner).
- The **Clustering Columns** dictate the physical sorting order of rows within that partition on disk.

---

## 3. CQL Physical Schema & Implementation

```sql
-- Create Keyspace with NetworkTopologyStrategy for multi-datacenter replication
CREATE KEYSPACE IF NOT EXISTS shopease_telemetry
WITH replication = {
    'class': 'NetworkTopologyStrategy',
    'eu-west-1': 3,
    'us-east-1': 3
} AND durable_writes = true;

USE shopease_telemetry;

-- ============================================================================
-- TABLE 1: CUSTOMER CLICKSTREAM & USER ENGAGEMENT LOGS
-- ============================================================================
-- Query Requirement: "Fetch all user interactions for Customer C on Date D,
--                     ordered chronologically in reverse (most recent first)."
--
-- Partition Key: (customer_id, event_date) -> Keeps one user's daily activity on one node.
-- Clustering Column: event_timestamp DESC   -> Physically stored sorted descending.
-- ============================================================================

CREATE TABLE IF NOT EXISTS customer_clickstream (
    customer_id         bigint,
    event_date          date,
    event_timestamp     timestamp,
    event_id            uuid,
    session_id          text,
    event_type          text, -- 'page_view', 'product_hover', 'add_to_cart', 'filter_click'
    page_url            text,
    sku_interacted      text,
    device_type         text,
    ip_address          text,
    PRIMARY KEY ((customer_id, event_date), event_timestamp, event_id)
) WITH CLUSTERING ORDER BY (event_timestamp DESC, event_id ASC)
  AND default_time_to_live = 2592000 -- Auto-purge telemetry after 30 days (TTL)
  AND compaction = {'class': 'TimeWindowCompactionStrategy', 'compaction_window_unit': 'DAYS', 'compaction_window_size': 1};

-- ============================================================================
-- TABLE 2: SHIPMENT GPS TRACKING & TELEMETRY
-- ============================================================================
-- Query Requirement: "Retrieve full GPS waypoint trail for Tracking Number T,
--                     ordered chronologically."
-- ============================================================================

CREATE TABLE IF NOT EXISTS shipment_transit_telemetry (
    tracking_number     text,
    checkpoint_time     timestamp,
    latitude            double,
    longitude           double,
    city                text,
    carrier_facility    text,
    status_code         text,
    carrier_comments    text,
    PRIMARY KEY ((tracking_number), checkpoint_time)
) WITH CLUSTERING ORDER BY (checkpoint_time ASC);

-- ============================================================================
-- TABLE 3: HISTORICAL ORDER ARCHIVAL (TEN-YEAR AUDIT TRAIL)
-- ============================================================================
-- Query Requirement: "Retrieve all archived orders for Customer C sorted by order date."
-- ============================================================================

CREATE TABLE IF NOT EXISTS customer_orders_archive (
    customer_id         bigint,
    order_id            bigint,
    order_timestamp     timestamp,
    total_amount        decimal,
    order_status        text,
    payment_method      text,
    item_count          int,
    order_summary_json  text,
    PRIMARY KEY ((customer_id), order_timestamp, order_id)
) WITH CLUSTERING ORDER BY (order_timestamp DESC, order_id ASC);
```

---

## 4. Data Ingestion & Query Execution

### 4.1 Ingesting Clickstream Events
```sql
INSERT INTO customer_clickstream (
    customer_id, event_date, event_timestamp, event_id, session_id,
    event_type, page_url, sku_interacted, device_type, ip_address
) VALUES (
    101, '2026-03-15', '2026-03-15 14:22:10.124Z', uuid(), 'sess_99182',
    'page_view', 'https://shopease.co.uk/products/LAP-APL-MBP16', 'LAP-APL-MBP16', 'Desktop Chrome', '82.165.197.1'
);

INSERT INTO customer_clickstream (
    customer_id, event_date, event_timestamp, event_id, session_id,
    event_type, page_url, sku_interacted, device_type, ip_address
) VALUES (
    101, '2026-03-15', '2026-03-15 14:23:45.890Z', uuid(), 'sess_99182',
    'add_to_cart', 'https://shopease.co.uk/cart', 'LAP-APL-MBP16', 'Desktop Chrome', '82.165.197.1'
);
```

### 4.2 Querying Chronological User Activity
```sql
-- Retrieves the user's latest interactions for March 15, 2026 without any table scan
SELECT event_timestamp, event_type, sku_interacted, page_url
FROM customer_clickstream
WHERE customer_id = 101 AND event_date = '2026-03-15';
```
**Execution Analysis:**
- Cassandra routes this query directly to the replica nodes holding the hash partition `(101, '2026-03-15')`.
- The data is already physically stored on disk in descending order by `event_timestamp`.
- Disk access is a single sequential read across the SSTable block, returning in **under 2 milliseconds**.

---

## 5. Tunable Consistency Levels in CQL

Unlike relational databases with static ACID guarantees, Cassandra provides **Tunable Consistency** per read and write request:

$$\text{Strong Consistency Condition: } R + W > N$$

Where:
- $N$ = Replication Factor (e.g., 3 nodes per datacenter).
- $W$ = Number of replicas that must acknowledge a write.
- $R$ = Number of replicas that must respond to a read.

```sql
-- 1. High-throughput clickstream write (maximum speed, tolerable loss)
CONSISTENCY ONE;
INSERT INTO customer_clickstream (...) VALUES (...);

-- 2. Financial order archival write (strong multi-datacenter guarantee)
CONSISTENCY LOCAL_QUORUM;
INSERT INTO customer_orders_archive (...) VALUES (...);

-- 3. Verifiable read matching strong consistency (LOCAL_QUORUM read + LOCAL_QUORUM write = 2 + 2 = 4 > 3)
CONSISTENCY LOCAL_QUORUM;
SELECT * FROM customer_orders_archive WHERE customer_id = 101;
```
