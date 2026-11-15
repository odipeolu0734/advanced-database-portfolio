-- ============================================================================
-- ShopEase E-Commerce Platform — Seed Data
-- ============================================================================
-- Populates all 18 tables with realistic sample data.
-- Run AFTER schema.sql.
-- ============================================================================

SET search_path TO shopease;

-- ============================================================================
-- 1. CUSTOMERS (15 rows)
-- ============================================================================
INSERT INTO shopease.customers (first_name, last_name, email, phone, password_hash) VALUES
('Alice',   'Smith',      'alice.smith@email.com',       '+44-7700-100001', '$2b$12$LJ3m5ZQsJXxPh0Z1J5gRVeEzS0sA1LKqS3zYb7dLxWkHqOzL8aI.K'),
('Bob',     'Johnson',    'bob.johnson@email.com',       '+44-7700-100002', '$2b$12$Wf8hJx5N6cY3oVzQ7TgRX.4pP3dL5sK2nF7mA1bGcEiU0hR9vWyJO'),
('Claire',  'Williams',   'claire.williams@email.com',   '+44-7700-100003', '$2b$12$kG8pZ5xQ3rT7wE1yU6nBv.9jJ2fH4dS0mL3oA8iWcKqNx5hR7tYeM'),
('David',   'Brown',      'david.brown@email.com',       '+44-7700-100004', '$2b$12$pL5nR8wT3xQ7oE1yU6kBv.4mJ2fH9dS0gA3iWcKqNx5hR7tYeZjG'),
('Emma',    'Taylor',     'emma.taylor@email.com',       '+44-7700-100005', '$2b$12$qM6oS9xU4yR8pF2zV7lCw.5nK3gI0eT1hB4jXdLrOy6iS8uZfAkH'),
('Frank',   'Davies',     'frank.davies@email.com',      '+44-7700-100006', '$2b$12$rN7pT0yV5zS9qG3aW8mDx.6oL4hJ1fU2iC5kYeMs Py7jT9vAgBlI'),
('Grace',   'Evans',      'grace.evans@email.com',       '+44-7700-100007', '$2b$12$sO8qU1zW6aT0rH4bX9nEy.7pM5iK2gV3jD6lZfNtQz8kU0wBhCmJ'),
('Henry',   'Wilson',     'henry.wilson@email.com',      '+44-7700-100008', '$2b$12$tP9rV2aX7bU1sI5cY0oFz.8qN6jL3hW4kE7mAgOuRa9lV1xCiDnK'),
('Isabel',  'Thomas',     'isabel.thomas@email.com',     '+44-7700-100009', '$2b$12$uQ0sW3bY8cV2tJ6dZ1pGa.9rO7kM4iX5lF8nBhPvSb0mW2yDjEoL'),
('James',   'Roberts',    'james.roberts@email.com',     '+44-7700-100010', '$2b$12$vR1tX4cZ9dW3uK7eA2qHb.0sP8lN5jY6mG9oCiQwTc1nX3zEkFpM'),
('Karen',   'Hughes',     'karen.hughes@email.com',      '+44-7700-100011', '$2b$12$wS2uY5dA0eX4vL8fB3rIc.1tQ9mO6kZ7nH0pDjRxUd2oY4aFlGqN'),
('Liam',    'Edwards',    'liam.edwards@email.com',      '+44-7700-100012', '$2b$12$xT3vZ6eB1fY5wM9gC4sJd.2uR0nP7lA8oI1qEkSyVe3pZ5bGmHrO'),
('Mia',     'Green',      'mia.green@email.com',         '+44-7700-100013', '$2b$12$yU4wA7fC2gZ6xN0hD5tKe.3vS1oQ8mB9pJ2rFlTzWf4qA6cHnIsP'),
('Nathan',  'Clark',      'nathan.clark@email.com',      '+44-7700-100014', '$2b$12$zV5xB8gD3hA7yO1iE6uLf.4wT2pR9nC0qK3sGmUaXg5rB7dIoJtQ'),
('Olivia',  'Walker',     'olivia.walker@email.com',     '+44-7700-100015', '$2b$12$aW6yC9hE4iB8zP2jF7vMg.5xU3qS0oD1rL4tHnVbYh6sC8eJpKuR');

