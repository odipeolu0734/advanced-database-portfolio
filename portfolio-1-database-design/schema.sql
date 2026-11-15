-- ============================================================================
-- ShopEase E-Commerce Platform — Database Schema (PostgreSQL)
-- ============================================================================
-- Description : Complete DDL script for the ShopEase online retail platform.
-- Database    : PostgreSQL 15+
-- Schema      : shopease
-- Author      : Portfolio 1 — Database Design and Modelling
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Schema Creation
-- ----------------------------------------------------------------------------
DROP SCHEMA IF EXISTS shopease CASCADE;
CREATE SCHEMA shopease;

SET search_path TO shopease;

-- ============================================================================
-- 1. CUSTOMERS
-- ============================================================================
CREATE TABLE shopease.customers (
    customer_id     SERIAL          PRIMARY KEY,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    phone           VARCHAR(20),
    password_hash   VARCHAR(255)    NOT NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE shopease.customers IS 'Registered customers of the ShopEase platform.';

-- ============================================================================
-- 2. ADDRESSES
-- ============================================================================
CREATE TABLE shopease.addresses (
    address_id      SERIAL          PRIMARY KEY,
    customer_id     INT             NOT NULL REFERENCES shopease.customers(customer_id) ON DELETE CASCADE,
    address_type    VARCHAR(20)     NOT NULL CHECK (address_type IN ('shipping', 'billing', 'both')),
    address_line1   VARCHAR(255)    NOT NULL,
    address_line2   VARCHAR(255),
    city            VARCHAR(100)    NOT NULL,
    state           VARCHAR(100),
    postal_code     VARCHAR(20)     NOT NULL,
    country         VARCHAR(100)    NOT NULL DEFAULT 'United Kingdom',
    is_default      BOOLEAN         NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE shopease.addresses IS 'Customer shipping and billing addresses.';

-- ============================================================================
-- 3. SELLERS (Vendors / Marketplace Partners)
-- ============================================================================
CREATE TABLE shopease.sellers (
    seller_id       SERIAL          PRIMARY KEY,
    company_name    VARCHAR(200)    NOT NULL UNIQUE,
    contact_name    VARCHAR(200)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    phone           VARCHAR(20),
    description     TEXT,
    rating          NUMERIC(3, 2)   DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5),
    status          VARCHAR(20)     NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'pending')),
    registered_at   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE shopease.sellers IS 'Sellers/vendors who list products on the ShopEase marketplace.';

-- ============================================================================
-- 4. CATEGORIES (Self-referencing hierarchy)
-- ============================================================================
CREATE TABLE shopease.categories (
    category_id         SERIAL          PRIMARY KEY,
    parent_category_id  INT             REFERENCES shopease.categories(category_id) ON DELETE SET NULL,
    category_name       VARCHAR(100)    NOT NULL,
    description         TEXT,
    slug                VARCHAR(120)    NOT NULL UNIQUE,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    sort_order          INT             NOT NULL DEFAULT 0
);

COMMENT ON TABLE shopease.categories IS 'Hierarchical product categories (supports unlimited nesting via parent_category_id).';

-- ============================================================================
-- 5. PRODUCTS
-- ============================================================================
CREATE TABLE shopease.products (
    product_id          SERIAL          PRIMARY KEY,
    seller_id           INT             NOT NULL REFERENCES shopease.sellers(seller_id) ON DELETE RESTRICT,
    category_id         INT             NOT NULL REFERENCES shopease.categories(category_id) ON DELETE RESTRICT,
    product_name        VARCHAR(300)    NOT NULL,
    description         TEXT,
    price               NUMERIC(12, 2)  NOT NULL CHECK (price >= 0),
    discount_percentage NUMERIC(5, 2)   NOT NULL DEFAULT 0.00 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    sku                 VARCHAR(50)     NOT NULL UNIQUE,
    weight              NUMERIC(8, 2)   CHECK (weight >= 0),
    status              VARCHAR(20)     NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'draft', 'out_of_stock')),
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE shopease.products IS 'Products listed for sale on the ShopEase platform.';

-- ============================================================================
-- 6. PRODUCT_IMAGES
-- ============================================================================
CREATE TABLE shopease.product_images (
    image_id    SERIAL          PRIMARY KEY,
    product_id  INT             NOT NULL REFERENCES shopease.products(product_id) ON DELETE CASCADE,
    image_url   VARCHAR(500)    NOT NULL,
    alt_text    VARCHAR(255),
    is_primary  BOOLEAN         NOT NULL DEFAULT FALSE,
    sort_order  INT             NOT NULL DEFAULT 0
);

