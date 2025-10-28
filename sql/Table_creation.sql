use OLTP;
select * from bundle_items;
select * from customers;
select * from products;
select * from payments;
select * from returns;
select * from orders;
select * from order_items;
select * from returns;

drop database Team6;
create database Team6;
use Team6;

-- Finalized Star Schema Model

-- 1. Dimension Table for Customers
CREATE TABLE dim_customers(
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(100),
    signup_date date
);

-- 2. Dimension Table for Products
CREATE TABLE dim_products(
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    product_category VARCHAR(100),
    price DECIMAL(12,2)
);

-- 3. Dimension Table for Payment Methods (Descriptive attributes only)
CREATE TABLE dim_payments(
   payment_id int primary key,
   order_id int,
   payment_method varchar(50),
   amount decimal(12,2),
   payment_date date
);

-- 4. Dimension Table for Dates (Surrogate key 'date_id' is primary key)
CREATE TABLE dim_date( -- e.g., an integer like 20251020
    order_id int primary key,-- Renamed for clarity from payment_date
    days VARCHAR(30),
    weeks DECIMAL(12,2),
    months VARCHAR(30),
    quarters DECIMAL(12,2)
);

create table dim_order_items(
	order_item_id int primary key,
    order_id int,
    product_id int,
    unit_price decimal(12,2),
    quantity decimal(12,2),
    line_total decimal(12,2)
);

create table dim_returns(
return_id int primary key,
order_id int references fact_sales(orders),
return_date date,
refund_amount decimal(12,2)
);


-- 5. Central Fact Table for Sales (Grain: One row per order)
CREATE TABLE fact_sales (
order_id int primary key,
customer_id int references dim_customers(customer_id),
order_date date,
status varchar(20),
order_value decimal(12,2),
product_id int references dim_products(product_id),
order_item_id int references dim_order_item(order_item_id),
payment_id int references dim_payments(payment_id),
return_id int references dim_returns(return_id)
);