-- ============================================================================
-- 2. ADDRESSES (20 rows)
-- ============================================================================
INSERT INTO shopease.addresses (customer_id, address_type, address_line1, address_line2, city, state, postal_code, country, is_default) VALUES
(1,  'both',     '10 Oak Street',        'Flat 3A',         'London',       'England',              'SW1A 1AA',  'United Kingdom', TRUE),
(1,  'shipping', '55 Riverside Walk',    NULL,              'Oxford',       'Oxfordshire',          'OX1 2AB',   'United Kingdom', FALSE),
(2,  'both',     '25 Elm Avenue',        NULL,              'Manchester',   'Greater Manchester',   'M1 1AA',    'United Kingdom', TRUE),
(3,  'shipping', '8 Castle Road',        'Unit 7',          'Edinburgh',    'Scotland',             'EH1 1AA',   'United Kingdom', TRUE),
(3,  'billing',  '12 Queen Street',      NULL,              'Edinburgh',    'Scotland',             'EH2 3BB',   'United Kingdom', FALSE),
(4,  'both',     '142 High Street',      NULL,              'Birmingham',   'West Midlands',        'B1 1AA',    'United Kingdom', TRUE),
(5,  'both',     '30 Park Lane',         'Suite 12',        'Leeds',        'West Yorkshire',       'LS1 1AA',   'United Kingdom', TRUE),
(6,  'both',     '77 Market Square',     NULL,              'Bristol',      'Avon',                 'BS1 1AA',   'United Kingdom', TRUE),
(7,  'shipping', '3 Chapel Street',      NULL,              'Liverpool',    'Merseyside',           'L1 1AA',    'United Kingdom', TRUE),
(7,  'billing',  '3 Chapel Street',      NULL,              'Liverpool',    'Merseyside',           'L1 1AA',    'United Kingdom', FALSE),
(8,  'both',     '200 Cathedral Road',   'Apt 5B',          'Cardiff',      'Wales',                'CF1 1AA',   'United Kingdom', TRUE),
(9,  'both',     '15 Royal Mile',        NULL,              'Edinburgh',    'Scotland',             'EH1 2CC',   'United Kingdom', TRUE),
(10, 'both',     '48 Grafton Street',    NULL,              'Dublin',       'Leinster',             'D02 X285',  'Ireland',        TRUE),
(11, 'both',     '6 Baker Street',       'Floor 2',         'London',       'England',              'NW1 6XE',   'United Kingdom', TRUE),
(12, 'both',     '91 Princes Street',    NULL,              'Edinburgh',    'Scotland',             'EH2 2ER',   'United Kingdom', TRUE),
(13, 'both',     '17 George Square',     NULL,              'Glasgow',      'Scotland',             'G2 1AL',    'United Kingdom', TRUE),
(14, 'both',     '33 Broad Street',      'Unit 1',          'Nottingham',   'Nottinghamshire',      'NG1 3AL',   'United Kingdom', TRUE),
(15, 'shipping', '5 The Crescent',       NULL,              'Bath',         'Somerset',             'BA1 2AA',   'United Kingdom', TRUE),
(15, 'billing',  '88 London Road',       NULL,              'Reading',      'Berkshire',            'RG1 1AA',   'United Kingdom', FALSE),
(2,  'shipping', '14 Victoria Street',   NULL,              'Manchester',   'Greater Manchester',   'M2 5QQ',    'United Kingdom', FALSE);

-- ============================================================================
-- 3. SELLERS (8 rows)
-- ============================================================================
INSERT INTO shopease.sellers (company_name, contact_name, email, phone, description, rating, status) VALUES
('TechVault Electronics',  'Tom Harrison',     'tom@techvault.co.uk',      '+44-20-7946-0001', 'Premium electronics retailer specialising in laptops, phones, and accessories.',    4.70, 'active'),
('FashionForward Ltd',     'Fiona Campbell',   'fiona@fashionforward.com', '+44-20-7946-0002', 'Contemporary fashion brand offering clothing, footwear, and accessories.',          4.50, 'active'),
('HomeHaven Supplies',     'Helen Morris',     'helen@homehaven.co.uk',    '+44-20-7946-0003', 'Quality home and kitchen products for modern living.',                             4.30, 'active'),
('GadgetWorld',            'Gary Patel',       'gary@gadgetworld.com',     '+44-20-7946-0004', 'The latest gadgets, smart devices, and tech accessories.',                         4.60, 'active'),
('LeatherCraft Co',        'Leo Martinez',     'leo@leathercraft.co.uk',   '+44-20-7946-0005', 'Handcrafted leather goods — bags, belts, wallets, and accessories.',                4.80, 'active'),
('SportsPeak',             'Sarah O''Brien',   'sarah@sportspeak.com',     '+44-20-7946-0006', 'Sports equipment, activewear, and outdoor gear.',                                 4.40, 'active'),
('BookBound Publishing',   'Ben Cooper',       'ben@bookbound.co.uk',      '+44-20-7946-0007', 'Curated selection of books across fiction, non-fiction, and academic titles.',       4.20, 'active'),
('GreenGrow Organics',     'Gemma Nguyen',     'gemma@greengrow.co.uk',    '+44-20-7946-0008', 'Organic and eco-friendly products for health-conscious consumers.',                4.50, 'inactive');

