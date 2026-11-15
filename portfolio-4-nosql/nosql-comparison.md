# Portfolio 4: Comprehensive Database Model Comparison & Architectural Synthesis

**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** ShopEase E-Commerce Platform  
**Component:** Multi-Model Database Analysis  

---

## 1. Paradigm Comparison Matrix

The table below contrasts the five distinct database models evaluated for the ShopEase e-commerce platform:

| Evaluation Dimension | Relational (PostgreSQL) | Document (MongoDB) | Key-Value (Redis) | Graph (Neo4j) | Wide-Column (Cassandra) |
|---|---|---|---|---|---|
| **Data Representation** | Normalised 2D tables (rows & columns) | Hierarchical JSON/BSON documents | Key-value pairs (strings, hashes, sets) | Nodes & directed relationships (edges) | Partitioned sparse tables of cell families |
| **Primary Query Language** | ANSI SQL with procedural PL/pgSQL | MQL (MongoDB Query Language) & Aggregation | Native Redis command set / Lua scripts | Cypher Query Language (CQL) | Cassandra Query Language (CQL) |
| **Schema Paradigm** | Strict, compile-time schema enforcement (DDL) | Dynamic, polymorphic schema (optional JSON Schema) | Schemaless | Flexible labeled property graph | Fixed column family schema; query-first |
| **Typical Read Latency** | 2 – 15 ms | 2 – 10 ms | **< 1 ms (Sub-millisecond)** | 2 – 12 ms (traversals) | 2 – 5 ms |
| **Typical Write Latency** | 5 – 25 ms (ACID commit overhead) | 3 – 12 ms | **< 1 ms** | 5 – 20 ms | **< 2 ms (LSM CommitLog append)** |
| **Scaling Architecture** | Vertical scale-up; Read replicas | Horizontal sharding via mongos routers | Redis Cluster (hash slots sharding) | Scale-up core; Read-replica fabric | **Masterless peer-to-peer ring (Linear horizontal)** |
| **CAP Theorem Profile** | **CA / CP** (ACID strictly prioritized) | **CP** (Configurable read preference) | **AP / CP** (Configurable clustering) | **CA** (ACID native graph engine) | **AP** (Tunable Consistency $R+W > N$) |
| **Transaction Model** | Full ACID (Multi-table serializable) | ACID multi-document (v4.0+) | Atomic per key/pipeline; MULTI/EXEC | Full ACID graph transactions | Lightweight transactions (Paxos LWT) |
| **Join Capability** | Native, highly optimised $N$-way joins | `$lookup` stage (computationally expensive) | None | Direct pointer traversals ($O(1)$ per hop) | None (Anti-pattern; denormalization mandatory) |
| **Optimal ShopEase Role** | Orders, Financial Ledger, Invoicing, Tax | Product Catalog, Polymorphic SKUs, Reviews | User Sessions, Ephemeral Carts, Rate Limits | Social Recommendations, Fraud Rings | Clickstream Logs, Shipment GPS Telemetry |

---

## 2. Deep-Dive: When to Choose Which Model in E-Commerce

### 2.1 When to choose Relational (PostgreSQL)
- **Financial Balances and Billing:** Every transaction modifying money (e.g. `payments`, `orders`, `return_requests`) requires strict transactional isolation to guarantee that funds are never debited without a corresponding order creation.
- **Complex Analytical Ad-Hoc Queries:** Relational optimizers generate dynamic query plans across dozens of relations without demanding advance knowledge of access patterns.

### 2.2 When to choose Document (MongoDB)
- **Catalogs with Diverse, Polymorphic Attributes:** Selling shoes (sizes, colors, heel height) alongside laptops (RAM, SSD, screen resolution) and perfumes (fragrance notes, volume) produces an unmaintainable nightmare of nullable columns in relational systems. A document embeds dynamic attributes natively.
- **Single-Page Reads (Document Atomicity):** Loading a product page requires the product description, its active images, and its top 5 reviews. In SQL, this involves 3 joins. In MongoDB, a single index read retrieves the entire hydrated document in one operation.

### 2.3 When to choose Key-Value (Redis)
- **Volatile, High-Throughput Checkout Queues:** Managing shopping carts for 500,000 active shoppers browsing simultaneously would overwhelm disk I/O in PostgreSQL. Redis keeps this data in RAM with automatic TTL eviction.
- **Atomic Concurrency Primitives:** Redis primitives like `DECR` allow sub-millisecond stock reservations during high-concurrency flash sales with zero database lock contention.

### 2.4 When to choose Graph (Neo4j)
- **Collaborative Filtering & "People Also Bought":** Calculating co-purchase affinity requires traversing multiple levels of relationships. In SQL, joining `orders` $\rightarrow$ `order_items` $\rightarrow$ `customers` $\rightarrow$ `orders` $\rightarrow$ `products` creates massive intermediate Cartesian products. In Neo4j, traversing relationship pointers has constant time complexity relative to the node degree.
- **Fraud Detection:** Identifying organized crime rings that recycle stolen credit cards or delivery addresses across multiple accounts.

### 2.5 When to choose Wide-Column (Cassandra)
- **Append-Only Event Streams:** Clickstream analysis, mouse tracking, and parcel delivery GPS pings generate millions of write operations per minute. Cassandra's LSM trees absorb these sequential writes at line rate without degrading query performance.
- **Multi-Region Active-Active Deployments:** Cassandra's masterless ring architecture allows writes to occur simultaneously in London, Frankfurt, and Virginia with automatic conflict resolution.

---

## 3. Conclusion & Polyglot Persistence Blueprint

There is no single "best" database for modern enterprise systems. The architectural excellence of ShopEase lies not in replacing PostgreSQL with NoSQL, but in **polyglot specialization**:
1. PostgreSQL handles **state transitions requiring ACID correctness**.
2. MongoDB handles **polymorphic entity catalogs**.
3. Redis handles **ephemeral high-velocity state**.
4. Neo4j handles **relationship network traversals**.
5. Cassandra handles **boundless time-series log ingestion**.
