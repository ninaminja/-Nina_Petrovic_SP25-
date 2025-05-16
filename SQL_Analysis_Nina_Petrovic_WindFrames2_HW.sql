--1. Create a query for analyzing the annual sales data for the years 1999 to 2001, focusing on different sales channels and regions: 'Americas,' 'Asia,' and 'Europe.'

--The resulting report should contain the following columns:
--AMOUNT_SOLD: This column should show the total sales amount for each sales channel
--% BY CHANNELS: In this column, we should display the percentage of total sales for each channel (e.g. 100% - total sales for Americas in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
--% PREVIOUS PERIOD: This column should display the same percentage values as in the '% BY CHANNELS' column but for the previous year
--% DIFF: This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns, indicating the change in sales percentage from the previous year.
--The final result should be sorted in ascending order based on three criteria: first by 'country_region,' then by 'calendar_year,' and finally by 'channel_desc'



WITH sales_data AS (
    SELECT 
        cnt.country_region,
        t.calendar_year,
        ch.channel_desc,
        --and total sales volume by channel, region and year
        SUM(s.amount_sold) AS amount_sold,
        --calculates total sales by region and year (window function)
        SUM(SUM(s.amount_sold)) OVER (PARTITION BY cnt.country_region, t.calendar_year) AS total_region_year
    FROM 
        sales s
        JOIN channels ch ON s.channel_id = ch.channel_id --join to get channel descriptions
        JOIN customers cust ON s.cust_id = cust.cust_id --join to get customer data
        JOIN countries cnt ON cust.country_id = cnt.country_id --join to get region info
        JOIN times t ON s.time_id = t.time_id --join to get date information
    WHERE 
        t.calendar_year BETWEEN 1999 AND 2001 --filter for specific years
        AND cnt.country_region IN ('Americas', 'Asia', 'Europe') --filter for specific regions
    GROUP BY 
        cnt.country_region, t.calendar_year, ch.channel_desc
),
with_percentage AS (
    SELECT 
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        CASE 
	        --calculates the share of sales by channel in relation to total sales in the region for that year 
	        --if the total sales in the region is 0, the share is set to 0
            WHEN total_region_year = 0 THEN 0
            ELSE ROUND((amount_sold / total_region_year) * 100, 2)
        END AS percent_by_channels
    FROM 
        sales_data
),
final_data AS ( --here the values ​​for the previous period and the percentage difference between the current and previous period are calculated
    SELECT 
        w.country_region,
        w.calendar_year,
        w.channel_desc,
        w.amount_sold,
        w.percent_by_channels AS "% BY CHANNELS", --current period percentage
        --uses the LAG function to calculate the share of sales for the previous year for the same channel and region
        LAG(w.percent_by_channels, 1) OVER (
            PARTITION BY w.country_region, w.channel_desc 
            ORDER BY w.calendar_year
        ) AS "% PREVIOUS PERIOD",
        --calculates the percentage difference between the current year and the previous year
        ROUND(w.percent_by_channels - LAG(w.percent_by_channels, 1) OVER (
            PARTITION BY w.country_region, w.channel_desc 
            ORDER BY w.calendar_year
        ), 2) AS "% DIFF"
    FROM 
        with_percentage w
)
SELECT 
    country_region,
    calendar_year,
    channel_desc,
    amount_sold,
    "% BY CHANNELS", --share of sales by channel, expressed as a percentage
    "% PREVIOUS PERIOD",
    "% DIFF" --difference between current and previous period in percentage
FROM 
    final_data
ORDER BY --sorts them by region, year and channel
    country_region ASC,
    calendar_year ASC,
    channel_desc ASC;



--2.You need to create a query that meets the following requirements:

--Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
--Include a column named CUM_SUM to display the amounts accumulated during each week.
--Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, current, and following days using a centered moving average.
--For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) as well as Monday and Tuesday.
--For Friday, calculate the average sales on Thursday, Friday, and the weekend.

