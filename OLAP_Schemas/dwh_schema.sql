CREATE SCHEMA IF NOT EXISTS dwh;

-- Watermark tracking
CREATE TABLE IF NOT EXISTS dwh.etl_watermark (
    table_name        TEXT PRIMARY KEY,
    last_extracted_at TIMESTAMPTZ NOT NULL DEFAULT '2000-01-01'
);

-- Dimension: Date
CREATE TABLE IF NOT EXISTS dwh.dim_date (
    date_key        INT PRIMARY KEY,  -- YYYYMMDD
    full_date       DATE,
    day             INT,
    month           INT,
    month_name      TEXT,
    quarter         INT,
    year            INT,
    day_of_week     INT,
    day_name        TEXT,
    is_weekend      BOOLEAN
);

-- Dimension: User
CREATE TABLE IF NOT EXISTS dwh.dim_user (
    user_key        SERIAL PRIMARY KEY,
    user_id         INT NOT NULL,
    full_name       TEXT,
    email           TEXT,
    phone           TEXT,
    city            TEXT,
    country         TEXT,
    -- SCD2
    effective_from  TIMESTAMPTZ NOT NULL,
    effective_to    TIMESTAMPTZ,
    is_current      BOOLEAN DEFAULT TRUE
);

-- Dimension: Seller
CREATE TABLE IF NOT EXISTS dwh.dim_seller (
    seller_key      SERIAL PRIMARY KEY,
    seller_id       INT NOT NULL,
    store_name      TEXT,
    email           TEXT,
    commission_rate NUMERIC(5,2),
    rating          NUMERIC(3,2),
    -- SCD2
    effective_from  TIMESTAMPTZ NOT NULL,
    effective_to    TIMESTAMPTZ,
    is_current      BOOLEAN DEFAULT TRUE
);

-- Dimension: Product
CREATE TABLE IF NOT EXISTS dwh.dim_product (
    product_key     SERIAL PRIMARY KEY,
    product_id      INT NOT NULL,
    variant_id      INT,
    product_name    TEXT,
    category        TEXT,
    seller_id       INT,
    sku             TEXT,
    base_price      NUMERIC(12,2),
    -- SCD2
    effective_from  TIMESTAMPTZ NOT NULL,
    effective_to    TIMESTAMPTZ,
    is_current      BOOLEAN DEFAULT TRUE
);

-- Dimension: Payment Method
CREATE TABLE IF NOT EXISTS dwh.dim_payment_method (
    payment_method_key  SERIAL PRIMARY KEY,
    payment_method      TEXT UNIQUE
);

-- Dimension: Coupon
CREATE TABLE IF NOT EXISTS dwh.dim_coupon (
    coupon_key      SERIAL PRIMARY KEY,
    coupon_id       INT UNIQUE,
    code            TEXT,
    discount_type   TEXT,
    discount_value  NUMERIC(10,2)
);

-- Fact: Sales
CREATE TABLE IF NOT EXISTS dwh.fact_sales (
    fact_id             SERIAL PRIMARY KEY,
    order_item_id       INT UNIQUE,   -- natural key, prevents duplicates
    order_id            INT,
    date_key            INT REFERENCES dwh.dim_date(date_key),
    user_key            INT REFERENCES dwh.dim_user(user_key),
    seller_key          INT REFERENCES dwh.dim_seller(seller_key),
    product_key         INT REFERENCES dwh.dim_product(product_key),
    payment_method_key  INT REFERENCES dwh.dim_payment_method(payment_method_key),
    coupon_key          INT,
    -- Measures
    quantity            INT,
    unit_price          NUMERIC(12,2),
    gross_revenue       NUMERIC(12,2),
    discount_amount     NUMERIC(12,2),
    net_revenue         NUMERIC(12,2),
    commission_rate     NUMERIC(5,2),
    commission_amount   NUMERIC(12,2),
    seller_earnings     NUMERIC(12,2),
    shipping_cost       NUMERIC(12,2)
);