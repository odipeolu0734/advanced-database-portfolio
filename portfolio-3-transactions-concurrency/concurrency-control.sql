-- ============================================================================
-- ShopEase E-Commerce Platform — Concurrency Control & Isolation Scenarios
-- ============================================================================
-- Course      : MIT 8103 Advanced Database Systems
-- Session     : 2026/2027 Academic Session
-- Target RDBMS: PostgreSQL 15+
-- Schema      : shopease
-- Author      : Portfolio 3 — Transactions and Concurrency
-- Description : Step-by-step SQL reproduction of concurrent transactional anomalies
--               and their architectural resolutions using explicit locking,
--               isolation levels, and deadlock avoidance.
-- ============================================================================

SET search_path TO shopease;

-- ============================================================================
-- SCENARIO 1: DIRTY READ ANOMALY (AND POSTGRESQL'S NATIVE PREVENTION)
-- ============================================================================
-- Context: Dirty Read occurs when Transaction B reads uncommitted modifications
-- made by Transaction A. If Transaction A rolls back, Transaction B has acted
-- on "phantom" dirty data.
--
-- ANSI SQL allows Dirty Reads under READ UNCOMMITTED.
-- NOTE: In PostgreSQL, READ UNCOMMITTED is treated internally as READ COMMITTED.
-- Therefore, PostgreSQL NEVER permits dirty reads by default.
-- ============================================================================

-- SESSION A (Seller updates product price during a flash sale, but encounters error)
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- treated as READ COMMITTED in Postgres
UPDATE shopease.products 
SET price = 19.99 
WHERE product_id = 1; -- Originally 89.99

-- (Session A has NOT committed yet)

-- SESSION B (Customer checks product price concurrently)
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- In PostgreSQL, Session B will STILL see price = 89.99 (MVCC snapshot protection)
SELECT product_id, product_name, price 
FROM shopease.products 
WHERE product_id = 1;

-- SESSION A (Flash sale update fails validation and aborts)
ROLLBACK;

-- SESSION B (Customer commits read session)
COMMIT;


-- ============================================================================
-- SCENARIO 2: NON-REPEATABLE READ ANOMALY & REPEATABLE READ ISOLATION
-- ============================================================================
-- Context: Transaction A reads a row. Transaction B modifies and COMMITS that row.
-- When Transaction A re-reads the row, it observes the new value within the
-- same transaction.
-- Resolution: Set Isolation Level to REPEATABLE READ.
-- ============================================================================

-- --- REPRODUCTION UNDER DEFAULT READ COMMITTED ---

-- Step 1 (Session A: Customer audits stock before checkout)
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT quantity_in_stock FROM shopease.inventory WHERE product_id = 2; -- Returns 15

-- Step 2 (Session B: Another customer orders 5 units and commits)
BEGIN;
UPDATE shopease.inventory 
SET quantity_in_stock = quantity_in_stock - 5 
WHERE product_id = 2;
COMMIT;

-- Step 3 (Session A: Customer re-checks stock in same transaction)
SELECT quantity_in_stock FROM shopease.inventory WHERE product_id = 2; -- Returns 10 (Non-repeatable read!)
COMMIT;

-- --- RESOLUTION UNDER REPEATABLE READ ---

-- Step 1 (Session A: Transaction pinned to snapshot at start)
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT quantity_in_stock FROM shopease.inventory WHERE product_id = 2; -- Returns 10

-- Step 2 (Session B: Stock adjustment commits)
BEGIN;
UPDATE shopease.inventory 
SET quantity_in_stock = quantity_in_stock - 2 
WHERE product_id = 2;
COMMIT;

-- Step 3 (Session A: Re-evaluates stock)
-- In REPEATABLE READ, Session A continues to see 10, preserving snapshot isolation!
SELECT quantity_in_stock FROM shopease.inventory WHERE product_id = 2; -- Returns 10
COMMIT;


-- ============================================================================
-- SCENARIO 3: PHANTOM READ ANOMALY & SERIALIZABLE ISOLATION
-- ============================================================================
-- Context: Transaction A queries a range of rows matching a predicate.
-- Transaction B inserts a new row matching that predicate and commits.
-- When Transaction A re-executes the range query, new "phantom" rows appear.
-- Resolution: Set Isolation Level to SERIALIZABLE (SSI - Serializable Snapshot Isolation).
-- ============================================================================

-- Step 1 (Session A: Generates an inventory audit of luxury products > £500)
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT count(*), sum(price) 
FROM shopease.products 
WHERE price >= 500.00;

-- Step 2 (Session B: Vendor adds a new high-end designer watch)
BEGIN;
INSERT INTO shopease.products (seller_id, category_id, product_name, price, sku, status)
VALUES (1, 1, 'Luxury Gold Chronograph Watch', 1250.00, 'WCH-GLD-001', 'active');
COMMIT;

-- Step 3 (Session A: Re-executes audit or attempts update based on initial snapshot)
-- PostgreSQL SSI uses SIREAD locks to detect predicate read-write conflicts.
-- If Session A attempts a state transition conflicting with Session B's insert:
UPDATE shopease.products 
SET discount_percentage = 10.00 
WHERE price >= 500.00;
-- Session A COMMIT will raise ERROR: 40001: could not serialize access due to read/write dependencies among transactions
COMMIT;


-- ============================================================================
-- SCENARIO 4: THE LOST UPDATE PROBLEM & EXPLICIT PESSIMISTIC LOCKING
-- ============================================================================
-- Context: Two concurrent transactions read the same inventory row (e.g. 5 units).
-- Both calculate a decrement in application memory. Both write back.
-- The last write overwrites the first write, losing one order's deduction.
--
-- Solution: SELECT ... FOR UPDATE (Row-level exclusive lock).
-- ============================================================================

-- --- THE BUGGY PATTERN (Lost Update Risk in application layer) ---
-- User 1: SELECT quantity_in_stock FROM inventory WHERE product_id = 5; (reads 10)
-- User 2: SELECT quantity_in_stock FROM inventory WHERE product_id = 5; (reads 10)
-- User 1: UPDATE inventory SET quantity_in_stock = 9 WHERE product_id = 5;
-- User 2: UPDATE inventory SET quantity_in_stock = 9 WHERE product_id = 5; -- 2 items sold, but stock decremented by only 1!

-- --- THE PRODUCTION-GRADE SOLUTION (Pessimistic Locking) ---

-- Customer 1 Checkout Worker (Session A):
BEGIN;
-- Acquires an Exclusive Row Lock (FOR UPDATE)
SELECT inventory_id, quantity_in_stock 
FROM shopease.inventory 
WHERE product_id = 5 
FOR UPDATE;

-- While Customer 1 holds the lock, Customer 2 attempts checkout (Session B):
-- BEGIN;
-- SELECT inventory_id, quantity_in_stock FROM shopease.inventory WHERE product_id = 5 FOR UPDATE;
-- --> Session B BLOCKS and waits for Session A to finish!

-- Session A safely verifies stock and applies deduction:
UPDATE shopease.inventory 
SET quantity_in_stock = quantity_in_stock - 1,
    last_restocked = CURRENT_TIMESTAMP
WHERE product_id = 5;

COMMIT; -- Lock released! Session B immediately unblocks and sees updated quantity_in_stock = 9.


-- ============================================================================
-- SCENARIO 5: DEADLOCK REPRODUCTION & ARCHITECTURAL AVOIDANCE
-- ============================================================================
-- Context: Deadlock happens when Transaction 1 holds Lock A and waits for Lock B,
-- while Transaction 2 holds Lock B and waits for Lock A.
-- PostgreSQL detects deadlocks automatically via `deadlock_timeout` (default 1s)
-- and aborts one transaction with SQLSTATE 40P01.
-- ============================================================================

-- --- DEADLOCK REPRODUCTION ---

-- SESSION 1 (Customer placing multi-item order: Product 10 then Product 20)
BEGIN;
UPDATE shopease.inventory 
SET quantity_in_stock = quantity_in_stock - 1 
WHERE product_id = 10;
-- Session 1 now holds exclusive lock on row (product_id = 10)

-- SESSION 2 (Simultaneously, warehouse transfer modifies Product 20 then Product 10)
BEGIN;
UPDATE shopease.inventory 
SET quantity_in_stock = quantity_in_stock + 5 
WHERE product_id = 20;
-- Session 2 now holds exclusive lock on row (product_id = 20)

-- SESSION 1 (Attempts to lock Product 20)
UPDATE shopease.inventory 
SET quantity_in_stock = quantity_in_stock - 1 
WHERE product_id = 20;
-- Session 1 BLOCKS waiting for Session 2...

-- SESSION 2 (Attempts to lock Product 10)
UPDATE shopease.inventory 
SET quantity_in_stock = quantity_in_stock - 5 
WHERE product_id = 10;
-- DEADLOCK DETECTED!
-- PostgreSQL Output:
-- ERROR:  deadlock detected
-- DETAIL: Process 4128 waits for ShareLock on transaction; blocked by process 4129.
-- Process 4129 waits for ExclusiveLock on tuple; blocked by process 4128.
-- HINT:   See server log for query details.

-- --- ARCHITECTURAL SOLUTION: STRICT RESOURCE LOCK ORDERING ---
-- Rule: Always sort resource IDs numerically before acquiring row locks!

-- Session 1 & Session 2 both sort target IDs: [10, 20]
-- Session 1: Locks 10, then locks 20.
-- Session 2: Requests 10 first. Since Session 1 holds 10, Session 2 waits cleanly
-- BEFORE touching 20. Deadlock is mathematically impossible!
