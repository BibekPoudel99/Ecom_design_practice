-- ─────────────────────────────────────────
-- SAMPLE DATA
-- ─────────────────────────────────────────

-- Users
INSERT INTO users (email, password_hash, first_name, last_name, phone, role) VALUES
('ram@gmail.com',    'hashed_pw1', 'Ram',    'Sharma',    '9841000001', 'customer'),
('sita@gmail.com',   'hashed_pw2', 'Sita',   'Thapa',     '9841000002', 'customer'),
('hari@gmail.com',   'hashed_pw3', 'Hari',   'Bahadur',   '9841000003', 'seller'),
('gita@gmail.com',   'hashed_pw4', 'Gita',   'Gurung',    '9841000004', 'seller'),
('admin@shop.com',   'hashed_pw5', 'Admin',  'User',      '9841000005', 'admin');

-- Addresses
INSERT INTO user_addresses (user_id, label, address_line1, city, is_default) VALUES
(1, 'home',   'Thamel, Ward 26',      'Kathmandu', TRUE),
(1, 'office', 'Durbar Marg, Ward 1',  'Kathmandu', FALSE),
(2, 'home',   'Lakeside, Ward 6',     'Pokhara',   TRUE);

-- Sellers
INSERT INTO sellers (user_id, store_name, description, is_verified, commission_rate) VALUES
(3, 'TechHub Nepal',    'Electronics and gadgets',     TRUE,  8.00),
(4, 'Fashion Street',   'Clothing and accessories',    TRUE,  12.00);

-- Categories
INSERT INTO categories (parent_id, name, slug, level) VALUES
(NULL, 'Electronics',   'electronics',          1),
(NULL, 'Fashion',       'fashion',              1),
(1,    'Mobile Phones', 'mobile-phones',        2),
(1,    'Laptops',       'laptops',              2),
(2,    'Men Clothing',  'men-clothing',         2),
(3,    'Smartphones',   'smartphones',          3);

-- Attributes
INSERT INTO attributes (name) VALUES
('Color'), ('Storage'), ('Size'), ('RAM');

-- Products
INSERT INTO products (seller_id, category_id, name, slug, base_price) VALUES
(1, 6, 'Samsung Galaxy A54',  'samsung-galaxy-a54',  35000.00),
(1, 4, 'Dell Inspiron 15',    'dell-inspiron-15',    85000.00),
(2, 5, 'Basic Cotton T-Shirt','basic-cotton-tshirt',  1500.00);

-- Product Variants
INSERT INTO product_variants (product_id, sku, price) VALUES
(1, 'SAM-A54-BLK-128', 35000.00),   -- Samsung Black 128GB
(1, 'SAM-A54-BLU-256', 38000.00),   -- Samsung Blue 256GB
(2, 'DELL-I15-8-512',  85000.00),   -- Dell 8GB 512GB
(2, 'DELL-I15-16-512', 95000.00),   -- Dell 16GB 512GB
(3, 'TSHIRT-WHT-M',     1500.00),   -- T-shirt White M
(3, 'TSHIRT-BLK-L',     1500.00);   -- T-shirt Black L

-- Variant Attributes
INSERT INTO variant_attribute_values (variant_id, attribute_id, value) VALUES
(1, 1, 'Black'), (1, 2, '128GB'),
(2, 1, 'Blue'),  (2, 2, '256GB'),
(3, 4, '8GB'),   (3, 2, '512GB'),
(4, 4, '16GB'),  (4, 2, '512GB'),
(5, 1, 'White'), (5, 3, 'M'),
(6, 1, 'Black'), (6, 3, 'L');

-- Warehouses
INSERT INTO warehouses (name, city, address) VALUES
('KTM Central',  'Kathmandu', 'Balaju Industrial Area'),
('PKR Warehouse','Pokhara',   'Siddhartha Highway');

-- Inventory
INSERT INTO inventory (variant_id, warehouse_id, quantity, reserved) VALUES
(1, 1, 50, 5),
(2, 1, 30, 0),
(3, 1, 20, 2),
(4, 1, 10, 0),
(5, 2, 100, 10),
(6, 2, 80,  5);

-- Coupons
INSERT INTO coupons (code, type, value, min_order_amt, max_discount, usage_limit, starts_at, expires_at) VALUES
('SAVE10',  'percentage', 10.00, 1000.00, 500.00, 100, NOW(), NOW() + INTERVAL '30 days'),
('FLAT200', 'fixed',     200.00, 2000.00,   NULL,  50, NOW(), NOW() + INTERVAL '15 days');

-- Orders
INSERT INTO orders (user_id, address_id, coupon_id, status, subtotal, discount_amount, shipping_cost, total_amount) VALUES
(1, 1, 1, 'delivered', 35000.00, 500.00, 0.00, 34500.00),
(1, 1, NULL, 'shipped',  85000.00, 0.00, 200.00, 85200.00),
(2, 3, 2, 'pending',    1500.00, 200.00, 100.00,  1400.00);

-- Order Items
INSERT INTO order_items (order_id, variant_id, seller_id, quantity, unit_price, total_price, status) VALUES
(1, 1, 1, 1, 35000.00, 35000.00, 'delivered'),
(2, 3, 1, 1, 85000.00, 85000.00, 'shipped'),
(3, 5, 2, 1,  1500.00,  1500.00, 'pending');

-- Order Status History
INSERT INTO order_status_history (order_id, old_status, new_status, changed_by) VALUES
(1, NULL,        'pending',   1),
(1, 'pending',   'confirmed', 5),
(1, 'confirmed', 'shipped',   5),
(1, 'shipped',   'delivered', 5);

-- Payments
INSERT INTO payments (order_id, method, status, amount, transaction_id) VALUES
(1, 'esewa',  'completed', 34500.00, 'ESW-2024-00123'),
(2, 'khalti', 'completed', 85200.00, 'KHL-2024-00456'),
(3, 'cod',    'pending',    1400.00,  NULL);

-- Shipments
INSERT INTO shipments (order_id, warehouse_id, tracking_number, carrier, status, shipped_at, delivered_at) VALUES
(1, 1, 'TRK-001', 'Aramex Nepal', 'delivered', NOW() - INTERVAL '5 days', NOW() - INTERVAL '2 days'),
(2, 1, 'TRK-002', 'DHL',          'in_transit', NOW() - INTERVAL '1 day',  NULL);

-- Reviews
INSERT INTO reviews (user_id, product_id, order_item_id, rating, title, comment, is_verified) VALUES
(1, 1, 1, 5, 'Great Phone!', 'Battery life is excellent.', TRUE);