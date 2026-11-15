# Portfolio 3: Transaction Isolation Levels in PostgreSQL

**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** ShopEase E-Commerce Platform  
**RDBMS:** PostgreSQL 15+  
**Component:** Concurrency Control and Isolation Analysis  

---

## 1. Overview of ANSI SQL vs. PostgreSQL Isolation Levels

Transaction isolation governs the degree to which modifications made by concurrent transactions are visible to one another. The ANSI/ISO SQL standard defines four standard isolation levels based on three read phenomenon anomalies:
1. **Dirty Read:** Reading uncommitted changes made by a concurrent transaction.
2. **Non-Repeatable (Fuzzy) Read:** Re-reading previously retrieved rows within the same transaction and discovering that values have been updated or deleted by another committed transaction.
3. **Phantom Read:** Re-executing a range query within the same transaction and discovering new rows inserted by another committed transaction.

### PostgreSQL Implementation Specifics
PostgreSQL implements Multi-Version Concurrency Control (MVCC). Because data modifications generate new row versions (tuples) rather than overwriting existing blocks in place:
- **READ UNCOMMITTED** is internally mapped directly to **READ COMMITTED**. Dirty reads are structurally impossible in PostgreSQL.
- **REPEATABLE READ** in PostgreSQL also eliminates standard Phantom Reads by freezing the query snapshot at the transaction's first query.
- **SERIALIZABLE** uses Serializable Snapshot Isolation (SSI), detecting predicate lock conflicts without blocking readers.

---

## 2. Comparative Anomaly Matrix

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Serialization Anomaly (Write Skew) | PostgreSQL Implementation Mechanism |
|---|---|---|---|---|---|
| **Read Uncommitted** | Prevented *(PostgreSQL specific)* | Possible | Possible | Possible | Treated as Read Committed via MVCC |
| **Read Committed** *(Default)* | Prevented | Possible | Possible | Possible | Each statement sees a fresh snapshot of committed data |
| **Repeatable Read** | Prevented | Prevented | Prevented *(In PostgreSQL MVCC)* | Possible | Entire transaction uses the snapshot taken at the start of its first statement |
| **Serializable** | Prevented | Prevented | Prevented | Prevented | SSI (SIREAD predicate locks monitor read-write conflict cycles) |

---

## 3. Practical Isolation Level Selection for ShopEase

In an enterprise e-commerce platform, applying `SERIALIZABLE` globally degrades system throughput due to serialization aborts and retry overhead. Conversely, using `READ COMMITTED` indiscriminately exposes financial workflows to race conditions. The optimal strategy applies targeted isolation levels based on workload semantics:

### 3.1 Scenario A: Product Catalog Browsing & Full-Text Search
- **Level Applied:** `READ COMMITTED`
- **Justification:** High read concurrency (90%+ of site traffic). Customers browsing categories or searching for items tolerate slight differences in stock numbers between consecutive page loads. High performance and zero lock contention are paramount.
- **Locking Overhead:** Minimal. MVCC ensures readers never block writers and writers never block readers.

### 3.2 Scenario B: Shopping Cart Checkout & Stock Allocation
- **Level Applied:** `READ COMMITTED` with Explicit Pessimistic Locking (`SELECT FOR UPDATE`)
- **Justification:** Flash sales create extreme contention on single rows in `inventory`. Setting `SERIALIZABLE` would cause 90% of concurrent checkout transactions to fail with serialization failures (`ERROR: 40001`). Using `SELECT FOR UPDATE` queues concurrent checkout attempts in FIFO order without transaction aborts, ensuring clean stock decrements.

### 3.3 Scenario C: Daily Financial Audit & Tax Reconciliation
- **Level Applied:** `REPEATABLE READ`
- **Justification:** Financial batch jobs aggregate orders, payments, taxes, and shipping expenses across multiple long-running analytical queries. The entire audit must evaluate a mutually consistent point-in-time snapshot. `REPEATABLE READ` guarantees that new orders committed halfway through the reporting job do not corrupt cross-table reconciliation totals.

### 3.4 Scenario D: Coupon Quota Enforcement & Promotion Budgets
- **Level Applied:** `SERIALIZABLE`
- **Justification:** A promotional coupon provides £50 off but has a strict global usage limit of 100 redemptions. If 150 users attempt to redeem the code concurrently, a classic **Write Skew** anomaly could allow redemptions to exceed 100 if two sessions check the aggregate count concurrently. SSI automatically aborts the conflicting transactions, enforcing absolute budget invariance.

---

## 4. MVCC Mechanics: `xmin`, `xmax`, and Vacuuming

PostgreSQL coordinates concurrency using hidden system columns attached to every physical heap tuple:
- **`xmin`:** The transaction identifier (XID) of the creating transaction.
- **`xmax`:** The transaction identifier of the deleting/updating transaction (or 0 for active tuples).

When an e-commerce order updates a product price:
1. The old tuple's `xmax` is updated with the current transaction's XID.
2. A new tuple is appended to the table with `xmin` equal to the current XID and `xmax = 0`.
3. Readers evaluate tuple visibility by checking whether the tuple's `xmin` is committed and prior to their transaction's snapshot.
4. **VACUUM:** Dead tuples (where `xmax` is older than the oldest running transaction) are reclaimed by the PostgreSQL Autovacuum daemon to maintain compact disk pages.