COMMENT ON TABLE shopease.product_images IS 'Gallery images associated with products.';

-- ============================================================================
-- 7. INVENTORY
-- ============================================================================
CREATE TABLE shopease.inventory (
    inventory_id        SERIAL          PRIMARY KEY,
    product_id          INT             NOT NULL UNIQUE REFERENCES shopease.products(product_id) ON DELETE CASCADE,
    quantity_in_stock   INT             NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
    reorder_level       INT             NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    reorder_quantity    INT             NOT NULL DEFAULT 50 CHECK (reorder_quantity > 0),
    warehouse_location  VARCHAR(100),
    last_restocked      TIMESTAMP
);

COMMENT ON TABLE shopease.inventory IS 'Current stock levels and reorder thresholds for each product.';

-- ============================================================================
-- 8. SHOPPING_CART
-- ============================================================================
CREATE TABLE shopease.shopping_cart (
    cart_id     SERIAL      PRIMARY KEY,
    customer_id INT         NOT NULL UNIQUE REFERENCES shopease.customers(customer_id) ON DELETE CASCADE,
    created_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE shopease.shopping_cart IS 'Active shopping cart for each customer (one cart per customer).';

-- ============================================================================
-- 9. CART_ITEMS
-- ============================================================================
CREATE TABLE shopease.cart_items (
    cart_item_id    SERIAL      PRIMARY KEY,
    cart_id         INT         NOT NULL REFERENCES shopease.shopping_cart(cart_id) ON DELETE CASCADE,
    product_id      INT         NOT NULL REFERENCES shopease.products(product_id) ON DELETE CASCADE,
    quantity        INT         NOT NULL DEFAULT 1 CHECK (quantity > 0),
    added_at        TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cart_id, product_id)
);

COMMENT ON TABLE shopease.cart_items IS 'Individual items in a customer''s shopping cart.';

-- ============================================================================
-- 10. ORDERS
-- ============================================================================
CREATE TABLE shopease.orders (
    order_id            SERIAL          PRIMARY KEY,
    customer_id         INT             NOT NULL REFERENCES shopease.customers(customer_id) ON DELETE RESTRICT,
    shipping_address_id INT             NOT NULL REFERENCES shopease.addresses(address_id) ON DELETE RESTRICT,
    billing_address_id  INT             NOT NULL REFERENCES shopease.addresses(address_id) ON DELETE RESTRICT,
    order_status        VARCHAR(30)     NOT NULL DEFAULT 'pending'
                            CHECK (order_status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    subtotal            NUMERIC(12, 2)  NOT NULL CHECK (subtotal >= 0),
    tax_amount          NUMERIC(12, 2)  NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    shipping_cost       NUMERIC(10, 2)  NOT NULL DEFAULT 0.00 CHECK (shipping_cost >= 0),
    total_amount        NUMERIC(12, 2)  NOT NULL CHECK (total_amount >= 0),
    notes               TEXT,
    order_date          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE shopease.orders IS 'Customer orders. Each order references shipping and billing addresses.';

-- ============================================================================
-- 11. ORDER_ITEMS
-- ============================================================================
CREATE TABLE shopease.order_items (
    order_item_id   SERIAL          PRIMARY KEY,
    order_id        INT             NOT NULL REFERENCES shopease.orders(order_id) ON DELETE CASCADE,
    product_id      INT             NOT NULL REFERENCES shopease.products(product_id) ON DELETE RESTRICT,
    seller_id       INT             NOT NULL REFERENCES shopease.sellers(seller_id) ON DELETE RESTRICT,
    quantity        INT             NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(12, 2)  NOT NULL CHECK (unit_price >= 0),
    discount_amount NUMERIC(12, 2)  NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    total_price     NUMERIC(12, 2)  NOT NULL CHECK (total_price >= 0)
);

COMMENT ON TABLE shopease.order_items IS 'Individual line items within an order, linking products to orders.';

-- ============================================================================
-- 12. PAYMENTS
-- ============================================================================
CREATE TABLE shopease.payments (
    payment_id      SERIAL          PRIMARY KEY,
    order_id        INT             NOT NULL REFERENCES shopease.orders(order_id) ON DELETE RESTRICT,
    payment_method  VARCHAR(30)     NOT NULL
                        CHECK (payment_method IN ('credit_card', 'debit_card', 'paypal', 'bank_transfer', 'apple_pay', 'google_pay')),
    transaction_id  VARCHAR(100)    UNIQUE,
    amount          NUMERIC(12, 2)  NOT NULL CHECK (amount > 0),
    currency        VARCHAR(3)      NOT NULL DEFAULT 'GBP',
    status          VARCHAR(20)     NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'completed', 'failed', 'refunded', 'partially_refunded')),
    payment_date    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    gateway_response TEXT
);

