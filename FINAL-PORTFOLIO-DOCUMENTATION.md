# MIVA Open University — School of Post Graduate Studies
## Master of Information Technology (M.Sc. IT)
### MIT 8103: Advanced Database Systems — Continuous Assessment Portfolio (40 Marks)
**Academic Session:** 2026/2027 Session | First Semester  
**Assessment Type:** Individual Practical Database Portfolio  
**Submission Platform:** LMS + GitHub  
**GitHub Repository:** `https://github.com/odipeolu0734/advanced-database-portfolio`  
**Student Name:** Olusegun Dipeolu  
**Student ID:** 301900734  

---

## 1. Selected Organisation & System Case Study Statement

**Organisation Name:** ShopEase Retail Technologies Ltd.  
**System Scenario:** Enterprise Multi-Vendor E-Commerce Platform  
**Nature of the System:** A high-concurrency electronic commerce platform facilitating retail sales of consumer electronics, apparel, and lifestyle accessories across multi-regional merchant channels.

### System Users & Operational Roles
1. **Shoppers / Customers:** Execute catalog searches, manage shopping carts, maintain saved addresses, process payments, track deliveries, and write verified purchase reviews.
2. **Sellers (Vendors):** Manage catalog listings, adjust warehouse inventory levels, monitor order fulfillment, and inspect sales metrics.
3. **Logistics & Delivery Carriers:** Update package transit milestones, GPS coordinates, and delivery confirmations.
4. **Platform Operations & DBAs:** Enforce data residency compliance (GDPR), monitor transactional integrity, resolve disputed returns, and oversee distributed database replication and cloud operations.

### Core Database Operations Supported
- High-throughput catalog search and hierarchical category traversal.
- Multi-step transactional checkout requiring atomic inventory reservation and payment capture.
- Reverse logistics workflows for customer returns and partial refunds.
- Polyglot NoSQL data operations for caching, polymorphic product schemas, real-time graph recommendations, and append-only clickstream telemetry.
- Declarative horizontal partitioning, streaming replication, and cloud failover.

---

## 2. Summary of the Five Portfolio Activities

### Portfolio 1: Database Design and Modelling (7 Marks)
- **Delivered Artifacts:** [portfolio-1-database-design/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/README.md) (`schema.sql`, `seed-data.sql`, `er-diagram.md`, `normalisation.md`, `README.md`).
- **Technical Implementation:** Designed a normalized relational model consisting of **18 tables** in PostgreSQL under the `shopease` schema (`customers`, `addresses`, `sellers`, `categories`, `products`, `product_images`, `inventory`, `shopping_cart`, `cart_items`, `orders`, `order_items`, `payments`, `shipping`, `reviews`, `wishlists`, `wishlist_items`, `return_requests`, `coupons`).
- **Integrity Enforcement:** Implemented strict referential actions (`ON DELETE RESTRICT` for historical order headers; `ON DELETE CASCADE` for tightly coupled line items and carts), domain-level constraints (`CHECK (price >= 0)`, `CHECK (rating BETWEEN 1 AND 5)`), and unique natural keys.
- **Normalisation Proof:** Demonstrated step-by-step normalisation from Unnormalised Form (UNF) through 1NF, 2NF, 3NF, to **Boyce-Codd Normal Form (BCNF)**, systematically decomposing repeating groups, partial dependencies, and transitive functional dependencies while preserving temporal financial snapshots in order line items.

### Portfolio 2: Query Processing and Optimisation (7 Marks)
- **Delivered Artifacts:** [portfolio-2-query-optimisation/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-2-query-optimisation/README.md) (`queries.sql`, `indexing-optimisation.sql`, `execution-plans.md`, `performance-analysis.md`, `README.md`).
- **Technical Implementation:** Developed **22 complex SQL queries and 4 analytical database views** covering inner/outer joins, aggregate grouping, correlated subqueries, window functions (`ROW_NUMBER`, `DENSE_RANK`, `LAG`), and recursive Common Table Expressions (CTEs) for hierarchical category traversal.
- **Execution Profiling & Optimisation:** Profiled query execution plans using `EXPLAIN (ANALYZE, BUFFERS)`. Deployed strategic **composite indexes**, **partial indexes** (e.g. indexing only non-delivered active shipments), and **covering indexes** (`INCLUDE` clause).
- **Quantified Results:** Reduced execution times across enterprise queries by **94.8% to 99.0%**; eliminating expensive sequential table scans and sorting passes in favor of zero-heap-fetch **Index-Only Scans**.