-- ============================================================================
-- 4. CATEGORIES (15 rows — hierarchical)
-- ============================================================================
INSERT INTO shopease.categories (parent_category_id, category_name, description, slug, is_active, sort_order) VALUES
(NULL, 'Electronics',         'Electronic devices and accessories',                    'electronics',          TRUE, 1),
(NULL, 'Clothing',            'Apparel and fashion items',                             'clothing',             TRUE, 2),
(NULL, 'Home & Kitchen',      'Home furnishings, kitchen tools, and decor',            'home-kitchen',         TRUE, 3),
(NULL, 'Sports & Outdoors',   'Sports equipment and outdoor gear',                     'sports-outdoors',      TRUE, 4),
(NULL, 'Books',               'Fiction, non-fiction, and academic books',               'books',                TRUE, 5),
(1,   'Laptops & Computers',  'Laptops, desktops, and computer peripherals',           'laptops-computers',    TRUE, 1),
(1,   'Smartphones',          'Mobile phones and tablet devices',                      'smartphones',          TRUE, 2),
(1,   'Audio & Headphones',   'Speakers, headphones, and audio equipment',             'audio-headphones',     TRUE, 3),
(2,   'Men''s Clothing',      'Clothing for men',                                      'mens-clothing',        TRUE, 1),
(2,   'Women''s Clothing',    'Clothing for women',                                    'womens-clothing',      TRUE, 2),
(2,   'Accessories',          'Fashion accessories — belts, bags, watches',             'accessories',          TRUE, 3),
(3,   'Kitchen Appliances',   'Blenders, toasters, coffee machines, and more',          'kitchen-appliances',   TRUE, 1),
(3,   'Home Decor',           'Decorative items and home styling products',             'home-decor',           TRUE, 2),
(4,   'Fitness Equipment',    'Gym and workout equipment',                             'fitness-equipment',    TRUE, 1),
(5,   'Fiction',              'Novels and short fiction',                               'fiction',              TRUE, 1);

-- ============================================================================
-- 5. PRODUCTS (20 rows)
-- ============================================================================
INSERT INTO shopease.products (seller_id, category_id, product_name, description, price, discount_percentage, sku, weight, status) VALUES
(1, 6,  'ProBook 15 Laptop',                'High-performance 15.6" laptop with Intel i7, 16GB RAM, 512GB SSD.',          899.99,  5.00, 'TV-LAP-001',  2.10, 'active'),
(1, 6,  'UltraSlim 14 Laptop',              'Lightweight 14" ultrabook, AMD Ryzen 5, 8GB RAM, 256GB SSD.',               649.99,  0.00, 'TV-LAP-002',  1.40, 'active'),
(1, 7,  'SmartPhone X12 Pro',               '6.7" AMOLED display, 128GB storage, 5G capable.',                           799.99, 10.00, 'TV-PHN-001',  0.19, 'active'),
(1, 8,  'NoiseCancelling Headphones NC700',  'Premium over-ear headphones with ANC and 30-hour battery.',                 249.99,  0.00, 'TV-AUD-001',  0.25, 'active'),
(4, 8,  'Wireless Earbuds Pro',             'True wireless earbuds with spatial audio and IPX5 water resistance.',        129.99, 15.00, 'GW-AUD-001',  0.05, 'active'),
(2, 9,  'Classic Oxford Shirt',             '100% cotton slim-fit Oxford button-down shirt.',                              59.99,  0.00, 'FF-MSH-001',  0.30, 'active'),
(2, 10, 'Summer Floral Dress',              'Lightweight A-line dress with floral print, perfect for summer.',             79.99, 20.00, 'FF-WDR-001',  0.25, 'active'),
(2, 9,  'Slim Fit Chinos',                  'Stretch cotton chinos in navy, available in all sizes.',                      49.99,  0.00, 'FF-MCH-001',  0.45, 'active'),
(5, 11, 'Handcrafted Leather Belt',         'Full-grain leather belt with brass buckle, hand-stitched.',                   34.99,  0.00, 'LC-BLT-001',  0.20, 'active'),
(5, 11, 'Leather Messenger Bag',            'Vintage-style messenger bag, genuine leather, fits 15" laptops.',            149.99, 10.00, 'LC-BAG-001',  1.20, 'active'),
(3, 12, 'Premium Blender 1200W',            '1200W blender with 6 speed settings and pulse mode. BPA-free jug.',          89.99,  0.00, 'HH-KIT-001',  3.50, 'active'),
(3, 12, 'Espresso Coffee Machine',          'Pump espresso machine with integrated milk frother, 15-bar pressure.',       199.99, 25.00, 'HH-KIT-002',  4.80, 'active'),
(3, 13, 'Scented Candle Set (6-Pack)',       'Hand-poured soy wax candles in assorted fragrances. 40-hour burn time.',     29.99,  0.00, 'HH-DEC-001',  1.80, 'active'),
(6, 14, 'Adjustable Dumbbell Set 20kg',     'Adjustable dumbbells from 2kg to 20kg. Cast iron with rubber grip.',         79.99,  0.00, 'SP-FIT-001', 20.00, 'active'),
(6, 14, 'Yoga Mat Premium 6mm',             'Non-slip TPE yoga mat, 183cm x 61cm. Eco-friendly and lightweight.',         24.99,  0.00, 'SP-FIT-002',  1.00, 'active'),
(6, 4,  'Running Backpack 15L',             'Lightweight hydration-compatible running backpack, reflective details.',      44.99, 10.00, 'SP-OUT-001',  0.35, 'active'),
(7, 15, 'The Midnight Library',             'Bestselling novel by Matt Haig. Paperback edition.',                          8.99,   0.00, 'BB-FIC-001',  0.30, 'active'),
(7, 15, 'Atomic Habits',                    'By James Clear. Practical guide to building good habits. Paperback.',        12.99,   0.00, 'BB-FIC-002',  0.35, 'active'),
(8, 3,  'Organic Bamboo Towel Set',         'Set of 4 ultra-soft bamboo towels. Hypoallergenic and eco-friendly.',        39.99,  0.00, 'GG-HOM-001',  1.60, 'active'),
(4, 1,  'Smart Home Hub',                   'Voice-controlled smart home hub with Wi-Fi, Zigbee, and Thread support.',    99.99,  5.00, 'GW-SMT-001',  0.40, 'active');

