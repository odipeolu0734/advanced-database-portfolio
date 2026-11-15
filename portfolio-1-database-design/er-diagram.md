# ShopEase — Entity-Relationship Diagram

## Overview

This ER diagram models the complete data architecture for ShopEase, an online e-commerce platform. The diagram captures **18 entities** spanning customer management, product cataloguing, order processing, payment handling, shipping logistics, reviews, and inventory management.

### Cardinality Notation

| Symbol | Meaning |
|--------|---------|
| `\|\|` | Exactly one |
| `o\|` | Zero or one |
| `\|{` | One or more |
| `o{` | Zero or more |

---

## Entity-Relationship Diagram

```mermaid
erDiagram
    CUSTOMERS {
        INT customer_id PK
        VARCHAR first_name
        VARCHAR last_name
        VARCHAR email
        VARCHAR phone
        VARCHAR password_hash
        TIMESTAMP created_at
        TIMESTAMP updated_at
        BOOLEAN is_active
    }

    ADDRESSES {
        INT address_id PK
        INT customer_id FK
        VARCHAR address_type
        VARCHAR address_line1
        VARCHAR address_line2
        VARCHAR city
        VARCHAR state
        VARCHAR postal_code
        VARCHAR country
        BOOLEAN is_default
    }

    SELLERS {
        INT seller_id PK
        VARCHAR company_name
        VARCHAR contact_name
        VARCHAR email
        VARCHAR phone
        TEXT description
        DECIMAL rating
        VARCHAR status
        TIMESTAMP registered_at
        TIMESTAMP updated_at
    }

    CATEGORIES {
        INT category_id PK
        INT parent_category_id FK
        VARCHAR category_name
        TEXT description
        VARCHAR slug
        BOOLEAN is_active
        INT sort_order
    }

    PRODUCTS {
        INT product_id PK
        INT seller_id FK
        INT category_id FK
        VARCHAR product_name
        TEXT description
        DECIMAL price
        DECIMAL discount_percentage
        VARCHAR sku
        DECIMAL weight
        VARCHAR status
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    PRODUCT_IMAGES {
        INT image_id PK
        INT product_id FK
        VARCHAR image_url
        VARCHAR alt_text
        BOOLEAN is_primary
        INT sort_order
    }

    INVENTORY {
        INT inventory_id PK
        INT product_id FK
        INT quantity_in_stock
        INT reorder_level
        INT reorder_quantity
        VARCHAR warehouse_location
        TIMESTAMP last_restocked
    }

    SHOPPING_CART {
        INT cart_id PK
        INT customer_id FK
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    CART_ITEMS {
        INT cart_item_id PK
        INT cart_id FK
        INT product_id FK
        INT quantity
        TIMESTAMP added_at
    }

    ORDERS {
        INT order_id PK
        INT customer_id FK
        INT shipping_address_id FK
        INT billing_address_id FK
        VARCHAR order_status
        DECIMAL subtotal
        DECIMAL tax_amount
        DECIMAL shipping_cost
        DECIMAL total_amount
        TEXT notes
        TIMESTAMP order_date
        TIMESTAMP updated_at
    }

    ORDER_ITEMS {
        INT order_item_id PK
        INT order_id FK
        INT product_id FK
        INT seller_id FK
        INT quantity
        DECIMAL unit_price
        DECIMAL discount_amount
        DECIMAL total_price
    }

    PAYMENTS {
        INT payment_id PK
        INT order_id FK
        VARCHAR payment_method
        VARCHAR transaction_id
        DECIMAL amount
        VARCHAR currency
        VARCHAR status
        TIMESTAMP payment_date
        TEXT gateway_response
    }

    SHIPPING {
        INT shipping_id PK
        INT order_id FK
        VARCHAR carrier
        VARCHAR tracking_number
        VARCHAR shipping_status
        TIMESTAMP shipped_date
        TIMESTAMP estimated_delivery
        TIMESTAMP actual_delivery
        DECIMAL shipping_cost
    }

    REVIEWS {
        INT review_id PK
        INT product_id FK
        INT customer_id FK
        INT order_id FK
        INT rating
        VARCHAR title
        TEXT comment
        BOOLEAN is_verified
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    WISHLISTS {
        INT wishlist_id PK
        INT customer_id FK
        VARCHAR wishlist_name
        BOOLEAN is_public
        TIMESTAMP created_at
    }

    WISHLIST_ITEMS {
        INT wishlist_item_id PK
        INT wishlist_id FK
        INT product_id FK
        TIMESTAMP added_at
    }

    RETURN_REQUESTS {
        INT return_id PK
        INT order_item_id FK
        INT customer_id FK
        VARCHAR reason
        TEXT description
        VARCHAR status
        DECIMAL refund_amount
        TIMESTAMP requested_at
        TIMESTAMP resolved_at
    }

    COUPONS {
        INT coupon_id PK
        VARCHAR code
        VARCHAR discount_type
        DECIMAL discount_value
        DECIMAL min_order_amount
        TIMESTAMP valid_from
        TIMESTAMP valid_until
        INT usage_limit
        INT times_used
        BOOLEAN is_active
    }

    %% ===== RELATIONSHIPS =====

    %% Customer relationships
    CUSTOMERS ||--o{ ADDRESSES : "has"
    CUSTOMERS ||--o| SHOPPING_CART : "owns"
    CUSTOMERS ||--o{ ORDERS : "places"
    CUSTOMERS ||--o{ REVIEWS : "writes"
    CUSTOMERS ||--o{ WISHLISTS : "creates"
    CUSTOMERS ||--o{ RETURN_REQUESTS : "submits"

    %% Category self-reference (parent-child hierarchy)
    CATEGORIES ||--o{ CATEGORIES : "has subcategories"

    %% Seller relationships
    SELLERS ||--o{ PRODUCTS : "sells"

    %% Product relationships
    CATEGORIES ||--o{ PRODUCTS : "contains"
    PRODUCTS ||--o{ PRODUCT_IMAGES : "has"
    PRODUCTS ||--|| INVENTORY : "tracked in"
    PRODUCTS ||--o{ CART_ITEMS : "added to"
    PRODUCTS ||--o{ ORDER_ITEMS : "ordered as"
    PRODUCTS ||--o{ REVIEWS : "reviewed in"
    PRODUCTS ||--o{ WISHLIST_ITEMS : "wishlisted in"

    %% Shopping cart relationships
    SHOPPING_CART ||--o{ CART_ITEMS : "contains"

    %% Order relationships
    ORDERS ||--|{ ORDER_ITEMS : "contains"
    ORDERS ||--o| PAYMENTS : "paid via"
    ORDERS ||--o| SHIPPING : "shipped via"
    ADDRESSES ||--o{ ORDERS : "ships to"

    %% Order item relationships
    ORDER_ITEMS ||--o| RETURN_REQUESTS : "returned via"
    SELLERS ||--o{ ORDER_ITEMS : "fulfils"

    %% Wishlist relationships
    WISHLISTS ||--o{ WISHLIST_ITEMS : "contains"
```