--here 2 task fixed 

WITH expanded_sales AS (
    SELECT 
        t.calendar_week_number,
        t.time_id,
        t.day_name,
        COALESCE(SUM(s.amount_sold), 0) AS sales
    FROM 
        times t
        LEFT JOIN sales s ON t.time_id = s.time_id 
    WHERE --i tried this way TO INCLUDE weeks FROM 48 TO 52 so later ill FILTER them TO needed weeks 
        t.calendar_week_number BETWEEN 48 AND 52  
        AND EXTRACT(YEAR FROM t.time_id) = 1999
    GROUP BY 
        t.calendar_week_number, t.time_id, t.day_name
), --this IS the part WHERE i'll INCLUDE everything FROM FIRST CTE AND ADD good weeks that we need 
filtered_sales AS (
    SELECT * FROM expanded_sales WHERE calendar_week_number IN (49, 50, 51) 
)
SELECT 
    calendar_week_number,
    time_id,
    day_name,
    sales,
    SUM(sales) OVER (
        PARTITION BY calendar_week_number 
        ORDER BY time_id
    ) AS cum_sum,
    CASE    --centered 3-day average with special cases for Monday/Friday
        WHEN day_name = 'Monday' THEN 
            ROUND(( --i added COALESCE TO solve NULL results 
                COALESCE(LAG(sales, 2) OVER (ORDER BY time_id), 0) +  
                COALESCE(LAG(sales, 1) OVER (ORDER BY time_id), 0) +  
                sales +                                  
                COALESCE(LEAD(sales, 1) OVER (ORDER BY time_id), 0)   
            ) / 4, 2)
        WHEN day_name = 'Friday' THEN 
            ROUND((
                COALESCE(LAG(sales, 1) OVER (ORDER BY time_id), 0) +  
                sales +                                  
                COALESCE(LEAD(sales, 1) OVER (ORDER BY time_id), 0) +  
                COALESCE(LEAD(sales, 2) OVER (ORDER BY time_id), 0)   
            ) / 4, 2)
        ELSE 
            ROUND((
                COALESCE(LAG(sales, 1) OVER (ORDER BY time_id), 0) +
                sales +
                COALESCE(LEAD(sales, 1) OVER (ORDER BY time_id), 0)
            ) / 3, 2)
    END AS centered_3_day_avg
FROM 
    filtered_sales
ORDER BY 
    time_id;
        
        
        
--3. Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes. 
--Additionally, explain the reason for choosing a specific frame type for each example. 
--This can be presented as a single query or as three distinct queries.


--ROWS
--to calculate the cumulative sum (running total) amount_sold for each customer (cust_id), in the order of time_id
--ROWS is perfect when we need physical accumulation row by row regardless of duplicate values ​​in the order column
SELECT 
    cust_id,
    time_id,
    amount_sold,
    AVG(amount_sold) OVER (
        PARTITION BY cust_id
        ORDER BY time_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS purchase_avg
FROM sales;

--RANGE
--Compare customer spending patterns across countries with monthly rolling averages
--i think that RANGE is pretty useful in this type of query because it will gruop by time (date) and shows us groups of needed dates for each country
SELECT 
    c.country_id,
    s.time_id,
    s.amount_sold,
    AVG(s.amount_sold) OVER (
        PARTITION BY c.country_id
        ORDER BY s.time_id
        RANGE BETWEEN INTERVAL '30' DAY PRECEDING AND CURRENT ROW
    ) AS monthly_avg_by_country
FROM sales s
JOIN customers c ON s.cust_id = c.cust_id;


--GROUP
--sums the amount_sold values ​​to the current value, but if multiple rows have the same value
-- they are all considered a "peer group" and included together
SELECT 
    prod_id,
    time_id,
    amount_sold,
    SUM(amount_sold) OVER (
        PARTITION BY prod_id
        ORDER BY amount_sold
        GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_by_groups
FROM sales;



