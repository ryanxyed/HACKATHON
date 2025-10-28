-- ------------------------------------------------------------------------------------
-- gross revenue vs net revenue
-- -------------------------------------------------------------------------------------
    
select 
	sum(order_value) as gross_revenue,
    sum(order_value)-sum(refund_amount) as net_revenue
from 
	OLAP;
    
-- --------------------------------------------------------------------------------------------------------------------------    
-- 2.Customer cohort analysis (retention) — cohort by signup month:
-- % retained and % repeat purchasers over 3, 6, 12 months.
-- ---------------------------------------------------------------------------------------------------------------------------

WITH CustomerCohorts AS (
    -- Step 1: Define each customer's cohort month (month of first purchase/signup)
    -- We use the first day of the month for easy date truncation and comparison
    SELECT
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS cohort_month
    FROM
        OLAP
    GROUP BY
        customer_id
),
MonthlyActivity AS (
    -- Step 2: Identify every month a customer made a purchase after their cohort month
    SELECT
        o.customer_id,
        c.cohort_month,
        -- Calculate the month index: 0 = cohort month, 1 = next month, etc.
        TIMESTAMPDIFF(MONTH, CAST(c.cohort_month AS DATE), CAST(DATE_FORMAT(o.order_date, '%Y-%m-01') AS DATE)) AS cohort_index
    FROM
        OLAP AS o
    JOIN
        CustomerCohorts AS c ON o.customer_id = c.customer_id
    GROUP BY
        o.customer_id, c.cohort_month, cohort_index -- Ensure we count each customer once per month
),
CohortAggregation AS (
    -- Step 3: Count the number of unique customers active for each cohort month and index
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_id) AS retained_customers_count
    FROM
        MonthlyActivity
    GROUP BY
        cohort_month, cohort_index
),
CohortSize AS (
    -- Step 4: Get the initial size of each cohort (Month 0 count)
    SELECT
        cohort_month,
        retained_customers_count AS total_cohort_customers
    FROM
        CohortAggregation
    WHERE
        cohort_index = 0
)
-- Step 5: Pivot the data to display the retention rates for specific months (3, 6, 12)
SELECT
    ca.cohort_month,
    cs.total_cohort_customers AS cohort_size,
    -- Retention rate calculation: (Retained users / Total cohort size) * 100.0
    ROUND((SUM(CASE WHEN ca.cohort_index = 3 THEN ca.retained_customers_count ELSE 0 END) * 100.0 / cs.total_cohort_customers), 2) AS M3_Retention_Pct,
    ROUND((SUM(CASE WHEN ca.cohort_index = 6 THEN ca.retained_customers_count ELSE 0 END) * 100.0 / cs.total_cohort_customers), 2) AS M6_Retention_Pct,
    ROUND((SUM(CASE WHEN ca.cohort_index = 12 THEN ca.retained_customers_count ELSE 0 END) * 100.0 / cs.total_cohort_customers), 2) AS M12_Retention_Pct -- Represents the start of the 12th month after the cohort month
FROM
    CohortAggregation AS ca
JOIN
    CohortSize AS cs ON ca.cohort_month = cs.cohort_month
GROUP BY
    ca.cohort_month, cs.total_cohort_customers
ORDER BY
    ca.cohort_month DESC;



-- ----------------------------------------------------------------------
-- 3.Revenue recognition comparison — compute monthly
-- revenue by order/payment/delivered date and argue which is correct.
-- -----------------------------------------------------------------------

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    SUM(amount) AS revenue_order_date
FROM
    OLAP
GROUP BY
    sales_month
ORDER BY
    sales_month;
    


SELECT
    DATE_FORMAT(payment_date, '%Y-%m') AS payment_month,
    SUM(amount) AS revenue_payment_date
FROM
    OLAP
WHERE
    payment_date IS NOT NULL -- Exclude orders that haven't been paid yet
GROUP BY
    payment_month
ORDER BY
    payment_month;