-- ============================================================================
-- 6. PRODUCT_IMAGES (25 rows)
-- ============================================================================
INSERT INTO shopease.product_images (product_id, image_url, alt_text, is_primary, sort_order) VALUES
(1,  '/images/products/tv-lap-001-main.jpg',     'ProBook 15 Laptop front view',             TRUE,  1),
(1,  '/images/products/tv-lap-001-side.jpg',     'ProBook 15 Laptop side angle',             FALSE, 2),
(2,  '/images/products/tv-lap-002-main.jpg',     'UltraSlim 14 Laptop open',                 TRUE,  1),
(3,  '/images/products/tv-phn-001-main.jpg',     'SmartPhone X12 Pro front',                 TRUE,  1),
(3,  '/images/products/tv-phn-001-back.jpg',     'SmartPhone X12 Pro rear camera',            FALSE, 2),
(4,  '/images/products/tv-aud-001-main.jpg',     'NoiseCancelling Headphones on stand',       TRUE,  1),
(5,  '/images/products/gw-aud-001-main.jpg',     'Wireless Earbuds Pro in case',              TRUE,  1),
(6,  '/images/products/ff-msh-001-main.jpg',     'Classic Oxford Shirt front',                TRUE,  1),
(7,  '/images/products/ff-wdr-001-main.jpg',     'Summer Floral Dress on hanger',             TRUE,  1),
(7,  '/images/products/ff-wdr-001-detail.jpg',   'Summer Floral Dress fabric detail',         FALSE, 2),
(8,  '/images/products/ff-mch-001-main.jpg',     'Slim Fit Chinos flat lay',                  TRUE,  1),
(9,  '/images/products/lc-blt-001-main.jpg',     'Handcrafted Leather Belt coiled',            TRUE,  1),
(10, '/images/products/lc-bag-001-main.jpg',     'Leather Messenger Bag front',               TRUE,  1),
(10, '/images/products/lc-bag-001-open.jpg',     'Leather Messenger Bag open interior',       FALSE, 2),
(11, '/images/products/hh-kit-001-main.jpg',     'Premium Blender on counter',                TRUE,  1),
(12, '/images/products/hh-kit-002-main.jpg',     'Espresso Coffee Machine front',             TRUE,  1),
(13, '/images/products/hh-dec-001-main.jpg',     'Scented Candle Set arrangement',            TRUE,  1),
(14, '/images/products/sp-fit-001-main.jpg',     'Adjustable Dumbbell Set',                   TRUE,  1),
(15, '/images/products/sp-fit-002-main.jpg',     'Yoga Mat rolled up',                        TRUE,  1),
(16, '/images/products/sp-out-001-main.jpg',     'Running Backpack worn',                     TRUE,  1),
(17, '/images/products/bb-fic-001-main.jpg',     'The Midnight Library cover',                TRUE,  1),
(18, '/images/products/bb-fic-002-main.jpg',     'Atomic Habits cover',                       TRUE,  1),
(19, '/images/products/gg-hom-001-main.jpg',     'Organic Bamboo Towel Set folded',           TRUE,  1),
(20, '/images/products/gw-smt-001-main.jpg',     'Smart Home Hub top-down',                   TRUE,  1),
(20, '/images/products/gw-smt-001-side.jpg',     'Smart Home Hub side ports',                 FALSE, 2);

