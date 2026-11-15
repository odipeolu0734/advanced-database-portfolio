# Portfolio 1: Database Design and Modelling

**Course:** MIT 8103 Advanced Database Systems  
**Session:** 2026/2027 Academic Session  
**Case Study:** ShopEase E-Commerce Platform  
**Target RDBMS:** PostgreSQL 15+  
**Component Mark:** 7 Marks  

---

## 1. Case Study Overview & System Context

**ShopEase** is a multi-vendor online retail platform designed to support commercial transactions across electronics, apparel, homeware, and lifestyle goods. The platform interfaces four primary user groups:
1. **Customers:** Browse/search products, manage wishlists, maintain carts, execute payments, track shipments, and post verified reviews.
2. **Sellers (Vendors):** Manage product catalogs, monitor inventory levels, fulfill line items, and inspect ratings.
3. **Delivery Personnel & Carriers:** Update package transit milestones, tracking statuses, and delivery confirmations.
4. **System Administrators:** Oversee platform integrity, moderate disputes/return requests, manage global coupon campaigns, and audit system transactions.

### Key Operations Supported
- **High-throughput Catalog Browsing:** Fast hierarchical category tree traversal and multi-attribute product lookups.
- **Transactional Order Placement:** Atomic reservation of inventory, order header and item generation, payment capture, and fulfillment initialization.
- **Reverse Logistics:** Granular line-item return requests linked directly to customer and order history.
- **Customer Lifecycle Management:** Unified address books, cart persistence across sessions, and verified purchase reviews.

---

## 2. Entity-Relationship (ER) Architecture

The entity-relationship architecture consists of **18 relational entities** structured to balance high data integrity (3NF/BCNF) with operational throughput.

### Summary of Relational Entities
| Entity | Type | Purpose | Primary Key | Key Foreign References |
|---|---|---|---|---|
| `customers` | Strong Entity | Stores identity, authentication, and status | `customer_id` | None |
| `addresses` | Weak Entity | Customer shipping and billing locations | `address_id` | `customer_id` |
| `sellers` | Strong Entity | Marketplace merchant profiles and ratings | `seller_id` | None |
| `categories` | Strong / Recursive | Hierarchical taxonomy (self-referencing) | `category_id` | `parent_category_id` |
| `products` | Strong Entity | Master product SKU definitions and prices | `product_id` | `seller_id`, `category_id` |
| `product_images` | Weak Entity | Media assets for catalog presentation | `image_id` | `product_id` |
| `inventory` | Dependent | Current stock counts and warehouse zones | `inventory_id` | `product_id` (1:1 UNIQUE) |
| `shopping_cart` | Dependent | Active shopping session per customer | `cart_id` | `customer_id` (1:1 UNIQUE) |
| `cart_items` | Junction Entity | Products staged inside an active cart | `cart_item_id` | `cart_id`, `product_id` |
| `orders` | Transaction Header | Master order record and financial summary | `order_id` | `customer_id`, `shipping_address_id`, `billing_address_id` |
| `order_items` | Transaction Line | Granular purchase details and unit price snapshots | `order_item_id` | `order_id`, `product_id`, `seller_id` |
| `payments` | Financial Event | Gateway payment transaction records | `payment_id` | `order_id` |
| `shipping` | Logistics Event | Carrier tracking and transit milestones | `shipping_id` | `order_id` |
| `reviews` | Feedback Entity | Customer product evaluations and ratings | `review_id` | `product_id`, `customer_id`, `order_id` |
| `wishlists` | User Collection | Named bookmark collections per customer | `wishlist_id` | `customer_id` |
| `wishlist_items` | Junction Entity | Products saved in a wishlist | `wishlist_item_id` | `wishlist_id`, `product_id` |
| `return_requests` | Workflow Entity | Reverse logistics claim per order item | `return_id` | `order_item_id`, `customer_id` |
| `coupons` | Promotion Entity | Discount rules, validity intervals, quotas | `coupon_id` | None |

For the complete interactive diagram, review [er-diagram.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/er-diagram.md).

---

## 3. Relational Schema & Structural Integrity

