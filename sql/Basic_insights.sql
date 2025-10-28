
select * from fact_sales;

create view OLAP AS
select 
	fs.*,
	dc.customer_name,
    dc.phone,
    dc.city,
    dc.state,
    dc.signup_date,
	dd.days ,
    dd.weeks ,
    dd.months ,
    dd.quarters ,
    dpr.product_name,
    dpr.product_category,
    dpr.price,
    oi.unit_price,
    oi.quantity,
    oi.line_total,
    p.payment_method,
    p.amount,
    p.payment_date,
    r.return_date,
	r.refund_amount 
from fact_sales fs 
left join dim_customers dc on dc.customer_id= fs.customer_id
join dim_date dd on fs.payment_id=dd.order_id
join dim_products dpr on fs.product_id=dpr.product_id
join dim_order_items oi on fs.order_item_id=oi.order_item_id
join dim_payments p on fs.payment_id=p.payment_id
left join dim_returns r on fs.return_id=r.return_id;


create view fact_order_items as
select oi.*,p.product_name,p.product_category,p.price,dd.days,dd.weeks,dd.months,dd.quarters,fs.order_date
from dim_order_items oi
left join dim_products p on p.product_id=oi.product_id
left join dim_date dd on oi.order_id=dd.order_id
join fact_sales fs on fs.order_id=oi.order_id;

select * from OLAP;


-- ****************
-- 1.
-- ****************

-- ----------------------------------------------------------------------
-- INSIGHTS DAILY REVENUE, NUMBER OF ORDERS, AVERAGE ORDER VALUES
-- --------------------------------------------------------------------------

SELECT
    CAST(order_date AS DATE) AS day,
    SUM(amount) AS daily_revenue,
    COUNT(order_id) AS daily_orders,
    AVG(amount) AS daily_aov
FROM
    OLAP
GROUP BY
    CAST(order_date AS DATE);
    
    
-- ----------------------------------------------------------------
-- INSIGHTS WEEKLY REVENUE, NUMBER OF ORDERS, AVERAGE ORDER VALUES
-- ----------------------------------------------------------------

SELECT
    weeks AS week,
    SUM(amount) AS weekly_revenue,
    COUNT(order_id) AS weekly_orders,
    AVG(amount) AS weekly_aov
FROM
    OLAP
GROUP BY
    weeks
ORDER BY weeks;
    
-- ----------------------------------------------------------------
-- INSIGHTS MONTHLY REVENUE, NUMBER OF ORDERS, AVERAGE ORDER VALUES
-- ----------------------------------------------------------------

SELECT
    months AS month,
    SUM(amount) AS monthly_revenue,
    COUNT(order_id) AS monthly_orders,
    AVG(amount) AS monthly_aov
FROM
    OLAP
GROUP BY
    months;


-- ----------------------------------------------------------------
-- 2. Top 10 products by revenue
-- ----------------------------------------------------------------

SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM
    dim_products AS p
JOIN
    dim_order_items AS oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id, p.product_name
ORDER BY
    total_revenue DESC
LIMIT 10;


-- -----------------------------------------------------------------------
-- 3.TOP CITIES BY REVENUE
-- -----------------------------------------------------------------------

select 
	city,
    sum(amount) as total_revenue,
    count(order_id) as number_of_orders 
from OLAP
group by city
order by total_revenue;


-- ------------------------------------------------------------------------------------------------
-- 4.Revenue by category & month — show a month × category pivot (heatmap) and identify seasonality.
-- ------------------------------------------------------------------------------------------------

SELECT
	product_category,
    SUM(CASE WHEN MONTH(order_date) = 1 THEN quantity ELSE 0 END) AS 'Jan',
    SUM(CASE WHEN MONTH(order_date) = 2 THEN quantity ELSE 0 END) AS 'Feb',
    SUM(CASE WHEN MONTH(order_date) = 3 THEN quantity ELSE 0 END) AS 'Mar',
    SUM(CASE WHEN MONTH(order_date) = 4 THEN quantity ELSE 0 END) AS 'Apr',
    SUM(CASE WHEN MONTH(order_date) = 5 THEN quantity ELSE 0 END) AS 'May',
    SUM(CASE WHEN MONTH(order_date) = 6 THEN quantity ELSE 0 END) AS 'Jun',
    SUM(CASE WHEN MONTH(order_date) = 7 THEN quantity ELSE 0 END) AS 'Jul',
    SUM(CASE WHEN MONTH(order_date) = 8 THEN quantity ELSE 0 END) AS 'Aug',
    SUM(CASE WHEN MONTH(order_date) = 9 THEN quantity ELSE 0 END) AS 'Sep',
    SUM(CASE WHEN MONTH(order_date) = 10 THEN quantity ELSE 0 END) AS 'Oct',
    SUM(CASE WHEN MONTH(order_date) = 11 THEN quantity ELSE 0 END) AS 'Nov',
    SUM(CASE WHEN MONTH(order_date) = 12 THEN quantity ELSE 0 END) AS 'Dec'
FROM
    fact_order_items
GROUP BY
    product_category
ORDER BY
    product_category;
    
-- check
select sum(quantity),product_category
from fact_order_items
where months like "January"
group by product_category;

-- ------------------------------------------------------------------------------
--  5. payment method analysis
-- -------------------------------------------------------------------------------

select
	payment_method,
	count(return_id) as number_of_returns,
    AVG(order_value)
from OLAP
group by payment_method
order by number_of_returns desc;

-- -------------------------------------------------------------------------------------------
-- 6. new customers revenue percentage vs Repeated customers revenue percentage
-- -------------------------------------------------------------------------------------------

WITH CustomerPurchaseCounts AS (
    -- Step 1: Count the total number of orders for each customer across the entire dataset
    SELECT
        customer_id,
        COUNT(order_id) AS total_purchase_count
    FROM
        OLAP
    GROUP BY
        customer_id
),
CustomerTypeRevenue AS (
    -- Step 2: Join purchase counts back to the main data and sum revenues based on customer type
    SELECT
        SUM(o.amount) AS total_gross_revenue,
        SUM(CASE WHEN cpc.total_purchase_count > 1 THEN o.amount ELSE 0 END) AS repeat_customer_revenue,
        SUM(CASE WHEN cpc.total_purchase_count = 1 THEN o.amount ELSE 0 END) AS new_customer_revenue
    FROM
        OLAP AS o
    JOIN
        CustomerPurchaseCounts AS cpc ON o.customer_id = cpc.customer_id
)
-- Step 3: Calculate the final percentages in a single row
SELECT
    (repeat_customer_revenue * 100.0 / total_gross_revenue) AS percentage_revenue_repeat_customers,
    (new_customer_revenue * 100.0 / total_gross_revenue) AS percentage_revenue_new_customers
FROM
    CustomerTypeRevenue;

-- --------------------------------------------------------------------------------------
-- 7. AVERAGE ORDER VALUE
-- --------------------------------------------------------------------------------------

select 
	sum(amount)/count(order_id) as AOV
from
	OLAP;
    
-- ----------------------------------------------------------------------------------------    
-- 8. REVENUE BY STATE
-- ----------------------------------------------------------------------------------------

select 
	state,
    sum(amount) as Revenue_by_state
from 
	OLAP
group by 
	state
Order by 
	Revenue_by_state;
    
-- no channel given