COMMENT ON TABLE shopease.payments IS 'Payment records for orders, supporting multiple payment methods.';

-- ============================================================================
-- 13. SHIPPING
-- ============================================================================
CREATE TABLE shopease.shipping (
    shipping_id         SERIAL          PRIMARY KEY,
    order_id            INT             NOT NULL REFERENCES shopease.orders(order_id) ON DELETE CASCADE,
    carrier             VARCHAR(100)    NOT NULL,
    tracking_number     VARCHAR(100)    UNIQUE,
    shipping_status     VARCHAR(30)     NOT NULL DEFAULT 'pending'
                            CHECK (shipping_status IN ('pending', 'processing', 'shipped', 'in_transit', 'out_for_delivery', 'delivered', 'failed')),
    shipped_date        TIMESTAMP,
    estimated_delivery  TIMESTAMP,
    actual_delivery     TIMESTAMP,
    shipping_cost       NUMERIC(10, 2)  NOT NULL DEFAULT 0.00 CHECK (shipping_cost >= 0)
);

COMMENT ON TABLE shopease.shipping IS 'Shipping and delivery tracking for orders.';

-- ============================================================================
-- 14. REVIEWS
-- ============================================================================
CREATE TABLE shopease.reviews (
    review_id   SERIAL          PRIMARY KEY,
    product_id  INT             NOT NULL REFERENCES shopease.products(product_id) ON DELETE CASCADE,
    customer_id INT             NOT NULL REFERENCES shopease.customers(customer_id) ON DELETE CASCADE,
    order_id    INT             REFERENCES shopease.orders(order_id) ON DELETE SET NULL,
    rating      INT             NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title       VARCHAR(200),
    comment     TEXT,
    is_verified BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, customer_id, order_id)
);

COMMENT ON TABLE shopease.reviews IS 'Customer reviews and ratings for products.';

-- ============================================================================
-- 15. WISHLISTS
-- ============================================================================
CREATE TABLE shopease.wishlists (
    wishlist_id     SERIAL          PRIMARY KEY,
    customer_id     INT             NOT NULL REFERENCES shopease.customers(customer_id) ON DELETE CASCADE,
    wishlist_name   VARCHAR(100)    NOT NULL DEFAULT 'My Wishlist',
    is_public       BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE shopease.wishlists IS 'Named wishlists that customers can create and optionally share publicly.';

-- ============================================================================
-- 16. WISHLIST_ITEMS
-- ============================================================================
CREATE TABLE shopease.wishlist_items (
    wishlist_item_id    SERIAL      PRIMARY KEY,
    wishlist_id         INT         NOT NULL REFERENCES shopease.wishlists(wishlist_id) ON DELETE CASCADE,
    product_id          INT         NOT NULL REFERENCES shopease.products(product_id) ON DELETE CASCADE,
    added_at            TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (wishlist_id, product_id)
);

COMMENT ON TABLE shopease.wishlist_items IS 'Products saved to a customer''s wishlist.';

-- ============================================================================
-- 17. RETURN_REQUESTS
-- ============================================================================
CREATE TABLE shopease.return_requests (
    return_id       SERIAL          PRIMARY KEY,
    order_item_id   INT             NOT NULL REFERENCES shopease.order_items(order_item_id) ON DELETE RESTRICT,
    customer_id     INT             NOT NULL REFERENCES shopease.customers(customer_id) ON DELETE RESTRICT,
    reason          VARCHAR(50)     NOT NULL
                        CHECK (reason IN ('defective', 'wrong_item', 'not_as_described', 'changed_mind', 'damaged_in_transit', 'other')),
    description     TEXT,
    status          VARCHAR(20)     NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'approved', 'rejected', 'refunded', 'completed')),
    refund_amount   NUMERIC(12, 2)  CHECK (refund_amount >= 0),
    requested_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at     TIMESTAMP
);

COMMENT ON TABLE shopease.return_requests IS 'Return and refund requests at the order-item level.';