The physical implementation is codified in [schema.sql](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/schema.sql) under the dedicated PostgreSQL schema `shopease`.

### Key Design Principles & Constraints
1. **Referential Integrity Actions:**
   - **`ON DELETE CASCADE`** is applied to strictly owned child entities: `addresses`, `product_images`, `inventory`, `shopping_cart`, `cart_items`, `wishlists`, and `wishlist_items`.
   - **`ON DELETE RESTRICT`** safeguards historical business transactions: `orders` referencing `customers` and `addresses`, `order_items` referencing `products` and `sellers`, and `return_requests` referencing `order_items`.
   - **`ON DELETE SET NULL`** is utilized for self-referential parent categories (`categories.parent_category_id`) and optional reviews linked to historical orders.

2. **Domain & Business Rule Constraints:**
   - Monetary attributes (`price`, `subtotal`, `total_amount`, `unit_price`, `discount_amount`) enforce `NUMERIC(12, 2)` with `CHECK (value >= 0)` to eliminate floating-point rounding errors.
   - Percentage fields enforce bounds: `CHECK (discount_percentage >= 0 AND discount_percentage <= 100)`.
   - Quantitative attributes (`quantity_in_stock`, `reorder_level`) enforce non-negativity; transaction line item quantities enforce strictly positive quantities: `CHECK (quantity > 0)`.
   - State lifecycles are constrained via enumerated `CHECK` constraints (e.g., `order_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')`).

3. **Data Immutability vs. Normalisation in Historical Snapshots:**
   - Note that `order_items` stores historical copies of `unit_price` and `discount_amount`. While this appears to store duplicate product data, it represents a temporal snapshot requirement in transactional commerce. If a product's catalog price changes tomorrow, historical orders must reflect the exact price charged at purchase time.

---

## 4. Normalisation Summary (1NF → BCNF)

The schema was systematically refined from an unnormalised business log to Boyce-Codd Normal Form (BCNF). A summary of each transition:

- **First Normal Form (1NF):** Eliminated repeating attribute groups (e.g., multiple order items stored as comma-separated values in an order record) and ensured atomic domain types for all columns.
- **Second Normal Form (2NF):** Removed partial functional dependencies by establishing synthetic surrogate keys (`order_item_id`, `cart_item_id`, `wishlist_item_id`) so that every non-key attribute depends entirely on the whole primary key.
- **Third Normal Form (3NF):** Extracted transitive functional dependencies (e.g., Customer $\rightarrow$ Address $\rightarrow$ City/PostalCode; Product $\rightarrow$ Seller $\rightarrow$ SellerEmail) into discrete relational tables (`addresses`, `sellers`, `categories`).
- **Boyce-Codd Normal Form (BCNF):** Verified that for every functional dependency $X \rightarrow Y$ in all relations, the determinant $X$ is a superkey. Where composite candidate keys exist (such as `cart_id + product_id` or `coupon_code`), surrogate primary keys are paired with strict `UNIQUE` constraints to preserve dependency satisfaction without anomalies.

For exhaustive proofs, dependency diagrams, and decomposition walkthroughs, inspect [normalisation.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/normalisation.md).

---

## 5. Artifact Directory & Verification Guide

| File | Description | Link |
|---|---|---|
| `schema.sql` | Complete DDL script (tables, constraints, indices, comments) | [schema.sql](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/schema.sql) |
| `seed-data.sql` | Comprehensive mock dataset covering all 18 tables | [seed-data.sql](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/seed-data.sql) |
| `er-diagram.md` | Mermaid Crow's Foot ER diagram documenting all relationships | [er-diagram.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/er-diagram.md) |
| `normalisation.md` | Full theoretical decomposition from UNF to BCNF | [normalisation.md](file:///c:/Users/Pc/Desktop/test/advanced-database-portfolio/portfolio-1-database-design/normalisation.md) |

### Setup Script Execution
To instantiate and seed the ShopEase database in PostgreSQL:
```bash
# 1. Connect and create schema/tables
psql -U postgres -d postgres -f portfolio-1-database-design/schema.sql

# 2. Populate sample dataset
psql -U postgres -d postgres -f portfolio-1-database-design/seed-data.sql
```
