# Portfolio 4: NoSQL and Advanced Data Models

**Course:** MIT 8103 Advanced Database Systems  
**Session:** 2026/2027 Academic Session  
**Case Study:** ShopEase E-Commerce Platform  
**Component Mark:** 7 Marks  

---

## 1. Executive Summary & Polyglot Persistence Architecture

Modern hyperscale e-commerce platforms like ShopEase cannot efficiently rely on a single relational database engine for all architectural workloads. While relational engines (PostgreSQL) excel at ACID-bound financial transactions and order records, they suffer severe impedance mismatches when dealing with polymorphic product schemas, sub-millisecond session caching, collaborative graph recommendations, and write-heavy time-series event streams.

To resolve these limitations, ShopEase implements a **Polyglot Persistence Architecture**, routing domain requirements to the specialized database model that natively matches their access patterns:

```
                          ┌────────────────────────────────────────┐
                          │   ShopEase API Gateway / Microservices │
                          └───────────────────┬────────────────────┘
                                              │
         ┌──────────────────┬─────────────────┼──────────────────┬─────────────────┐
         ▼                  ▼                 ▼                  ▼                 ▼
 ┌───────────────┐  ┌───────────────┐  ┌──────────────┐  ┌───────────────┐ ┌───────────────┐
 │  PostgreSQL   │  │    MongoDB    │  │    Redis     │  │     Neo4j     │ │   Cassandra   │
 │  (Relational) │  │  (Document)   │  │ (Key-Value)  │  │    (Graph)    │ │ (Wide-Column) │
 └───────┬───────┘  └───────┬───────┘  └──────┬───────┘  └───────┬───────┘ └───────┬───────┘
         │                  │                 │                  │                 │
 • Orders & Payments• Polymorphic     • User Sessions • Recommendations • Clickstream logs
 • Financial Audit  • Catalogs & SKUs • Carts Cache   • "Bought Together"• Time-series
 • Inventory Stock  • Rich Reviews    • Rate Limiting • Fraud Rings     • Telemetry
```

---

## 2. NoSQL Models Implemented for ShopEase

This portfolio implements and demonstrates four primary NoSQL data models using the same ShopEase case study:

### 2.1 Document Model (MongoDB)
- **File:** [document-model.js](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/document-model.js)
- **Primary Use Case:** Product Catalog & Flexible Schema Management.
- **Why Document:** E-commerce products exhibit high polymorphism (e.g., clothing has sizes/colors; laptops have CPUs/RAM/storage; perfumes have scent notes). In relational models, this requires fragile EAV (Entity-Attribute-Value) anti-patterns or sparse columns. MongoDB JSON documents embed polymorphic attributes, localized variants, and nested reviews in a single self-contained structure.

### 2.2 Key-Value Model (Redis)
- **File:** [key-value-model.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/key-value-model.md)
- **Primary Use Case:** Ephemeral Shopping Carts, Token Sessions, and Flash Sale Rate Limiting.
- **Why Key-Value:** In-memory execution provides sub-millisecond latencies for volatile checkout states. Built-in TTL (Time-To-Live) automatically expires abandoned carts and inactive sessions without background cleanup jobs.

### 2.3 Graph Data Model (Neo4j & Cypher)
- **File:** [graph-model.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/graph-model.md)
- **Primary Use Case:** Real-Time Recommendation Engines ("Customers Who Bought X Also Bought Y") & Social Graph.
- **Why Graph:** Traversing multi-hop connections (Customer $\rightarrow$ Order $\rightarrow$ Item $\rightarrow$ Category $\rightarrow$ Similar Item) in SQL requires expensive $n$-way joins that scale poorly. Graph engines traverse relationship pointers in $O(1)$ constant time per hop.

### 2.4 Column-Family Model (Apache Cassandra)
- **File:** [column-family-model.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/column-family-model.md)
- **Primary Use Case:** High-Throughput User Clickstream, Order History Archival, and Shipment Telemetry.
- **Why Wide-Column:** Cassandra uses Log-Structured Merge (LSM) trees, providing near-linear write scalability with zero single points of failure across global data centers.

---

## 3. CAP Theorem & Trade-Off Analysis in ShopEase

Brewer's CAP Theorem dictates that in the presence of a Network Partition ($P$), a distributed system must choose between Consistency ($C$) and Availability ($A$).

| Subsystem | Data Handled | CAP Classification | Trade-Off Decision |
|---|---|---|---|
| **Checkout & Payments (PostgreSQL)** | Ledger, Payment debits, Inventory allocation | **CP (Consistency + Partition Tolerance)** | During a network split, payments and inventory reservation must lock or fail rather than risk double-spending or overselling. Availability is sacrificed. |
| **Product Browsing (MongoDB Replica Set)** | Product descriptions, images, category taxonomies | **AP (Availability + Partition Tolerance)** | If read-replicas become isolated, they continue serving stale catalog data to shoppers rather than taking down product pages. Stale reads are acceptable. |
| **User Activity Feeds (Cassandra / Redis)** | Likes, page views, click telemetry | **AP (Eventual Consistency)** | Maximum availability. A missed or delayed view count will never disrupt checkout or site usability. |

---

## 4. Deliverables Manifest

| Deliverable | Technology | File Link |
|---|---|---|
| MongoDB Implementation Scripts | JavaScript / Mongosh | [document-model.js](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/document-model.js) |
| Redis In-Memory Specification | Redis Commands / Data Structures | [key-value-model.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/key-value-model.md) |
| Graph Database Architecture | Neo4j / Cypher QL | [graph-model.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/graph-model.md) |
| Wide-Column Architecture | Apache Cassandra / CQL | [column-family-model.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/column-family-model.md) |
| Comprehensive Model Comparison | Architectural Synthesis | [nosql-comparison.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-4-nosql/nosql-comparison.md) |