-- ============================================================================
-- 7. INVENTORY (20 rows — one per product)
-- ============================================================================
INSERT INTO shopease.inventory (product_id, quantity_in_stock, reorder_level, reorder_quantity, warehouse_location, last_restocked) VALUES
(1,  45,  10, 30, 'Warehouse A - Aisle 3, Shelf 2',  '2024-10-15 08:00:00'),
(2,  60,  15, 40, 'Warehouse A - Aisle 3, Shelf 3',  '2024-10-20 09:30:00'),
(3,  120, 20, 60, 'Warehouse A - Aisle 1, Shelf 1',  '2024-11-01 07:00:00'),
(4,  80,  15, 50, 'Warehouse A - Aisle 4, Shelf 1',  '2024-10-25 10:00:00'),
(5,  200, 30, 100,'Warehouse B - Aisle 1, Shelf 5',  '2024-11-05 08:30:00'),
(6,  150, 25, 75, 'Warehouse C - Aisle 2, Shelf 1',  '2024-10-28 11:00:00'),
(7,  90,  20, 50, 'Warehouse C - Aisle 2, Shelf 3',  '2024-11-02 09:00:00'),
(8,  110, 20, 60, 'Warehouse C - Aisle 2, Shelf 2',  '2024-10-30 08:45:00'),
(9,  180, 30, 80, 'Warehouse D - Aisle 1, Shelf 1',  '2024-11-03 07:30:00'),
(10, 35,  8,  20, 'Warehouse D - Aisle 1, Shelf 2',  '2024-10-18 10:15:00'),
(11, 70,  12, 40, 'Warehouse B - Aisle 3, Shelf 1',  '2024-11-04 08:00:00'),
(12, 25,  5,  15, 'Warehouse B - Aisle 3, Shelf 2',  '2024-10-22 09:30:00'),
(13, 300, 50, 150,'Warehouse B - Aisle 4, Shelf 1',  '2024-11-06 07:00:00'),
(14, 40,  8,  25, 'Warehouse E - Aisle 1, Shelf 1',  '2024-10-27 10:00:00'),
(15, 250, 40, 100,'Warehouse E - Aisle 1, Shelf 2',  '2024-11-01 08:30:00'),
(16, 65,  10, 30, 'Warehouse E - Aisle 2, Shelf 1',  '2024-10-29 11:00:00'),
(17, 500, 50, 200,'Warehouse F - Aisle 1, Shelf 1',  '2024-11-05 09:00:00'),
(18, 400, 50, 200,'Warehouse F - Aisle 1, Shelf 2',  '2024-11-05 09:00:00'),
(19, 85,  15, 40, 'Warehouse B - Aisle 5, Shelf 1',  '2024-10-31 08:00:00'),
(20, 95,  15, 50, 'Warehouse A - Aisle 5, Shelf 1',  '2024-11-07 07:00:00');

-- ============================================================================
-- 8. SHOPPING_CART (10 rows)
-- ============================================================================
INSERT INTO shopease.shopping_cart (customer_id) VALUES
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10);

-- ============================================================================
-- 9. CART_ITEMS (12 rows)
-- ============================================================================
INSERT INTO shopease.cart_items (cart_id, product_id, quantity) VALUES
(1,  3,  1),   -- Alice has SmartPhone X12 in cart
(1,  9,  1),   -- Alice has Leather Belt in cart
(2,  1,  1),   -- Bob has ProBook 15 in cart
(3, 12,  1),   -- Claire has Espresso Machine in cart
(3, 13,  2),   -- Claire has 2x Scented Candles in cart
(4,  6,  2),   -- David has 2x Oxford Shirts in cart
(5, 15,  1),   -- Emma has Yoga Mat in cart
(5, 14,  1),   -- Emma has Dumbbell Set in cart
(7, 17,  1),   -- Grace has Midnight Library in cart
(7, 18,  1),   -- Grace has Atomic Habits in cart
(8, 20,  1),   -- Henry has Smart Home Hub in cart
(9,  7,  1);   -- Isabel has Summer Dress in cart

-- ============================================================================
-- 10. ORDERS (15 rows)
-- ============================================================================
INSERT INTO shopease.orders (customer_id, shipping_address_id, billing_address_id, order_status, subtotal, tax_amount, shipping_cost, total_amount, notes, order_date) VALUES
(1,  1,  1,  'delivered',   959.97,  192.00,  5.99,  1157.96, NULL,                              '2024-09-01 10:23:00'),
(2,  3,  3,  'delivered',   649.99,  130.00,  5.99,   785.98, 'Please leave at reception.',       '2024-09-05 14:15:00'),
(1,  2,  1,  'delivered',   129.99,   26.00,  3.99,   159.98, NULL,                              '2024-09-10 09:30:00'),
(3,  4,  5,  'shipped',     249.99,   50.00,  4.99,   304.98, NULL,                              '2024-10-01 11:00:00'),
(5,  7,  7,  'delivered',   139.97,   28.00,  4.99,   172.96, NULL,                              '2024-10-05 16:45:00'),
(4,  6,  6,  'delivered',   899.99,  180.00,  0.00,  1079.99, 'Gift — please do not include invoice.', '2024-10-10 08:20:00'),
(6,  8,  8,  'processing',  169.98,   34.00,  5.99,   209.97, NULL,                              '2024-10-20 13:10:00'),
(7,  9,  10, 'delivered',    79.99,   16.00,  3.99,    99.98, NULL,                              '2024-10-22 17:30:00'),
(8,  11, 11, 'shipped',     199.99,   40.00,  5.99,   245.98, NULL,                              '2024-11-01 09:00:00'),
(9,  12, 12, 'pending',      59.99,   12.00,  3.99,    75.98, NULL,                              '2024-11-05 10:15:00'),
(10, 13, 13, 'confirmed',   149.99,   30.00,  7.99,   187.98, 'International delivery to Ireland.', '2024-11-08 14:00:00'),
(11, 14, 14, 'delivered',    21.98,    4.40,  2.99,    29.37, NULL,                              '2024-09-15 11:30:00'),
(12, 15, 15, 'delivered',    34.99,    7.00,  3.99,    45.98, NULL,                              '2024-09-20 15:00:00'),
(13, 16, 16, 'cancelled',   104.98,   21.00,  4.99,   130.97, 'Customer requested cancellation.', '2024-10-12 12:00:00'),
(14, 17, 17, 'delivered',    44.99,    9.00,  3.99,    57.98, NULL,                              '2024-10-18 09:45:00');