---

## Relationship Summary

### One-to-Many (1:M) Relationships

| Parent Entity | Child Entity | Description |
|---------------|-------------|-------------|
| CUSTOMERS | ADDRESSES | A customer can have multiple addresses (home, work, etc.) |
| CUSTOMERS | ORDERS | A customer can place multiple orders over time |
| CUSTOMERS | REVIEWS | A customer can write reviews for multiple products |
| CUSTOMERS | WISHLISTS | A customer can maintain multiple wishlists |
| CUSTOMERS | RETURN_REQUESTS | A customer can submit multiple return requests |
| SELLERS | PRODUCTS | A seller/vendor can list multiple products |
| SELLERS | ORDER_ITEMS | A seller fulfils multiple order line items |
| CATEGORIES | PRODUCTS | A category contains multiple products |
| CATEGORIES | CATEGORIES | A category can have multiple subcategories (self-referencing) |
| PRODUCTS | PRODUCT_IMAGES | A product can have multiple images/gallery photos |
| PRODUCTS | CART_ITEMS | A product can appear in multiple carts |
| PRODUCTS | ORDER_ITEMS | A product can be part of multiple orders |
| PRODUCTS | REVIEWS | A product can receive multiple reviews |
| PRODUCTS | WISHLIST_ITEMS | A product can appear in multiple wishlists |
| SHOPPING_CART | CART_ITEMS | A cart contains multiple items |
| ORDERS | ORDER_ITEMS | An order contains multiple line items |
| WISHLISTS | WISHLIST_ITEMS | A wishlist contains multiple items |
| ADDRESSES | ORDERS | An address can be used for multiple orders |

### One-to-One (1:1) Relationships

| Entity A | Entity B | Description |
|----------|----------|-------------|
| CUSTOMERS | SHOPPING_CART | Each customer has at most one active cart |
| PRODUCTS | INVENTORY | Each product has exactly one inventory record |
| ORDERS | PAYMENTS | Each order has at most one payment record |
| ORDERS | SHIPPING | Each order has at most one shipping record |
| ORDER_ITEMS | RETURN_REQUESTS | Each order item can have at most one return request |

### Many-to-Many (M:N) Relationships (via Junction Tables)

| Entity A | Entity B | Junction Table | Description |
|----------|----------|---------------|-------------|
| SHOPPING_CART | PRODUCTS | CART_ITEMS | Products added to shopping carts |
| ORDERS | PRODUCTS | ORDER_ITEMS | Products included in orders |
| WISHLISTS | PRODUCTS | WISHLIST_ITEMS | Products saved to wishlists |

---

## Design Decisions

1. **Self-referencing Categories**: The `CATEGORIES` table uses a `parent_category_id` foreign key to support unlimited nesting depth (e.g., Electronics → Phones → Smartphones).

2. **Separate Address Table**: Addresses are normalised into their own table to support multiple addresses per customer and to allow both shipping and billing addresses on orders.

3. **Junction Tables for M:N**: `CART_ITEMS`, `ORDER_ITEMS`, and `WISHLIST_ITEMS` serve as junction/associative tables, each carrying additional attributes (quantity, price, timestamps).

4. **Seller on ORDER_ITEMS**: The `seller_id` on `ORDER_ITEMS` (rather than only on `ORDERS`) supports marketplace-style multi-seller orders where different items are fulfilled by different sellers.

5. **Coupons Entity**: Included to model promotional discounts with usage limits, validity windows, and both percentage and fixed-amount discount types.

6. **Return Requests at Item Level**: Returns are modelled at the `ORDER_ITEMS` level (not the order level) to support partial returns where only some items in an order are returned.