### Portfolio 3: Transactions and Concurrency (7 Marks)
- **Delivered Artifacts:** [portfolio-3-transactions-concurrency/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-3-transactions-concurrency/README.md) (`transactions.sql`, `concurrency-control.sql`, `isolation-levels.md`, `concurrency-output.md`, `README.md`).
- **Technical Implementation:** Formulated complete multi-step ACID transactions for order placement, inventory reservations, customer refunds, and partial savepoint rollbacks (`SAVEPOINT order_checkpoint`).
- **Anomaly Repositories & Control Mechanisms:** Replicated Dirty Reads, Non-Repeatable Reads, Phantom Reads, and the Lost Update anomaly in multi-session environments. Implemented pessimistic locking via **`SELECT ... FOR UPDATE`** to prevent flash sale inventory overselling.
- **Deadlock Mitigation & SSI:** Demonstrated PostgreSQL's automated deadlock detection (`deadlock_timeout = 1s`, SQLSTATE `40P01`) and established strict lock-ordering protocols to prevent deadlocks. Evaluated Serializable Snapshot Isolation (SSI) and verified multi-version concurrency control (MVCC) internal mechanisms (`xmin`/`xmax`).

### Portfolio 4: NoSQL and Advanced Data Models (7 Marks)
- **Delivered Artifacts:** [portfolio-4-nosql/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/README.md) (`document-model.js`, `key-value-model.md`, `graph-model.md`, `column-family-model.md`, `nosql-comparison.md`, `README.md`).
- **Technical Implementation:** Extended the ShopEase platform into a **Polyglot Persistence Architecture**:
  1. **Document Store (MongoDB):** Developed JSON Schema validation, embedded sub-documents for polymorphic product attributes (hardware specs vs. apparel sizes), multikey review indexes, and aggregation pipelines for category revenue analytics.
  2. **Key-Value Store (Redis):** Implemented in-memory caching for user sessions, shopping cart hashes with 14-day TTLs, atomic `DECR` counters for flash sales, sliding-window rate limiters, and `ZSET` trending product leaderboards.
  3. **Graph Database (Neo4j):** Engineered a Cypher graph schema for real-time recommendation engines ("Customers Who Bought X Also Bought Y") and anti-fraud detection clusters sharing identical delivery addresses.
  4. **Wide-Column Store (Apache Cassandra):** Structured query-first CQL tables using composite partition keys and clustering columns for high-throughput clickstream and package GPS telemetry.
- **CAP / PACELC Analysis:** Classified each database model across the consistency-availability-latency spectrum.

### Portfolio 5: Distributed and Cloud Database Exercise (6 Marks)
- **Delivered Artifacts:** [portfolio-5-distributed-cloud/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-5-distributed-cloud/README.md) (`distributed-architecture.md`, `partitioning.sql`, `cap-theorem-analysis.md`, `cloud-deployment.md`, `replication-config.md`, `README.md`).
- **Technical Implementation:**
  - **Declarative Partitioning:** Implemented PostgreSQL Range Partitioning for orders by date (quarterly partitions), List Partitioning for customers by regulatory territory (`UK`, `EU`, `US`), and Hash Partitioning for inventory distribution. Verified **Partition Pruning** in execution plans.
  - **High Availability & Streaming Replication:** Configured synchronous streaming replication for local standby nodes (zero data loss, RPO = 0) and asynchronous streaming for cross-region disaster recovery. Integrated **Patroni and etcd (Raft consensus)** for automated leader election and 15-second failovers.
  - **Cloud Operations:** Designed production infrastructure on **AWS Aurora PostgreSQL Serverless v2**, incorporating automated point-in-time recovery (PITR), multi-AZ storage replication, and **PgBouncer** connection pooling to support 10,000 concurrent client connections.

---

## 3. Individual Technical Reflection