-- ============================================================================
-- 11. ORDER_ITEMS (22 rows)
-- ============================================================================
INSERT INTO shopease.order_items (order_id, product_id, seller_id, quantity, unit_price, discount_amount, total_price) VALUES
-- Order 1: Alice — Laptop + Headphones
(1,  1,  1, 1, 899.99,  45.00, 854.99),
(1,  4,  1, 1, 249.99,   0.00, 249.99),
-- Order 2: Bob — UltraSlim Laptop
(2,  2,  1, 1, 649.99,   0.00, 649.99),
-- Order 3: Alice — Wireless Earbuds
(3,  5,  4, 1, 129.99,  19.50, 110.49),
-- Order 4: Claire — NoiseCancelling Headphones
(4,  4,  1, 1, 249.99,   0.00, 249.99),
-- Order 5: Emma — Dumbbell Set + Yoga Mat
(5, 14,  6, 1,  79.99,   0.00,  79.99),
(5, 15,  6, 1,  24.99,   0.00,  24.99),
(5, 16,  6, 1,  44.99,   4.50,  40.49),
-- Order 6: David — ProBook 15 Laptop
(6,  1,  1, 1, 899.99,  45.00, 854.99),
-- Order 7: Frank — Espresso Machine + Scented Candles
(7, 12,  3, 1, 199.99,  50.00, 149.99),
(7, 13,  3, 1,  29.99,   0.00,  29.99),
-- Order 8: Grace — Summer Floral Dress
(8,  7,  2, 1,  79.99,  16.00,  63.99),
-- Order 9: Henry — Espresso Machine
(9, 12,  3, 1, 199.99,  50.00, 149.99),
-- Order 10: Isabel — Oxford Shirt
(10, 6,  2, 1,  59.99,   0.00,  59.99),
-- Order 11: James — Leather Messenger Bag
(11,10,  5, 1, 149.99,  15.00, 134.99),
-- Order 12: Karen — Books
(12,17,  7, 1,   8.99,   0.00,   8.99),
(12,18,  7, 1,  12.99,   0.00,  12.99),
-- Order 13: Liam — Leather Belt
(13, 9,  5, 1,  34.99,   0.00,  34.99),
-- Order 14: Mia — Dumbbell Set + Yoga Mat (cancelled)
(14,14,  6, 1,  79.99,   0.00,  79.99),
(14,15,  6, 1,  24.99,   0.00,  24.99),
-- Order 15: Nathan — Running Backpack
(15,16,  6, 1,  44.99,   4.50,  40.49);

-- ============================================================================
-- 12. PAYMENTS (14 rows — no payment for cancelled order 14)
-- ============================================================================
INSERT INTO shopease.payments (order_id, payment_method, transaction_id, amount, currency, status, payment_date) VALUES
(1,  'credit_card',   'TXN-2024-00001', 1157.96, 'GBP', 'completed', '2024-09-01 10:25:00'),
(2,  'debit_card',    'TXN-2024-00002',  785.98, 'GBP', 'completed', '2024-09-05 14:17:00'),
(3,  'paypal',        'TXN-2024-00003',  159.98, 'GBP', 'completed', '2024-09-10 09:32:00'),
(4,  'credit_card',   'TXN-2024-00004',  304.98, 'GBP', 'completed', '2024-10-01 11:02:00'),
(5,  'apple_pay',     'TXN-2024-00005',  172.96, 'GBP', 'completed', '2024-10-05 16:47:00'),
(6,  'credit_card',   'TXN-2024-00006', 1079.99, 'GBP', 'completed', '2024-10-10 08:22:00'),
(7,  'paypal',        'TXN-2024-00007',  209.97, 'GBP', 'completed', '2024-10-20 13:12:00'),
(8,  'debit_card',    'TXN-2024-00008',   99.98, 'GBP', 'completed', '2024-10-22 17:32:00'),
(9,  'credit_card',   'TXN-2024-00009',  245.98, 'GBP', 'completed', '2024-11-01 09:02:00'),
(10, 'google_pay',    'TXN-2024-00010',   75.98, 'GBP', 'pending',   '2024-11-05 10:17:00'),
(11, 'bank_transfer', 'TXN-2024-00011',  187.98, 'EUR', 'completed', '2024-11-08 14:05:00'),
(12, 'debit_card',    'TXN-2024-00012',   29.37, 'GBP', 'completed', '2024-09-15 11:32:00'),
(13, 'credit_card',   'TXN-2024-00013',   45.98, 'GBP', 'completed', '2024-09-20 15:02:00'),
(15, 'paypal',        'TXN-2024-00015',   57.98, 'GBP', 'completed', '2024-10-18 09:47:00');

