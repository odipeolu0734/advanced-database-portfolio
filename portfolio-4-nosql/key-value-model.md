# Portfolio 4: Key-Value Data Model Implementation (Redis)

**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** ShopEase E-Commerce Platform  
**Technology:** Redis 7.2+  
**Component:** In-Memory Caching, Sessions, and Ephemeral State  

---

## 1. Architectural Role of Key-Value Store in ShopEase

Relational disk-backed databases are ill-suited for extremely high-frequency, transient data workloads that require sub-millisecond responses. In ShopEase, **Redis** acts as an ultra-fast in-memory layer positioned between the API microservices and the primary PostgreSQL database:

```
 [ Client App ] ──► [ API Gateway ]
                          │
         ┌────────────────┴────────────────┐
         ▼ (Sub-millisecond latency)       ▼ (Persistent ACID)
   [ Redis 7.2 ]                    [ PostgreSQL 15 ]
   - User Sessions                  - Orders & Ledger
   - Ephemeral Shopping Carts       - Master Catalog
   - Flash Sale Stock Counters      - Customer Profiles
   - API Rate Limiters              - Audit Trails
```

---

## 2. Core E-Commerce Use Cases & Redis Data Structures

Redis provides rich native data structures. Below is how each is leveraged across ShopEase:

| Use Case | Redis Data Type | Key Pattern | TTL / Expiry Policy |
|---|---|---|---|
| **User Authentication Sessions** | `Hash` | `session:{token}` | 24 Hours (sliding expiration) |
| **Ephemeral Shopping Cart** | `Hash` | `cart:cust:{customer_id}` | 14 Days |
| **Real-Time Stock Decrement (Flash Sale)** | `String` (Atomic Integer) | `stock:sku:{sku}` | No expiry (synced to PostgreSQL) |
| **Trending Products Leaderboard** | `Sorted Set (ZSET)` | `leaderboard:daily_views:{date}` | 48 Hours |
| **API Gateway Rate Limiting** | `Sorted Set (ZSET)` | `ratelimit:{ip_or_user}:{endpoint}` | 60 Seconds |
| **Recently Viewed Products Carousel** | `List` | `recent:cust:{customer_id}` | 30 Days (capped at 20 items) |

---

## 3. Concrete Implementation & Redis Commands

### 3.1 Use Case 1: High-Performance Shopping Cart Management
In ShopEase, active shopping carts undergo rapid item additions, deletions, and quantity alterations. Storing these directly in PostgreSQL generates excessive write churn on the `cart_items` table. Instead, carts are maintained in Redis Hashes and synced to PostgreSQL only during final checkout:

```redis
# 1. Customer 101 adds 2 units of Laptop (SKU: LAP-APL-MBP16) to cart
HSET cart:cust:101 "LAP-APL-MBP16" 2

# 2. Customer adds 1 pair of Sneakers (SKU: APP-NIK-AF1-09)
HSET cart:cust:101 "APP-NIK-AF1-09" 1

# 3. Set a 14-day inactivity expiration window (1209600 seconds)
EXPIRE cart:cust:101 1209600

# 4. Fetch the entire cart contents for checkout calculation
HGETALL cart:cust:101
# Output:
# 1) "LAP-APL-MBP16"
# 2) "2"
# 3) "APP-NIK-AF1-09"
# 4) "1"

# 5. Customer removes the sneakers
HDEL cart:cust:101 "APP-NIK-AF1-09"

# 6. Customer increments laptop quantity by 1 atomically
HINCRBY cart:cust:101 "LAP-APL-MBP16" 1
```

---

### 3.2 Use Case 2: Flash Sale Stock Decrement & Race Condition Elimination
During black-friday promotional events, thousands of concurrent requests hit the same product simultaneously. In PostgreSQL, `SELECT FOR UPDATE` can result in lock contention. In Redis, `DECR` is single-threaded and executes atomically in nanoseconds:

```redis
# Pre-warm Redis with initial stock before sale starts
SET stock:sku:LAP-APL-MBP16 50

# Atomic decrement during purchase attempt
DECR stock:sku:LAP-APL-MBP16
# Returns: 49 (Success, proceed to queue payment)

# When counter drops below zero:
DECR stock:sku:LAP-APL-MBP16
# Returns: -1 (Out of stock! Reject checkout immediately, revert counter)
INCR stock:sku:LAP-APL-MBP16
```

---

### 3.3 Use Case 3: Sliding-Window Log Rate Limiting
To prevent bot scalpers from scraping prices or flooding the checkout endpoint, Redis Sorted Sets (`ZSET`) enforce a sliding window rate limit (e.g., maximum 10 checkout attempts per 60 seconds per IP):

```redis
# Timestamp: 1773780000000 ms, Member: unique request ID
# Step 1: Remove requests older than (current_time - 60,000 ms)
ZREMRANGEBYSCORE ratelimit:192.168.1.50:checkout -inf 1773720000000

# Step 2: Add current request timestamp
ZADD ratelimit:192.168.1.50:checkout 1773780000000 "req_9981a"

# Step 3: Count total requests inside the active 60-second window
ZCARD ratelimit:192.168.1.50:checkout
# Output: 4 (Allow request if <= 10; otherwise abort with HTTP 429 Too Many Requests)

# Step 4: Refresh TTL
EXPIRE ratelimit:192.168.1.50:checkout 60
```

---

### 3.4 Use Case 4: Real-Time Trending Products Leaderboard
ShopEase displays a live "Trending Right Now" ranking on the homepage based on product detail page views:

```redis
# Increment product view score by 1 each time a page is viewed
ZINCRBY leaderboard:views:2026-03-15 1 "LAP-APL-MBP16"
ZINCRBY leaderboard:views:2026-03-15 1 "APP-NIK-AF1-09"
ZINCRBY leaderboard:views:2026-03-15 5 "HOM-NES-VERT-BLK"

# Retrieve Top 3 Trending Products (Highest to Lowest)
ZREVRANGE leaderboard:views:2026-03-15 0 2 WITHSCORES
# Output:
# 1) "HOM-NES-VERT-BLK"
# 2) "5"
# 3) "LAP-APL-MBP16"
# 4) "1"
# 5) "APP-NIK-AF1-09"
# 6) "1"
```

---

## 4. Eviction Policies & Memory Management

Because Redis stores data entirely in RAM, ShopEase configures a strict `maxmemory` cap (e.g., 16GB) paired with an intelligent eviction policy:
- **`volatile-lru`:** Evicts the least recently used keys among those with an expiration (`TTL`) set. This guarantees that temporary session keys and old carts are reclaimed before persistent cache data.
- **Persistence Configuration:** ShopEase runs **AOF (Append Only File) with `everysec` sync** combined with periodic RDB snapshots. This guarantees durability while maintaining over 80,000 operations per second.
