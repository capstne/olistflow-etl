-- Star schema for OlistFlow ETL.
CREATE SCHEMA IF NOT EXISTS olistflow;

-- Dim: Customers
CREATE TABLE olistflow.dim_customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32),
    zip_code_prefix INTEGER,
    city VARCHAR(50),
    state CHAR(2)
);

-- Dim: Products
CREATE TABLE olistflow.dim_products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(50)
);

-- Dim: Sellers
CREATE TABLE olistflow.dim_sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(50),
    seller_state CHAR(2)
);

-- Fact: Orders
CREATE TABLE olistflow.fact_orders (
    order_id VARCHAR(32) PRIMARY KEY,
    order_date DATE NOT NULL,
    customer_id VARCHAR(32) REFERENCES olistflow.dim_customers(customer_id),
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(50),
    customer_state CHAR(2),
    total_price DECIMAL(10,2),
    total_freight DECIMAL(10,2),
    installments INTEGER,
    payment_count INTEGER,
    order_status VARCHAR(15),
    review_score DECIMAL(3,2)
);

-- Indexes for performance.
CREATE INDEX idx_fact_orders_date ON olistflow.fact_orders(order_date);
CREATE INDEX idx_fact_orders_customer ON olistflow.fact_orders(customer_id);
CREATE INDEX idx_fact_orders_status ON olistflow.fact_orders(order_status);