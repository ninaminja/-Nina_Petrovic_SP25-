--1. Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels.
-- This report should list the top 5 customers for each channel.
-- Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' which represents the percentage of a customer's sales relative to the total sales within their respective channel.

-- hope this is okay, I waited for this query to load but it couldn't, hope that this is better and fixed

-- select distinct combinations of channel_id and total_sales to get the top customers per channel
SELECT 
    cs.channel_desc,
    cs.cust_last_name,
    cs.cust_first_name,
    TO_CHAR(cs.total_sales, 'FM999999990.00') AS amount_sold,
    TO_CHAR(
        (cs.total_sales / ch.total_channel_sales) * 100,
        'FM99999990.0000'
    ) || ' %' AS sales_percentage
FROM (
    -- subquery to compute total sales per customer per channel
    -- this prepares grouped data needed to rank customers by sales in each channel
    SELECT 
        cu.cust_id,
        cu.cust_first_name,
        cu.cust_last_name,
        ch.channel_id,
        ch.channel_desc,
        SUM(sa.amount_sold) AS total_sales
    FROM 
        sales sa
        JOIN customers cu ON sa.cust_id = cu.cust_id
        JOIN channels ch ON sa.channel_id = ch.channel_id
    GROUP BY 
        cu.cust_id, cu.cust_first_name, cu.cust_last_name, ch.channel_id, ch.channel_desc
) cs
-- joining to get total sales per channel, so we can later calculate the percentage
JOIN (
    SELECT 
        ch.channel_id,
        SUM(s.amount_sold) AS total_channel_sales
    FROM 
        sales s
        JOIN channels ch ON s.channel_id = ch.channel_id
    GROUP BY 
        ch.channel_id
) ch ON cs.channel_id = ch.channel_id
-- filtering to only include the top 5 customers per channel
-- we use a correlated subquery with LIMIT 5
WHERE cs.cust_id IN (
    SELECT cu2.cust_id
    FROM 
        sales sa2
        JOIN customers cu2 ON sa2.cust_id = cu2.cust_id
    -- correlated to the outer cs.channel_id, ensures we only rank within the same channel
    WHERE sa2.channel_id = cs.channel_id
    GROUP BY cu2.cust_id
    ORDER BY SUM(sa2.amount_sold) DESC
    LIMIT 5  -- this LIMIT restricts the result to top 5 customers per channel
)
-- sort output by channel and then by sales amount (descending) for readability
ORDER BY 
    cs.channel_id, cs.total_sales DESC;



--2. Create a query to retrieve data for a report that displays the total sales for all products in the Photo category in the Asian region for the year 2000.
-- Calculate the overall report total and name it 'YEAR_SUM'

-- we include the tablefunc extension for crosstab functionality
-- this is executed only once
CREATE EXTENSION IF NOT ECISTS tablefunc;

-- main SELECT is using crosstab to form pivot table:
SELECT 
    prod_name,
    q1,
    q2,
    q3,
    q4,
    -- we will calculate quarterly values classic way
    ROUND(COALESCE(q1, 0) + COALESCE(q2, 0) + COALESCE(q3, 0) + COALESCE(q4, 0), 2) AS year_sum
FROM crosstab(
    $$
    -- this query returns by product and quarter total sales
    -- we avoid window functions by doing the classic GROUP BY by quarter
    SELECT 
        p.prod_name,
        t.calendar_quarter_desc,
        ROUND(SUM(s.amount_sold), 2) AS total_sales
    FROM 
        sales s
        JOIN products p ON s.prod_id = p.prod_id
        JOIN times t ON s.time_id = t.time_id
        JOIN customers c ON s.cust_id = c.cust_id
        JOIN countries co ON c.country_id = co.country_id
    WHERE 
        p.prod_category = 'Photo' -- we will filter just 'Photo' products
        AND co.country_region = 'Asia'    -- filter just 'Asia'
        AND t.calendar_year = 2000 -- filter just for 2000 year
    GROUP BY 
        p.prod_name, t.calendar_quarter_desc
    ORDER BY 
        p.prod_name, t.calendar_quarter_desc
    $$,
    $$ 
    -- we define the order of quarters used as columns in the pivot
    SELECT unnest(ARRAY['Q1', 'Q2', 'Q3', 'Q4']) 
    $$
) AS pivot_table (
    prod_name TEXT,
    q1 NUMERIC(10,2),
    q2 NUMERIC(10,2),
    q3 NUMERIC(10,2),
    q4 NUMERIC(10,2)
)
-- we sort by total sales for a year
ORDER BY 
    year_sum DESC;

