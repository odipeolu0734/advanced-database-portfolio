# Portfolio 5: CAP & PACELC Theorem Architectural Analysis

**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** ShopEase E-Commerce Platform  
**Component:** Distributed Systems Theory & Practical Trade-Offs  

---

## 1. Theoretical Foundations: CAP & PACELC

### 1.1 Brewer's CAP Theorem
Formulated by Eric Brewer and formally proven by Gilbert and Lynch (2002), the CAP theorem asserts that any distributed data store can simultaneously guarantee at most two of the following three properties:
- **Consistency ($C$):** Every read receives the most recent write or an error (Linearizability).
- **Availability ($A$):** Every non-failing node returns a non-error response for every received request, without guarantee that it contains the most recent write.
- **Partition Tolerance ($P$):** The system continues to operate despite an arbitrary number of messages being dropped or delayed by the network between nodes.

Because physical network hardware is inherently prone to severed fiber lines, switch reboots, and packet loss, **Partition Tolerance ($P$) is non-negotiable in distributed environments**. Thus, a distributed database must architecturally trade off between **Consistency ($C$)** and **Availability ($A$)** during network partitions.

### 1.2 The PACELC Theorem Extension
Formulated by Daniel Abadi (2012), PACELC extends CAP by acknowledging that network partitions are rare. PACELC asks what trade-offs occur during normal system operation:

$$\text{If } \mathbf{P} \text{ (Partition): Choose } \mathbf{A} \lor \mathbf{C}; \quad \mathbf{E} \text{ (Else / Normal Operations): Choose } \mathbf{L} \lor \mathbf{C}$$

Where:
- $\mathbf{P / A}$: In a partition, maximize Availability (e.g., DynamoDB, Cassandra).
- $\mathbf{P / C}$: In a partition, enforce Consistency (e.g., PostgreSQL, CockroachDB).
- $\mathbf{E / L}$: In normal operations, minimize Latency (eventual consistency, local memory reads).
- $\mathbf{E / C}$: In normal operations, enforce Consistency (synchronous replication, higher write latency).

---

## 2. Subsystem Mapping in the ShopEase Platform

A single monolithic CAP decision across an entire e-commerce ecosystem is an anti-pattern. Different business domains require different consistency and availability guarantees:

```
                                  [ PACELC Spectrum in ShopEase ]
        
      PC / EC (Max Consistency)                                    PA / EL (Max Availability)
 ◄─────────────────────────────────────────────────────────────────────────────────────────────►
   • Payments & Ledgers          • Real-time Inventory       • Product Reviews     • Clickstream
   • Order Finalization          • Cart Reservations         • Catalog Browsing    • Page Views
   (PostgreSQL Primary)          (Redis Cluster)             (MongoDB Replica)     (Cassandra)
```

### Detailed Subsystem Breakdown Matrix

| Subsystem | Underlying Technology | PACELC Classification | Justification & Business Consequence |
|---|---|---|---|
| **Payments & General Ledger** | PostgreSQL 15 | **PC / EC** | If the transatlantic link between London and Virginia splits, payment mutations must halt or fail rather than risk debiting a customer twice or capturing fraudulent funds. In normal operations, synchronous commit ($E/C$) is enforced despite latency overhead. |
| **Inventory Stock Allocation** | PostgreSQL + Redis Lua | **PC / EC** | During flash sales, if two nodes lose connectivity, selling the same item twice (overselling) creates legal and fulfillment liabilities. Consistency overrides availability. |
| **Product Catalog & Search** | MongoDB Replica Set | **PA / EL** | If a secondary replica in Singapore loses connection to the primary in Ireland, it must continue serving product details and images to local shoppers. Reading a price that is 30 seconds stale is vastly preferable to displaying an HTTP 500 error page. |
| **Active Shopping Carts** | Redis (Hash Slots) | **PA / EL** | High availability is paramount for shopping cart retention. If temporary replication lag drops a newly added item from view for 200 ms, the customer simply clicks "Add to Cart" again; a total checkout outage destroys conversion rates. |
| **Product Reviews & Ratings** | MongoDB / Elasticsearch | **PA / EL** | Reviews are inherently tolerant of eventual consistency. Whether a newly posted 5-star review appears in 20 milliseconds or 3 seconds has zero operational impact on system correctness. |
| **Clickstream & Parcel GPS Telemetry** | Apache Cassandra | **PA / EL** | Write throughput reaches 100,000 events/second. Ingestion must never reject incoming sensor coordinates. Cassandra writes locally at `CONSISTENCY ONE` and repairs replicas asynchronously via hinted handoffs and anti-entropy read repairs. |

---

## 3. Failure Scenario Walkthrough: Transatlantic Network Partition

### Scenario Description
At 14:00 UTC, a subsea fiber cut isolates ShopEase's **Primary Region (`eu-west-1`, Dublin)** from its **Disaster Recovery Region (`us-east-1`, Virginia)**.

```
       [ Region: eu-west-1 ]                   [ Region: us-east-1 ]
   ┌───────────────────────────┐           ┌───────────────────────────┐
   │ PG Primary + Sync Replica │           │ PG Cross-Region Replica   │
   │ (Quorum = 2 / 3 nodes)    │   XXXXX   │ (Quorum = 1 / 3 nodes)    │
   │ State: CAN REACH QUORUM   │   Fiber   │ State: MINORITY ISOLATED  │
   │ Mode: ACCEPT READ/WRITE   │   Cut     │ Mode: FORCE READ-ONLY     │
   └───────────────────────────┘           └───────────────────────────┘
```

### Protocol Execution Step-by-Step
1. **Quorum Detection via Patroni / Raft:**
   - The cluster consists of 3 consensus voters.
   - The Dublin cluster retains 2 voters (Dublin Primary + Dublin Standby), representing a **66.7% majority quorum**.
   - The Virginia node detects loss of heartbeats and attempts to check its quorum. Holding only 1 vote (33.3%), it recognizes it is in the minority partition.
2. **Preventing Split-Brain:**
   - The Virginia node is strictly prohibited by Patroni from promoting itself to primary. It remains in read-only standby mode, serving local cached reads.
   - Dublin continues processing payment transactions without interruption.
3. **Partition Healing & Resynchronization:**
   - At 14:45 UTC, the network link is restored.
   - The Virginia standby node contacts the Dublin primary.
   - PostgreSQL streaming replication calculates the Log Sequence Number (LSN) gap from the Dublin Write-Ahead Log (WAL) archive and fast-forwards the Virginia replica to the current state without manual intervention.