-- ============================================================================
-- 13. SHIPPING (13 rows — no shipping for pending/cancelled orders)
-- ============================================================================
INSERT INTO shopease.shipping (order_id, carrier, tracking_number, shipping_status, shipped_date, estimated_delivery, actual_delivery, shipping_cost) VALUES
(1,  'Royal Mail',    'RM-2024-00001', 'delivered',       '2024-09-02 08:00:00', '2024-09-05 18:00:00', '2024-09-04 14:30:00', 5.99),
(2,  'DPD',           'DPD-2024-00002','delivered',       '2024-09-06 09:00:00', '2024-09-09 18:00:00', '2024-09-08 11:15:00', 5.99),
(3,  'Hermes',        'HM-2024-00003', 'delivered',       '2024-09-11 07:30:00', '2024-09-14 18:00:00', '2024-09-13 16:45:00', 3.99),
(4,  'Royal Mail',    'RM-2024-00004', 'in_transit',      '2024-10-02 08:00:00', '2024-10-06 18:00:00', NULL,                  4.99),
(5,  'DPD',           'DPD-2024-00005','delivered',       '2024-10-06 09:00:00', '2024-10-09 18:00:00', '2024-10-08 10:30:00', 4.99),
(6,  'Royal Mail',    'RM-2024-00006', 'delivered',       '2024-10-11 08:00:00', '2024-10-14 18:00:00', '2024-10-13 15:00:00', 0.00),
(7,  'Hermes',        'HM-2024-00007', 'processing',     NULL,                  NULL,                  NULL,                  5.99),
(8,  'Royal Mail',    'RM-2024-00008', 'delivered',       '2024-10-23 08:00:00', '2024-10-26 18:00:00', '2024-10-25 12:00:00', 3.99),
(9,  'DPD',           'DPD-2024-00009','shipped',         '2024-11-02 09:00:00', '2024-11-05 18:00:00', NULL,                  5.99),
(11, 'FedEx',         'FX-2024-00011', 'shipped',         '2024-11-09 10:00:00', '2024-11-14 18:00:00', NULL,                  7.99),
(12, 'Royal Mail',    'RM-2024-00012', 'delivered',       '2024-09-16 08:00:00', '2024-09-19 18:00:00', '2024-09-18 14:00:00', 2.99),
(13, 'Hermes',        'HM-2024-00013', 'delivered',       '2024-09-21 07:30:00', '2024-09-24 18:00:00', '2024-09-23 11:00:00', 3.99),
(15, 'DPD',           'DPD-2024-00015','delivered',       '2024-10-19 09:00:00', '2024-10-22 18:00:00', '2024-10-21 16:30:00', 3.99);

-- ============================================================================
-- 14. REVIEWS (15 rows)
-- ============================================================================
INSERT INTO shopease.reviews (product_id, customer_id, order_id, rating, title, comment, is_verified) VALUES
(1,  1,  1,  5, 'Excellent Laptop',             'Fast, lightweight, and the screen is gorgeous. Very happy with this purchase.',         TRUE),
(4,  1,  1,  4, 'Great ANC Headphones',         'Sound quality is superb. ANC could be slightly better on windy days.',                 TRUE),
(2,  2,  2,  4, 'Good Value Ultrabook',          'Solid performance for the price. Battery life could be a bit longer.',                 TRUE),
(5,  1,  3,  5, 'Best Earbuds I''ve Owned',     'Crystal clear audio and the case is super compact. Love the spatial audio feature.',    TRUE),
(14, 5,  5,  5, 'Sturdy Dumbbells',              'Well-built and the adjustment mechanism is smooth. Great for home workouts.',           TRUE),
(15, 5,  5,  4, 'Nice Yoga Mat',                 'Good grip and thickness. Took a day for the smell to dissipate.',                      TRUE),
(16, 5,  5,  4, 'Lightweight Backpack',          'Perfect for trail runs. Hydration sleeve fits my 1.5L bladder.',                       TRUE),
(1,  4,  6,  5, 'Perfect for Work',              'Using it for software development. Handles everything I throw at it.',                  TRUE),
(7,  7,  8,  5, 'Beautiful Dress',               'The fabric is lovely and the fit is perfect. Got many compliments!',                    TRUE),
(12, 6,  7,  4, 'Decent Espresso Machine',       'Makes great espresso. Milk frother could be more powerful for lattes.',                 TRUE),
(17, 11, 12, 5, 'Thought-Provoking Read',        'Beautifully written. Made me think about the roads not taken.',                         TRUE),
(18, 11, 12, 5, 'Changed My Habits',             'Practical and actionable advice. I''ve already implemented three habit stacks.',        TRUE),
(9,  12, 13, 5, 'Superb Craftsmanship',          'The leather quality is outstanding. The brass buckle adds a nice touch.',               TRUE),
(16, 14, 15, 3, 'Decent But Small',              'Good quality but the 15L capacity feels cramped for longer runs.',                      TRUE),
(10, 10, 11, 4, 'Stylish Messenger Bag',         'Looks great and fits my laptop. Leather will develop a nice patina over time.',         TRUE);

