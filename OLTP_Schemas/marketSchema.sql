-- ============================================================
-- E-COMMERCE MARKETPLACE DATABASE
-- Database: PostgreSQL
-- ============================================================

-- ─────────────────────────────────────────
-- 1. USERS & ADDRESSES
-- ─────────────────────────────────────────

CREATE TABLE users (
    user_id         SERIAL PRIMARY KEY,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    phone           VARCHAR(20),
    role            VARCHAR(20) DEFAULT 'customer'
                    CHECK (role IN ('customer', 'seller', 'admin')),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_addresses (
    address_id      SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    label           VARCHAR(50),          -- 'home', 'office', 'other'
    address_line1   VARCHAR(255) NOT NULL,
    address_line2   VARCHAR(255),
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(100),
    country         VARCHAR(100) NOT NULL DEFAULT 'Nepal',
    postal_code     VARCHAR(20),
    is_default      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ─────────────────────────────────────────
-- 2. SELLERS
-- ─────────────────────────────────────────

CREATE TABLE sellers (
    seller_id       SERIAL PRIMARY KEY,
    user_id         INT UNIQUE NOT NULL REFERENCES users(user_id),
    store_name      VARCHAR(255) NOT NULL,
    description     TEXT,
    rating          DECIMAL(3,2) DEFAULT 0.00,
    total_reviews   INT DEFAULT 0,
    is_verified     BOOLEAN DEFAULT FALSE,
    commission_rate DECIMAL(5,2) DEFAULT 10.00,   -- % platform takes per sale
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ─────────────────────────────────────────
-- 3. CATEGORIES (Self-Referencing Hierarchy)
-- ─────────────────────────────────────────
-- Example:
-- Electronics (level 1, parent=NULL)
--   └── Mobile Phones (level 2, parent=Electronics)
--         └── Smartphones (level 3, parent=Mobile Phones)

CREATE TABLE categories (
    category_id     SERIAL PRIMARY KEY,
    parent_id       INT REFERENCES categories(category_id),  -- NULL = root
    name            VARCHAR(100) NOT NULL,
    slug            VARCHAR(100) UNIQUE NOT NULL,
    description     TEXT,
    level           INT NOT NULL DEFAULT 1,
    is_active       BOOLEAN DEFAULT TRUE
);


-- ─────────────────────────────────────────
-- 4. PRODUCTS & VARIANTS
-- ─────────────────────────────────────────

CREATE TABLE products (
    product_id      SERIAL PRIMARY KEY,
    seller_id       INT NOT NULL REFERENCES sellers(seller_id),
    category_id     INT NOT NULL REFERENCES categories(category_id),
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) UNIQUE NOT NULL,
    description     TEXT,
    base_price      DECIMAL(12,2) NOT NULL,    -- lowest price across variants
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Flexible attribute system
-- 'Color', 'Size', 'Storage', 'Material' etc.
CREATE TABLE attributes (
    attribute_id    SERIAL PRIMARY KEY,
    name            VARCHAR(100) UNIQUE NOT NULL
);

-- A variant = one specific combination
-- e.g., iPhone 15 | Red | 128GB = one variant
CREATE TABLE product_variants (
    variant_id      SERIAL PRIMARY KEY,
    product_id      INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    sku             VARCHAR(100) UNIQUE NOT NULL,
    price           DECIMAL(12,2) NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Junction table: what makes each variant unique
CREATE TABLE variant_attribute_values (
    variant_id      INT NOT NULL REFERENCES product_variants(variant_id) ON DELETE CASCADE,
    attribute_id    INT NOT NULL REFERENCES attributes(attribute_id),
    value           VARCHAR(100) NOT NULL,     -- 'Red', 'Large', '128GB'
    PRIMARY KEY (variant_id, attribute_id)
);

CREATE TABLE product_images (
    image_id        SERIAL PRIMARY KEY,
    product_id      INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    variant_id      INT REFERENCES product_variants(variant_id),  -- NULL = all variants
    url             VARCHAR(500) NOT NULL,
    alt_text        VARCHAR(255),
    is_primary      BOOLEAN DEFAULT FALSE,
    display_order   INT DEFAULT 0
);


-- ─────────────────────────────────────────
-- 5. INVENTORY
-- ─────────────────────────────────────────

CREATE TABLE warehouses (
    warehouse_id    SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    address         TEXT,
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE inventory (
    inventory_id    SERIAL PRIMARY KEY,
    variant_id      INT NOT NULL REFERENCES product_variants(variant_id),
    warehouse_id    INT NOT NULL REFERENCES warehouses(warehouse_id),
    quantity        INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reserved        INT NOT NULL DEFAULT 0 CHECK (reserved >= 0),
    -- reserved = locked for pending orders, not yet deducted
    last_updated    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (variant_id, warehouse_id)        -- one row per variant per warehouse
);


-- ─────────────────────────────────────────
-- 6. COUPONS & DISCOUNTS
-- ─────────────────────────────────────────

CREATE TABLE coupons (
    coupon_id       SERIAL PRIMARY KEY,
    code            VARCHAR(50) UNIQUE NOT NULL,
    type            VARCHAR(20) NOT NULL CHECK (type IN ('percentage', 'fixed')),
    value           DECIMAL(10,2) NOT NULL,        -- 10 = 10% OR Rs.10 off
    min_order_amt   DECIMAL(12,2) DEFAULT 0,        -- minimum cart value
    max_discount    DECIMAL(12,2),                  -- cap for percentage type
    usage_limit     INT,                            -- NULL = unlimited global uses
    used_count      INT DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    starts_at       TIMESTAMP NOT NULL,
    expires_at      TIMESTAMP NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE coupon_usage (
    usage_id        SERIAL PRIMARY KEY,
    coupon_id       INT NOT NULL REFERENCES coupons(coupon_id),
    user_id         INT NOT NULL REFERENCES users(user_id),
    order_id        INT NOT NULL,                   -- FK added after orders table
    used_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (coupon_id, user_id)                     -- 1 use per user per coupon
);


-- ─────────────────────────────────────────
-- 7. ORDERS
-- ─────────────────────────────────────────

CREATE TABLE orders (
    order_id        SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id),
    address_id      INT NOT NULL REFERENCES user_addresses(address_id),
    coupon_id       INT REFERENCES coupons(coupon_id),
    status          VARCHAR(30) NOT NULL DEFAULT 'pending'
                    CHECK (status IN (
                        'pending', 'confirmed', 'processing',
                        'shipped', 'delivered', 'cancelled', 'refunded'
                    )),
    subtotal        DECIMAL(12,2) NOT NULL,         -- before discount/shipping
    discount_amount DECIMAL(12,2) DEFAULT 0,
    shipping_cost   DECIMAL(12,2) DEFAULT 0,
    total_amount    DECIMAL(12,2) NOT NULL,          -- what customer actually pays
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Each line item in an order
-- KEY DESIGN DECISION: unit_price is stored here (denormalized)
-- because variant price can change later — we need price AT TIME OF PURCHASE
CREATE TABLE order_items (
    order_item_id   SERIAL PRIMARY KEY,
    order_id        INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    variant_id      INT NOT NULL REFERENCES product_variants(variant_id),
    seller_id       INT NOT NULL REFERENCES sellers(seller_id),
    quantity        INT NOT NULL CHECK (quantity > 0),
    unit_price      DECIMAL(12,2) NOT NULL,         -- SNAPSHOT of price at purchase
    total_price     DECIMAL(12,2) NOT NULL,          -- quantity * unit_price
    status          VARCHAR(30) DEFAULT 'pending'    -- each seller handles own items
                    CHECK (status IN (
                        'pending', 'confirmed', 'shipped',
                        'delivered', 'cancelled', 'refunded'
                    )),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit trail — every status change is recorded
CREATE TABLE order_status_history (
    history_id      SERIAL PRIMARY KEY,
    order_id        INT NOT NULL REFERENCES orders(order_id),
    old_status      VARCHAR(30),
    new_status      VARCHAR(30) NOT NULL,
    changed_by      INT REFERENCES users(user_id),
    note            TEXT,
    changed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ─────────────────────────────────────────
-- 8. PAYMENTS
-- ─────────────────────────────────────────

CREATE TABLE payments (
    payment_id      SERIAL PRIMARY KEY,
    order_id        INT NOT NULL REFERENCES orders(order_id),
    method          VARCHAR(50) NOT NULL
                    CHECK (method IN ('esewa', 'khalti', 'card', 'cod', 'bank_transfer')),
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    amount          DECIMAL(12,2) NOT NULL,
    transaction_id  VARCHAR(255),                   -- payment gateway reference
    gateway_response JSONB,                         -- raw gateway response, flexible
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ─────────────────────────────────────────
-- 9. SHIPMENTS
-- ─────────────────────────────────────────

CREATE TABLE shipments (
    shipment_id     SERIAL PRIMARY KEY,
    order_id        INT NOT NULL REFERENCES orders(order_id),
    warehouse_id    INT REFERENCES warehouses(warehouse_id),
    tracking_number VARCHAR(100),
    carrier         VARCHAR(100),                   -- 'Aramex', 'DHL', 'Local Courier'
    status          VARCHAR(30) DEFAULT 'processing'
                    CHECK (status IN (
                        'processing', 'dispatched', 'in_transit',
                        'delivered', 'returned'
                    )),
    shipped_at      TIMESTAMP,
    delivered_at    TIMESTAMP,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ─────────────────────────────────────────
-- 10. REVIEWS
-- ─────────────────────────────────────────

CREATE TABLE reviews (
    review_id       SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id),
    product_id      INT NOT NULL REFERENCES products(product_id),
    order_item_id   INT REFERENCES order_items(order_item_id),  -- proves they bought it
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title           VARCHAR(255),
    comment         TEXT,
    is_verified     BOOLEAN DEFAULT FALSE,          -- verified purchase review
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, order_item_id)                 -- one review per purchased item
);


-- ─────────────────────────────────────────
-- 11. INDEXES
-- ─────────────────────────────────────────

-- Users
CREATE INDEX idx_users_email          ON users(email);

-- Addresses
CREATE INDEX idx_addresses_user_id    ON user_addresses(user_id);

-- Products (most queried table)
CREATE INDEX idx_products_seller_id   ON products(seller_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_is_active   ON products(is_active);

-- Variants
CREATE INDEX idx_variants_product_id  ON product_variants(product_id);
CREATE INDEX idx_variants_sku         ON product_variants(sku);

-- Inventory
CREATE INDEX idx_inventory_variant_id    ON inventory(variant_id);
CREATE INDEX idx_inventory_warehouse_id  ON inventory(warehouse_id);

-- Orders (heavily queried)
CREATE INDEX idx_orders_user_id       ON orders(user_id);
CREATE INDEX idx_orders_status        ON orders(status);
CREATE INDEX idx_orders_created_at    ON orders(created_at DESC);

-- Order Items
CREATE INDEX idx_order_items_order_id   ON order_items(order_id);
CREATE INDEX idx_order_items_seller_id  ON order_items(seller_id);
CREATE INDEX idx_order_items_variant_id ON order_items(variant_id);

-- Payments
CREATE INDEX idx_payments_order_id    ON payments(order_id);
CREATE INDEX idx_payments_status      ON payments(status);

-- Reviews
CREATE INDEX idx_reviews_product_id   ON reviews(product_id);
CREATE INDEX idx_reviews_user_id      ON reviews(user_id);