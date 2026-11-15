# Advanced Database Systems Portfolio (MIT 8103)

**Institution:** MIVA Open University — School of Post Graduate Studies  
**Degree Programme:** Master of Information Technology (M.Sc. IT)  
**Academic Session:** 2026/2027 Session — First Semester  
**Course Code & Title:** MIT 8103 — Advanced Database Systems  
**Assessment:** Individual Practical Database Portfolio (40 Marks)  
**Selected Case Study:** **ShopEase — Enterprise Multi-Vendor E-Commerce Platform**  
**Student Submission Link:** `https://github.com/odipeolu0734/advanced-database-portfolio`  

---

## 1. Case Study & Business Statement

### Organisation Scenario: ShopEase Retail Platform
**ShopEase** is a scalable, multi-vendor electronic commerce platform supporting the online presentation, transactional ordering, inventory tracking, secure payment capture, and delivery logistics for a diverse inventory spanning consumer electronics, apparel, homeware, and lifestyle accessories.

### System Users & Stakeholders
1. **Shoppers / Customers:** Search and filter product catalogs, manage shopping carts, maintain saved delivery/billing addresses, execute multi-currency card payments, inspect shipment transit, and submit verified customer reviews.
2. **Sellers & Vendors:** Manage merchant store profiles, upload polymorphic product SKUs, adjust warehouse stock levels, inspect sales velocity, and review customer feedback.
3. **Logistics & Carriers:** Ingest real-time shipping events, update GPS package checkpoints, and record signed delivery confirmations.
4. **Platform Operations & Administrators:** Moderate dispute and refund workflows, enforce platform discount coupons, audit transactional consistency, and monitor database telemetry.

### Core Operations Supported Across Portfolios
- **Relational Integrity & Normalisation:** High-throughput transactional data modeled in 3NF/BCNF across 18 relations.
- **Complex Query Processing & Optimization:** Execution plan profiling, multi-table joins, window analytics, recursive CTEs, and strategic composite/partial indexing.
- **Transactional Atomicity & Concurrency Control:** Multi-statement order checkouts with pessimistic locking (`SELECT FOR UPDATE`), isolation anomaly mitigations, and automatic deadlock resolution.
- **Polyglot NoSQL Architecture:** Document modeling in MongoDB for polymorphic catalogs, in-memory caching in Redis, graph traversals in Neo4j for collaborative filtering, and wide-column time-series in Cassandra.
- **Distributed & Cloud Operations:** PostgreSQL declarative range/list/hash partitioning, synchronous primary-replica streaming replication, automated failover with Patroni/Raft, and AWS Aurora cloud deployment.

---

## 2. Repository Directory Structure

```text
advanced-database-portfolio/
│
├── portfolio-1-database-design/
│   ├── README.md                   # Case study, entities, keys, referential actions
│   ├── er-diagram.md               # Interactive Mermaid ER diagram (18 entities)
│   ├── schema.sql                  # Complete PostgreSQL DDL (tables, constraints, indexes)
│   ├── seed-data.sql               # Comprehensive seed data script across all tables
│   └── normalisation.md            # Rigorous theoretical normalisation (UNF -> 1NF -> 2NF -> 3NF -> BCNF)
│
├── portfolio-2-query-optimisation/
│   ├── README.md                   # Query catalogue, design patterns, index strategies
│   ├── queries.sql                 # 22 SQL queries + 4 analytical views (Simple to Recursive CTEs)
│   ├── execution-plans.md          # EXPLAIN (ANALYZE, BUFFERS) deep-dive for 5 enterprise queries
│   ├── indexing-optimisation.sql   # B-tree, composite, partial, covering, expression indexes
│   └── performance-analysis.md     # Before vs. after benchmarking matrix (95%+ latency improvements)
│
├── portfolio-3-transactions-concurrency/
│   ├── README.md                   # ACID properties, locking fundamentals, anomaly taxonomy
│   ├── transactions.sql            # Order placement, refunds, batch inventory, savepoints
│   ├── concurrency-control.sql     # Dirty read, non-repeatable read, phantoms, lost updates, deadlocks
│   ├── isolation-levels.md         # PostgreSQL MVCC mechanics, xmin/xmax, isolation comparison
│   └── concurrency-output.md       # Verifiable terminal outputs showing locks and SSI aborts
│
├── portfolio-4-nosql/
│   ├── README.md                   # Polyglot persistence overview & CAP trade-offs
│   ├── document-model.js           # MongoDB document schema, validation, CRUD, aggregation pipelines
│   ├── key-value-model.md          # Redis in-memory session caching, carts, rate limiters, ZSETs
│   ├── graph-model.md              # Neo4j & Cypher collaborative filtering recommendations & fraud rings
│   ├── column-family-model.md      # Apache Cassandra CQL time-series clickstream & parcel telemetry
│   └── nosql-comparison.md         # Synthesis matrix comparing all 5 database paradigms
│
├── portfolio-5-distributed-cloud/
│   ├── README.md                   # Distributed database architecture summary
│   ├── distributed-architecture.md # Replication topologies, sharding, consensus (Patroni/Raft)
│   ├── partitioning.sql            # PostgreSQL Range (Orders), List (Regions), Hash (SKUs)
│   ├── cap-theorem-analysis.md     # CAP & PACELC theorem trade-offs across e-commerce domains
│   ├── cloud-deployment.md         # AWS Aurora Serverless v2 deployment guide & Terraform script
│   └── replication-config.md       # Primary postgresql.conf, pg_hba.conf, PgBouncer pooler config
│
├── FINAL-PORTFOLIO-DOCUMENTATION.md # 2-3 page LMS submission summary, reflection, and AI declaration
└── README.md                       # This master repository index
```

