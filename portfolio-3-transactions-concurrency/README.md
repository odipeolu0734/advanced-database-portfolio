# Portfolio 3: Transactions and Concurrency Control

## ShopEase E-commerce Platform — Transaction Management & Concurrency

---

## Table of Contents

1. [Introduction](#introduction)
2. [Transaction Fundamentals](#transaction-fundamentals)
3. [ACID Properties in E-commerce Context](#acid-properties-in-e-commerce-context)
4. [Concurrency Issues](#concurrency-issues)
5. [Isolation Levels](#isolation-levels)
6. [Locking Mechanisms](#locking-mechanisms)
7. [Deadlock Detection and Resolution](#deadlock-detection-and-resolution)
8. [Best Practices for ShopEase](#best-practices-for-shopease)
9. [File Manifest](#file-manifest)
10. [References](#references)

---

## 1. Introduction

In any multi-user e-commerce platform such as ShopEase, **transactions** and **concurrency control** are the foundational pillars that guarantee data correctness, consistency, and reliability. ShopEase processes thousands of concurrent operations — customers placing orders, making payments, updating carts, managing inventory, and processing returns — all of which must execute correctly even when they overlap in time.

This portfolio explores how PostgreSQL's transaction and concurrency mechanisms safeguard ShopEase's data integrity. We examine real-world scenarios drawn from the platform's operations — from the critical multi-step order placement workflow to the subtle race conditions that arise when two customers attempt to purchase the last unit of a product simultaneously.

---

## 2. Transaction Fundamentals

### What Is a Transaction?

A **transaction** is a logical unit of work comprising one or more SQL operations that must be treated as an indivisible whole. In PostgreSQL, a transaction begins with `BEGIN` and concludes with either `COMMIT` (making all changes permanent) or `ROLLBACK` (discarding all changes).

```sql
BEGIN;
    -- Multiple operations here form a single atomic unit
    UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 101;
    INSERT INTO order_items (...) VALUES (...);
COMMIT;
```

### Why Transactions Matter in E-commerce

Consider a customer placing an order on ShopEase. This single "business event" involves:

1. Verifying that sufficient inventory exists
2. Creating the order record
3. Creating individual order item records
4. Deducting inventory quantities
5. Processing the payment
6. Creating a shipping record

If step 4 succeeds but step 5 fails (e.g., payment declined), the system must **undo all preceding changes**. Without transactions, we would have reduced inventory for an order that was never paid — a data integrity catastrophe.

### Transaction Control Statements in PostgreSQL

| Statement | Purpose |
|-----------|---------|
| `BEGIN` / `START TRANSACTION` | Starts a new transaction block |
| `COMMIT` | Makes all changes since BEGIN permanent |
| `ROLLBACK` | Discards all changes since BEGIN |
| `SAVEPOINT name` | Creates a named rollback point within a transaction |
| `ROLLBACK TO SAVEPOINT name` | Rolls back to a savepoint without aborting the entire transaction |
| `RELEASE SAVEPOINT name` | Destroys a savepoint (frees resources) |
| `SET TRANSACTION ISOLATION LEVEL ...` | Sets the isolation level for the current transaction |

### PL/pgSQL Exception Handling

PostgreSQL supports structured exception handling within `DO` blocks and stored functions:

```sql
DO $$
BEGIN
    -- transactional work
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Duplicate entry detected';
    WHEN check_violation THEN
        RAISE NOTICE 'Constraint violation';
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END;
$$;
```

---

## 3. ACID Properties in E-commerce Context

The **ACID** properties define the guarantees that a database transaction must provide. Each property is critical to ShopEase's operations.

### Atomicity — "All or Nothing"

**Definition:** A transaction is an indivisible unit; either all of its operations succeed, or none of them take effect.

**ShopEase Example — Order Placement:**
When a customer places an order, the system must create the order record, add line items, deduct inventory, process payment, and create a shipping record. If the payment gateway returns a failure after inventory has already been deducted, atomicity guarantees that the inventory deduction is rolled back. The database is left exactly as it was before the order attempt.

**Implementation:** PostgreSQL enforces atomicity through its Write-Ahead Log (WAL). All changes are written to the WAL before being applied to data pages. On `ROLLBACK`, the WAL entries guide the undo process.

### Consistency — "Valid State to Valid State"

**Definition:** A transaction transforms the database from one valid state to another. All integrity constraints (primary keys, foreign keys, CHECK constraints, triggers) must be satisfied at the end of the transaction.

**ShopEase Example — Inventory Constraints:**
A CHECK constraint ensures `inventory.quantity >= 0`. If a transaction attempts to deduct more units than available, the constraint violation causes the transaction to abort, preserving data validity. The database never enters a state where inventory is negative.

**Implementation:** PostgreSQL evaluates constraints at different points depending on their deferral setting — `IMMEDIATE` constraints are checked after each statement; `DEFERRED` constraints are checked at `COMMIT` time.

### Isolation — "Concurrent Transactions Don't Interfere"

**Definition:** Even when multiple transactions execute concurrently, each transaction must behave as though it were the only one running. The degree of isolation is configurable via isolation levels.

**ShopEase Example — Last-Item Purchase:**
Two customers simultaneously attempt to buy the last unit of a popular product. Without proper isolation, both might read `quantity = 1`, both deduct 1, leaving `quantity = -1`. With proper isolation (e.g., `SELECT FOR UPDATE`), the second transaction waits until the first completes, then sees `quantity = 0` and correctly reports "out of stock."

**Implementation:** PostgreSQL uses Multi-Version Concurrency Control (MVCC) as its primary isolation mechanism, supplemented by explicit locking when needed.

### Durability — "Committed Data Survives Failures"

**Definition:** Once a transaction has been committed, its effects are permanent, even in the event of power failure, crash, or hardware malfunction.

**ShopEase Example — Payment Confirmation:**
After a customer receives an "Order Confirmed" message, the payment record must persist even if the database server crashes moments later. Durability ensures that the `payments` table retains the record after recovery.

**Implementation:** PostgreSQL achieves durability by writing WAL records to persistent storage before returning `COMMIT` success to the client. The `synchronous_commit` setting controls the trade-off between durability guarantees and commit latency.

---

## 4. Concurrency Issues

When multiple transactions execute simultaneously, several anomalies can arise if not properly managed.

### 4.1 Dirty Read

**Definition:** A transaction reads data that has been modified by another transaction but not yet committed. If the other transaction rolls back, the first transaction has acted on data that never officially existed.

**ShopEase Scenario:**
- Session A begins updating a product price from £49.99 to £39.99 (promotional sale).
- Before Session A commits, Session B reads the product price as £39.99 and calculates an order total.
- Session A rolls back (the promotion was entered in error).
- Session B has now used a price that was never valid.

**PostgreSQL Note:** PostgreSQL's minimum isolation level is `READ COMMITTED`, which inherently prevents dirty reads. The `READ UNCOMMITTED` level in PostgreSQL behaves identically to `READ COMMITTED` — dirty reads are **never** possible.

### 4.2 Non-Repeatable Read

**Definition:** A transaction reads the same row twice and sees different data each time because another committed transaction modified the row between the two reads.

**ShopEase Scenario:**
- Session A reads a product price as £49.99 for a discount calculation.
- Session B updates the price to £59.99 and commits.
- Session A reads the same price again and now sees £59.99.
- Session A's discount calculation is inconsistent — it used two different prices.

**Prevention:** Use `REPEATABLE READ` isolation level, which gives each transaction a consistent snapshot of the database as it existed at the start of the transaction.

### 4.3 Phantom Read

**Definition:** A transaction re-executes a query returning a set of rows and finds that the set has changed because another committed transaction inserted or deleted rows matching the query's predicate.

**ShopEase Scenario:**
- Session A counts the number of orders placed today: `SELECT COUNT(*) FROM orders WHERE order_date = CURRENT_DATE` → returns 150.
- Session B inserts a new order and commits.
- Session A re-runs the same count → returns 151.
- Session A's report is internally inconsistent.

**Prevention:** Use `SERIALIZABLE` isolation level, which guarantees that the result is equivalent to running transactions one at a time.

### 4.4 Lost Update

**Definition:** Two transactions both read the same value, compute a new value based on it, and write it back. One of the updates is lost because it is overwritten by the other.

**ShopEase Scenario:**
- Session A reads inventory quantity = 10 for product 101.
- Session B reads inventory quantity = 10 for product 101.
- Session A writes quantity = 10 - 3 = 7.
- Session B writes quantity = 10 - 2 = 8 (overwriting A's update).
- Net result: quantity = 8 instead of the correct 5. Three units are "lost."

**Prevention:** Use pessimistic locking (`SELECT ... FOR UPDATE`) to lock the row when first reading, blocking other transactions until the lock is released.

### 4.5 Deadlock

**Definition:** Two or more transactions permanently block each other, each holding a lock that the other needs and waiting for the other to release it.

**ShopEase Scenario:**
- Session A locks product 101's inventory row, then tries to lock product 102.
- Session B locks product 102's inventory row, then tries to lock product 101.
- Both sessions wait indefinitely for the other to release its lock.

**Resolution:** PostgreSQL automatically detects deadlocks (using a wait-for graph with a configurable `deadlock_timeout`, default 1 second) and aborts one of the transactions with an error. The application should retry the aborted transaction.

**Prevention Strategy:** Always acquire locks in a consistent, deterministic order (e.g., by ascending `product_id`).

---

## 5. Isolation Levels

PostgreSQL supports three effective isolation levels (READ UNCOMMITTED behaves as READ COMMITTED):

| Level | Dirty Read | Non-Repeatable Read | Phantom Read | Use Case |
|-------|-----------|---------------------|--------------|----------|
| READ COMMITTED | ✗ Prevented | ✓ Possible | ✓ Possible | Default; suitable for most operations |
| REPEATABLE READ | ✗ Prevented | ✗ Prevented | ✗ Prevented* | Financial calculations, report generation |
| SERIALIZABLE | ✗ Prevented | ✗ Prevented | ✗ Prevented | Critical financial transactions, audit trails |

*\*PostgreSQL's REPEATABLE READ implementation using MVCC snapshots also prevents phantom reads in practice, exceeding the SQL standard's requirements.*

> **See:** [isolation-levels.md](./isolation-levels.md) for a comprehensive analysis with ShopEase-specific examples and performance trade-offs.

---

## 6. Locking Mechanisms

### MVCC (Multi-Version Concurrency Control)

PostgreSQL's primary concurrency mechanism. Rather than locking rows for reading, PostgreSQL maintains multiple versions of each row. Readers see a consistent snapshot and are never blocked by writers; writers are never blocked by readers.

**Key concepts:**
- Each transaction receives an **xid** (transaction ID) at start.
- Each row version carries `xmin` (creating transaction) and `xmax` (deleting/updating transaction) metadata.
- A row version is visible to a transaction if `xmin` is committed and before the snapshot, and `xmax` is either empty or not yet committed/visible.

### Explicit Locking

| Lock Type | SQL | Purpose |
|-----------|-----|---------|
| Row-level exclusive | `SELECT ... FOR UPDATE` | Prevents other transactions from modifying or locking the selected rows |
| Row-level share | `SELECT ... FOR SHARE` | Prevents other transactions from modifying (but not reading) the selected rows |
| Row-level skip | `SELECT ... FOR UPDATE SKIP LOCKED` | Skips already-locked rows (useful for job queues) |
| Row-level no wait | `SELECT ... FOR UPDATE NOWAIT` | Fails immediately if the row is already locked |
| Table-level | `LOCK TABLE ... IN mode MODE` | Various table-level lock modes (ACCESS SHARE through ACCESS EXCLUSIVE) |
| Advisory | `pg_advisory_lock(key)` | Application-level cooperative locks |

### ShopEase Locking Strategy

For inventory management, ShopEase uses `SELECT ... FOR UPDATE` to lock inventory rows during order placement:

```sql
SELECT quantity FROM shopease.inventory
WHERE product_id = 101
FOR UPDATE;  -- Row is now locked until COMMIT/ROLLBACK
```

This ensures that concurrent orders for the same product are serialised at the inventory check step, preventing overselling.

---

## 7. Deadlock Detection and Resolution

### PostgreSQL's Deadlock Detector

PostgreSQL runs a background deadlock detector that:
1. Waits for `deadlock_timeout` (default: 1 second) after a lock wait begins.
2. Constructs a wait-for graph of all waiting transactions.
3. If a cycle is detected, aborts the youngest transaction in the cycle.
4. Logs the deadlock details to the server log.

### Application-Level Prevention

```
Strategy 1: Consistent Lock Ordering
    Always lock resources in the same order (e.g., by ascending primary key).

Strategy 2: Lock Timeout
    SET lock_timeout = '5s';  -- Fail fast instead of waiting indefinitely

Strategy 3: Reduce Transaction Duration
    Keep transactions as short as possible. Do not hold locks across user
    interactions or external API calls.

Strategy 4: Use NOWAIT or SKIP LOCKED
    SELECT ... FOR UPDATE NOWAIT;       -- Fail immediately
    SELECT ... FOR UPDATE SKIP LOCKED;  -- Skip locked rows
```

---

## 8. Best Practices for ShopEase

### Transaction Design Principles

1. **Keep transactions short** — Long transactions hold locks, increase contention, and bloat MVCC storage (dead tuples require vacuuming).

2. **Use the lowest sufficient isolation level** — `READ COMMITTED` (the default) is adequate for most ShopEase operations. Reserve `REPEATABLE READ` for financial reporting and `SERIALIZABLE` for critical monetary operations.

3. **Handle errors and retry** — Always implement retry logic for serialisation failures (`SQLSTATE 40001`) and deadlock aborts (`SQLSTATE 40P01`).

4. **Use SAVEPOINTs judiciously** — SAVEPOINTs allow partial rollback within a transaction, useful for "best-effort" operations (e.g., applying a coupon that might fail without aborting the entire order).

5. **Lock in consistent order** — When multiple rows or tables must be locked, always acquire locks in the same deterministic order across all code paths.

6. **Prefer optimistic over pessimistic locking** for low-contention scenarios — Use version columns or MVCC-based checks rather than `FOR UPDATE` when conflicts are rare.

7. **Monitor and tune** — Use `pg_stat_activity`, `pg_locks`, and `log_lock_waits = on` to identify contention hotspots.

### ShopEase-Specific Recommendations

| Operation | Isolation Level | Locking Strategy |
|-----------|----------------|------------------|
| Browse products | READ COMMITTED | None (read-only) |
| Add to cart | READ COMMITTED | None (cart is per-user) |
| Place order | READ COMMITTED | `SELECT FOR UPDATE` on inventory rows |
| Process payment | READ COMMITTED | Row lock on order + payment |
| Generate daily sales report | REPEATABLE READ | Consistent snapshot |
| End-of-day reconciliation | SERIALIZABLE | Full serialisation guarantee |
| Batch inventory update | READ COMMITTED | `SELECT FOR UPDATE` per product, ordered by product_id |
| Return/refund processing | READ COMMITTED | Row locks on order, payment, inventory |

---

## 9. File Manifest

| File | Description |
|------|-------------|
| [README.md](./README.md) | This document — overview and concepts |
| [transactions.sql](./transactions.sql) | Transaction scripts: order placement, refund, batch update, account ops, savepoints |
| [concurrency-control.sql](./concurrency-control.sql) | Concurrency scenarios: dirty read, non-repeatable read, phantom read, lost update, deadlock |
| [isolation-levels.md](./isolation-levels.md) | Detailed isolation level comparison with ShopEase examples |
| [concurrency-output.md](./concurrency-output.md) | Simulated terminal output from concurrency scenarios |

---

## 10. References

1. PostgreSQL Documentation — [Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
2. PostgreSQL Documentation — [Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
3. PostgreSQL Documentation — [MVCC Introduction](https://www.postgresql.org/docs/current/mvcc-intro.html)
4. Berenson, H., et al. (1995). *A Critique of ANSI SQL Isolation Levels*. ACM SIGMOD Record.
5. Kleppmann, M. (2017). *Designing Data-Intensive Applications*. O'Reilly Media. Chapters 7 (Transactions).
6. Ramakrishnan, R. & Gehrke, J. (2003). *Database Management Systems* (3rd ed.). McGraw-Hill. Chapter 16 (Concurrency Control).
7. PostgreSQL Documentation — [Deadlocks](https://www.postgresql.org/docs/current/explicit-locking.html#LOCKING-DEADLOCKS)