--3.Create a query to generate a sales report for customers ranked in the top 300 based on total sales in the years 1998, 1999, and 2001.
-- The report should be categorized based on sales channels, and separate calculations should be performed for each channel.

-- sales report for top 300 customers by channel (1998, 1999, 2001)
SELECT 
    c.channel_desc,
    cust.cust_id,
    cust.cust_last_name,
    cust.cust_first_name,
    -- sum and round the amount sold for each customer per channel
    ROUND(SUM(s.amount_sold), 2) AS amount_sold
-- join necessary tables to access sales, customer, channel, and time data
FROM 
    sh.sales s
    JOIN sh.customers cust ON s.cust_id = cust.cust_id  -- join to get customer information
    JOIN sh.channels c ON s.channel_id = c.channel_id   -- join to get channel information
    JOIN sh.times t ON s.time_id = t.time_id            -- join to filter by calendar year
-- filter for sales from specific years and only include top 300 customers
WHERE 
    t.calendar_year IN (1998, 1999, 2001)
    -- use a subquery to filter only the top 300 customers by total sales over the selected years
    AND cust.cust_id IN (
        SELECT cust_id
        FROM (
            SELECT 
                s.cust_id,
                -- aggregate sales per customer across selected years
                SUM(s.amount_sold) AS total_sales
            FROM 
                sh.sales s
                JOIN sh.times t ON s.time_id = t.time_id
            WHERE 
                t.calendar_year IN (1998, 1999, 2001)
            GROUP BY 
                s.cust_id
            ORDER BY 
                total_sales DESC
            -- limit to top 300 customers based on total sales
            FETCH FIRST 300 ROWS ONLY
        ) top_customers
    )
-- grouping final results by channel and customer to prepare for aggregation
GROUP BY 
    c.channel_desc,
    cust.cust_id,
    cust.cust_last_name,
    cust.cust_first_name
-- order results by channel and descending sales amount within each channel
ORDER BY 
    c.channel_desc,
    amount_sold DESC;

--4. Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically for the Europe and Americas regions.
--Display the result by months and by product category in alphabetical order.

-- I fixed this part as well, now results looking better, like example

-- selecting the month description and product category for grouping and display
SELECT 
    t.calendar_month_desc AS month,
    p.prod_category AS product_category,
    SUM(s.amount_sold) AS total_sales
FROM 
    sh.sales s
-- joining with the times table to extract the calendar month of each sale
JOIN 
    sh.times t ON s.time_id = t.time_id
-- joining with the products table to classify sales by product category
JOIN 
    sh.products p ON s.prod_id = p.prod_id
-- joining with customers to trace each sale back to a customer's region
JOIN 
    sh.customers c ON s.cust_id = c.cust_id
-- joining with countries to access the region (Europe/Americas) of each customer
JOIN 
    sh.countries co ON c.country_id = co.country_id
-- filtering to only include sales made in the first three months of the year 2000
-- and only for customers in the Europe and Americas regions (i fixed this part so now i have them better displayed)
WHERE 
    t.calendar_month_desc IN ('2000-01', '2000-02', '2000-03')
    AND co.country_region IN ('Europe', 'Americas')
-- grouping by month and product category to calculate monthly category-level sales
GROUP BY 
    t.calendar_month_desc,
    p.prod_category
-- sorting first by month and then alphabetically by category for better readability
ORDER BY 
    month,
    product_category ASC;