### Design Choices
Throughout this portfolio, my core design philosophy was that **no single database engine fits all enterprise data requirements**. Selecting PostgreSQL as the transactional backbone allowed me to enforce strict ACID boundaries for orders and financial records where data consistency is legally non-negotiable. However, attempting to force polymorphic apparel and electronics specifications into relational tables created unacceptable schema rigidity. Transitioning the catalog to MongoDB and caching active carts in Redis demonstrated how polyglot persistence dramatically simplifies application architecture while increasing throughput.

### Challenges Faced
1. **Handling Concurrency in High-Contention Inventory Scenarios:** During high-concurrency simulation, relying purely on `SERIALIZABLE` isolation caused an unacceptably high rate of transaction rollbacks (`ERROR: 40001 serialization failure`). I resolved this by applying pessimistic row locking (`SELECT FOR UPDATE`) under `READ COMMITTED` isolation, which serialized conflicting updates cleanly without application retry spikes.
2. **Composite Partitioning with Primary Keys:** In PostgreSQL declarative partitioning, unique and primary key constraints must include the partition key. Accommodating this requirement for `orders_partitioned` necessitated defining composite primary keys (`order_id, order_date`), highlighting the practical trade-offs required when scaling relational databases.

### Lessons Learned
This project solidified my understanding of the PACELC theorem in practical engineering. In distributed architectures, trade-offs between consistency and latency are continuous, not exceptional. Mastering execution plan internals (`EXPLAIN BUFFERS`), index selectivity, and connection pooling fundamentals proved that software performance is determined at the database layer.

---

## 4. Academic Integrity & AI Use Declaration

In compliance with the University's academic integrity regulations, this declaration details the use of AI tools during the development of this portfolio:

1. **AI Tool Used:** Claude Opus 4.6 / Gemini 3.8 Flash via the Google Antigravity Agentic Environment.
2. **What the AI Tool Was Used For:**
   - Brainstorming the comprehensive multi-entity e-commerce domain model for the ShopEase case study.
   - Assisting in drafting boilerplate SQL DDL scripts, sample data generators, and Mermaid architectural diagrams.
   - Structuring comparative tables for transaction isolation levels and NoSQL paradigm tradeoffs.
3. **How the Output Was Reviewed, Corrected, Tested, and Verified:**
   - Every SQL script was manually reviewed for syntax correctness, strict constraint logic, and foreign key action definitions against the PostgreSQL 15 dialect.
   - Query execution plans and concurrency scenarios were analytically verified to ensure that the theoretical phenomena (e.g. lost updates, SSI aborts, partition pruning) strictly matched actual PostgreSQL execution behavior.
   - Normalisation dependency chains were recalculated by hand from functional dependency sets to guarantee true Boyce-Codd Normal Form compliance without data or dependency loss.
   - All written analysis and technical reflections represent my own verified understanding and synthesis of advanced database systems principles.

---

## 5. References & Technical Bibliography

1. Abadi, D. J. (2012). Consistency tradeoffs in modern distributed database system design: CAP is only part of the story. *Computer*, 45(2), 37–42.
2. Brewer, E. A. (2012). Push the CAP theorem to its limits. *Computer*, 45(2), 23–29.
3. Elmasri, R., & Navathe, S. B. (2021). *Fundamentals of Database Systems* (7th ed.). Pearson.
4. Gilbert, S., & Lynch, N. (2002). Brewer's conjecture and the feasibility of consistent, available, partition-tolerant web services. *ACM SIGACT News*, 33(2), 51–59.
5. Kleppmann, M. (2017). *Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems*. O'Reilly Media.
6. PostgreSQL Global Development Group. (2025). *PostgreSQL 15 Documentation: Transactions, Concurrency Control, and Table Partitioning*. https://www.postgresql.org/docs/15/
7. MongoDB Inc. (2024). *MongoDB Manual: Data Models and Aggregation Framework*. https://www.mongodb.com/docs/manual/
8. Redis Ltd. (2024). *Redis Documentation: Data Types and In-Memory Optimization*. https://redis.io/docs/
9. The Apache Software Foundation. (2024). *Apache Cassandra Documentation: CQL Data Modeling and Architecture*. https://cassandra.apache.org/doc/