---

## 3. Portfolio Component Mapping & Marks Allocation

| Portfolio Activity | Technical Focus | Allocated Marks | Evidence Files |
|---|---|:---:|---|
| **Portfolio 1** | Database Design & Modelling | **7 Marks** | [portfolio-1-database-design/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/README.md) |
| **Portfolio 2** | Query Processing & Optimisation | **7 Marks** | [portfolio-2-query-optimisation/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-2-query-optimisation/README.md) |
| **Portfolio 3** | Transactions & Concurrency | **7 Marks** | [portfolio-3-transactions-concurrency/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-3-transactions-concurrency/README.md) |
| **Portfolio 4** | NoSQL & Advanced Data Models | **7 Marks** | [portfolio-4-nosql/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/README.md) |
| **Portfolio 5** | Distributed & Cloud Database Exercise | **6 Marks** | [portfolio-5-distributed-cloud/](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-5-distributed-cloud/README.md) |
| **Final Docs** | Technical Reflection & Synthesis | **6 Marks** | [FINAL-PORTFOLIO-DOCUMENTATION.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/FINAL-PORTFOLIO-DOCUMENTATION.md) |
| **Total** | | **40 Marks** | Full practical evidence provided |

---

## 4. Quick-Start Reproduction Guide

### Prerequisites
- PostgreSQL 15+ (`psql` CLI)
- MongoDB 6.0+ (`mongosh`)
- Redis 7.0+ (`redis-cli`)

### Step 1: Initialize Relational Database (Portfolio 1)
```bash
# Connect to PostgreSQL and provision ShopEase schema
psql -U postgres -d postgres -f portfolio-1-database-design/schema.sql

# Seed 18 tables with sample enterprise data
psql -U postgres -d postgres -f portfolio-1-database-design/seed-data.sql
```

### Step 2: Run Analytical Queries & Optimisations (Portfolio 2)
```bash
# Execute analytical query catalog
psql -U postgres -d postgres -f portfolio-2-query-optimisation/queries.sql

# Apply performance indexes
psql -U postgres -d postgres -f portfolio-2-query-optimisation/indexing-optimisation.sql
```

### Step 3: Verify Transactions & Concurrency (Portfolio 3)
```bash
# Run transactional order flows
psql -U postgres -d postgres -f portfolio-3-transactions-concurrency/transactions.sql
```

### Step 4: Run MongoDB Document Scripts (Portfolio 4)
```bash
# Execute MongoDB document model, indexes, and aggregation pipelines
mongosh < portfolio-4-nosql/document-model.js
```

### Step 5: Test Table Partitioning & Pruning (Portfolio 5)
```bash
# Provision Range, List, and Hash declarative partitions
psql -U postgres -d postgres -f portfolio-5-distributed-cloud/partitioning.sql
```

---

## 5. Academic Verification & LMS Deliverable

The complete 2-3 page condensed documentation formatted specifically for LMS submission, containing the **Technical Reflection**, **AI Use Declaration**, and **GitHub Verification Links**, is available at:
👉 **[FINAL-PORTFOLIO-DOCUMENTATION.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/FINAL-PORTFOLIO-DOCUMENTATION.md)**