-- ============================================================================
-- 18. COUPONS
-- ============================================================================
CREATE TABLE shopease.coupons (
    coupon_id       SERIAL          PRIMARY KEY,
    code            VARCHAR(50)     NOT NULL UNIQUE,
    discount_type   VARCHAR(20)     NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount')),
    discount_value  NUMERIC(10, 2)  NOT NULL CHECK (discount_value > 0),
    min_order_amount NUMERIC(12, 2) DEFAULT 0.00 CHECK (min_order_amount >= 0),
    valid_from      TIMESTAMP       NOT NULL,
    valid_until     TIMESTAMP       NOT NULL,
    usage_limit     INT             CHECK (usage_limit > 0),
    times_used      INT             NOT NULL DEFAULT 0 CHECK (times_used >= 0),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    CHECK (valid_until > valid_from)
);

COMMENT ON TABLE shopease.coupons IS 'Promotional discount coupons with validity windows and usage limits.';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Customers
CREATE INDEX idx_customers_email       ON shopease.customers (email);
CREATE INDEX idx_customers_last_name   ON shopease.customers (last_name);

-- Addresses
CREATE INDEX idx_addresses_customer_id ON shopease.addresses (customer_id);

-- Categories
CREATE INDEX idx_categories_parent     ON shopease.categories (parent_category_id);
CREATE INDEX idx_categories_slug       ON shopease.categories (slug);

-- Products
CREATE INDEX idx_products_seller_id    ON shopease.products (seller_id);
CREATE INDEX idx_products_category_id  ON shopease.products (category_id);
CREATE INDEX idx_products_sku          ON shopease.products (sku);
CREATE INDEX idx_products_status       ON shopease.products (status);
CREATE INDEX idx_products_name         ON shopease.products (product_name);

-- Product Images
CREATE INDEX idx_product_images_product_id ON shopease.product_images (product_id);

-- Inventory
CREATE INDEX idx_inventory_product_id  ON shopease.inventory (product_id);

-- Shopping Cart
CREATE INDEX idx_shopping_cart_customer ON shopease.shopping_cart (customer_id);

-- Cart Items
CREATE INDEX idx_cart_items_cart_id     ON shopease.cart_items (cart_id);
CREATE INDEX idx_cart_items_product_id  ON shopease.cart_items (product_id);

-- Orders
CREATE INDEX idx_orders_customer_id    ON shopease.orders (customer_id);
CREATE INDEX idx_orders_status         ON shopease.orders (order_status);
CREATE INDEX idx_orders_order_date     ON shopease.orders (order_date);
CREATE INDEX idx_orders_shipping_addr  ON shopease.orders (shipping_address_id);
CREATE INDEX idx_orders_billing_addr   ON shopease.orders (billing_address_id);

-- Order Items
CREATE INDEX idx_order_items_order_id  ON shopease.order_items (order_id);
CREATE INDEX idx_order_items_product   ON shopease.order_items (product_id);
CREATE INDEX idx_order_items_seller    ON shopease.order_items (seller_id);

-- Payments
CREATE INDEX idx_payments_order_id     ON shopease.payments (order_id);
CREATE INDEX idx_payments_status       ON shopease.payments (status);
CREATE INDEX idx_payments_txn_id       ON shopease.payments (transaction_id);

-- Shipping
CREATE INDEX idx_shipping_order_id     ON shopease.shipping (order_id);
CREATE INDEX idx_shipping_status       ON shopease.shipping (shipping_status);
CREATE INDEX idx_shipping_tracking     ON shopease.shipping (tracking_number);

-- Reviews
CREATE INDEX idx_reviews_product_id    ON shopease.reviews (product_id);
CREATE INDEX idx_reviews_customer_id   ON shopease.reviews (customer_id);
CREATE INDEX idx_reviews_rating        ON shopease.reviews (rating);

-- Wishlists
CREATE INDEX idx_wishlists_customer_id ON shopease.wishlists (customer_id);

-- Wishlist Items
CREATE INDEX idx_wishlist_items_wishlist ON shopease.wishlist_items (wishlist_id);
CREATE INDEX idx_wishlist_items_product ON shopease.wishlist_items (product_id);

-- Return Requests
CREATE INDEX idx_return_requests_order_item ON shopease.return_requests (order_item_id);
CREATE INDEX idx_return_requests_customer   ON shopease.return_requests (customer_id);
CREATE INDEX idx_return_requests_status     ON shopease.return_requests (status);

-- Coupons
CREATE INDEX idx_coupons_code          ON shopease.coupons (code);
CREATE INDEX idx_coupons_valid_dates   ON shopease.coupons (valid_from, valid_until);

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