-- ============================================================================
-- 15. WISHLISTS (8 rows)
-- ============================================================================
INSERT INTO shopease.wishlists (customer_id, wishlist_name, is_public) VALUES
(1,  'Tech Upgrades',      FALSE),
(1,  'Gift Ideas',         TRUE),
(2,  'My Wishlist',        FALSE),
(3,  'Home Renovation',    FALSE),
(5,  'Fitness Goals',      TRUE),
(7,  'Reading List',       TRUE),
(9,  'Fashion Wants',      FALSE),
(13, 'Birthday List',      TRUE);

-- ============================================================================
-- 16. WISHLIST_ITEMS (18 rows)
-- ============================================================================
INSERT INTO shopease.wishlist_items (wishlist_id, product_id) VALUES
(1,  3),   -- Alice Tech Upgrades: SmartPhone X12 Pro
(1, 20),   -- Alice Tech Upgrades: Smart Home Hub
(2,  7),   -- Alice Gift Ideas: Summer Floral Dress
(2, 13),   -- Alice Gift Ideas: Scented Candle Set
(2, 10),   -- Alice Gift Ideas: Leather Messenger Bag
(3,  1),   -- Bob: ProBook 15 Laptop
(3,  4),   -- Bob: NoiseCancelling Headphones
(4, 11),   -- Claire Home Renovation: Premium Blender
(4, 12),   -- Claire Home Renovation: Espresso Machine
(4, 19),   -- Claire Home Renovation: Bamboo Towel Set
(5, 14),   -- Emma Fitness Goals: Dumbbell Set (already bought, keeping for re-order)
(5, 16),   -- Emma Fitness Goals: Running Backpack
(6, 17),   -- Grace Reading List: The Midnight Library
(6, 18),   -- Grace Reading List: Atomic Habits
(7,  6),   -- Isabel Fashion Wants: Oxford Shirt
(7,  8),   -- Isabel Fashion Wants: Slim Fit Chinos
(7,  9),   -- Isabel Fashion Wants: Leather Belt
(8, 20);   -- Mia Birthday List: Smart Home Hub

-- ============================================================================
-- 17. RETURN_REQUESTS (4 rows)
-- ============================================================================
INSERT INTO shopease.return_requests (order_item_id, customer_id, reason, description, status, refund_amount, requested_at, resolved_at) VALUES
(2,  1,  'not_as_described',  'The headphone cushions feel different from the product photos — much thinner than expected.', 'refunded',  249.99, '2024-09-10 09:00:00', '2024-09-15 14:00:00'),
(3,  2,  'changed_mind',      'Decided I need a more powerful laptop for video editing.',                                    'approved',  649.99, '2024-09-12 10:30:00', '2024-09-14 16:00:00'),
(19, 13, 'damaged_in_transit', 'Box arrived crushed and one dumbbell plate is cracked.',                                      'pending',    79.99, '2024-10-20 11:00:00', NULL),
(21, 14, 'wrong_item',        'Received a different colour backpack (black instead of blue).',                                'completed',  40.49, '2024-10-25 08:00:00', '2024-10-30 12:00:00');

-- ============================================================================
-- 18. COUPONS (6 rows)
-- ============================================================================
INSERT INTO shopease.coupons (code, discount_type, discount_value, min_order_amount, valid_from, valid_until, usage_limit, times_used, is_active) VALUES
('WELCOME10',   'percentage',   10.00,   0.00,   '2024-01-01 00:00:00', '2025-12-31 23:59:59', NULL,  342,  TRUE),
('SAVE20',      'percentage',   20.00,  50.00,   '2024-06-01 00:00:00', '2024-12-31 23:59:59', 1000, 567,  TRUE),
('FLAT15OFF',   'fixed_amount', 15.00, 100.00,   '2024-09-01 00:00:00', '2024-11-30 23:59:59', 500,  210,  TRUE),
('BLACKFRIDAY', 'percentage',   30.00,  75.00,   '2024-11-25 00:00:00', '2024-11-30 23:59:59', 2000,   0,  TRUE),
('FREESHIP50',  'fixed_amount',  5.99,  50.00,   '2024-01-01 00:00:00', '2025-06-30 23:59:59', NULL,  891,  TRUE),
('SUMMER25',    'percentage',   25.00,  30.00,   '2024-06-01 00:00:00', '2024-08-31 23:59:59', 750,  750, FALSE);

-- ============================================================================
-- END OF SEED DATA
-- ============================================================================
