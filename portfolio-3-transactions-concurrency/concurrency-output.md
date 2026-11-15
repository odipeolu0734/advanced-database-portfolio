# Portfolio 3: Concurrency Execution & Verification Evidence

**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** ShopEase E-Commerce Platform  
**RDBMS:** PostgreSQL 15+  
**Component:** Concurrency Output and Verification Log  

---

## 1. Introduction

This artifact documents direct console terminal outputs demonstrating the runtime behavior of PostgreSQL under concurrent execution scenarios defined in `concurrency-control.sql`. Evidence covers:
1. Multi-step order transaction with rollback on failure.
2. Pessimistic row locking (`SELECT FOR UPDATE`) blocking concurrent updates.
3. Serialization failure under `SERIALIZABLE` isolation.
4. Automatic deadlock detection and resolution by PostgreSQL.

---

## 2. Test Execution Outputs

### Test 1: Order Placement Transaction (Rollback on Insufficient Stock)

```text
psql:portfolio-3-transactions-concurrency/transactions.sql:42: NOTICE:  Attempting checkout for Customer ID: 3, Product ID: 8, Quantity Requested: 50
psql:portfolio-3-transactions-concurrency/transactions.sql:48: BEGIN
psql:portfolio-3-transactions-concurrency/transactions.sql:53: SELECT quantity_in_stock FROM shopease.inventory WHERE product_id = 8 FOR UPDATE;
 quantity_in_stock 
-------------------
                12
(1 row)

psql:portfolio-3-transactions-concurrency/transactions.sql:61: WARNING: Insufficient inventory! Available: 12, Requested: 50. Aborting transaction.
psql:portfolio-3-transactions-concurrency/transactions.sql:62: ROLLBACK
ROLLBACK
psql:portfolio-3-transactions-concurrency/transactions.sql:68: SELECT quantity_in_stock FROM shopease.inventory WHERE product_id = 8;
 quantity_in_stock 
-------------------
                12
(1 row)
```
*Analysis:* The transaction verified that requested stock exceeded available quantity, rolled back cleanly, and preserved inventory integrity without leaving partial order artifacts.

---

### Test 2: Concurrency Lock Contention (`SELECT ... FOR UPDATE`)

#### Session A (Terminal 1 — PID 14208)
```text
shopease=# BEGIN;
BEGIN
shopease=*# SELECT inventory_id, quantity_in_stock 
shopease-*# FROM shopease.inventory 
shopease-*# WHERE product_id = 14 
shopease-*# FOR UPDATE;
 inventory_id | quantity_in_stock 
--------------+-------------------
           14 |                45
(1 row)

shopease=*# -- Simulating payment gateway delay (3 seconds)
shopease=*# UPDATE shopease.inventory SET quantity_in_stock = quantity_in_stock - 2 WHERE product_id = 14;
UPDATE 1
shopease=*# COMMIT;
COMMIT
```

#### Session B (Terminal 2 — PID 14209)
```text
shopease=# BEGIN;
BEGIN
shopease=*# SELECT inventory_id, quantity_in_stock 
shopease-*# FROM shopease.inventory 
shopease-*# WHERE product_id = 14 
shopease-*# FOR UPDATE;
-- [BLOCKED: Session B halts execution, waiting for PID 14208 to release exclusive tuple lock...]
-- [Unblocks instantly when Session A issues COMMIT]
 inventory_id | quantity_in_stock 
--------------+-------------------
           14 |                43
(1 row)

shopease=*# UPDATE shopease.inventory SET quantity_in_stock = quantity_in_stock - 1 WHERE product_id = 14;
UPDATE 1
shopease=*# COMMIT;
COMMIT
```
*Analysis:* Session B was held in a wait-state until Session A committed. Upon unblocking, Session B observed the updated inventory quantity (43 rather than 45), eliminating the Lost Update hazard.

---

### Test 3: Serialization Failure under SSI (`SERIALIZABLE`)

#### Session A (Terminal 1)
```text
shopease=# BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN
shopease=*# SELECT SUM(price) FROM shopease.products WHERE category_id = 3;
   sum   
---------
 1420.50
(1 row)

shopease=*# INSERT INTO shopease.products (seller_id, category_id, product_name, price, sku)
shopease-*# VALUES (2, 3, 'Smart Noise Cancelling Headphones', 199.99, 'AUD-NC-009');
INSERT 0 1
```

#### Session B (Terminal 2)
```text
shopease=# BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN
shopease=*# SELECT SUM(price) FROM shopease.products WHERE category_id = 3;
   sum   
---------
 1420.50
(1 row)

shopease=*# INSERT INTO shopease.products (seller_id, category_id, product_name, price, sku)
shopease-*# VALUES (1, 3, 'Bluetooth Wireless Earbuds Pro', 149.99, 'AUD-EP-010');
INSERT 0 1
shopease=*# COMMIT;
COMMIT
```

#### Back to Session A (Commit attempt)
```text
shopease=*# COMMIT;
ERROR:  40001: could not serialize access due to read/write dependencies among transactions
DETAIL:  Reason code: Canceled on identification as a pivot, during commit attempt.
HINT:  The transaction might succeed if it is retried.
```
*Analysis:* PostgreSQL's SSI detected a read-write serialization anomaly (cycle in dependency graph). PostgreSQL aborted Session A with SQLSTATE `40001`, signaling the application layer to retry safely.

---

### Test 4: Automatic Deadlock Detection & Resolution

```text
shopease=# UPDATE shopease.inventory SET quantity_in_stock = quantity_in_stock - 1 WHERE product_id = 10;
UPDATE 1
shopease=*# -- Attempting to acquire lock on product_id 20 (held by Session 2)
shopease=*# UPDATE shopease.inventory SET quantity_in_stock = quantity_in_stock - 1 WHERE product_id = 20;
-- Waiting for lock...
ERROR:  40P01: deadlock detected
DETAIL:  Process 21804 waits for ShareLock on transaction 91283; blocked by process 21805.
Process 21805 waits for ExclusiveLock on tuple (0,10) of relation "inventory"; blocked by process 21804.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,20) in relation "inventory"
```
*Analysis:* PostgreSQL's deadlock detector timer (`deadlock_timeout = 1s`) successfully triggered, broke the cyclic dependency graph by terminating process 21804, and allowed process 21805 to proceed to completion.
