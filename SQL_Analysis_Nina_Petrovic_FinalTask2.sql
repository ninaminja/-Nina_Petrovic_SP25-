--1.Create a query to generate a report that identifies for each channel and throughout the entire period, the regions with the highest quantity of products sold (quantity_sold). 
--The resulting report should include the following columns:
--CHANNEL_DESC
--COUNTRY_REGION
--SALES: This column will display the number of products sold (quantity_sold) with two decimal places.
--SALES %: This column will show the percentage of maximum sales in the region (as displayed in the SALES column) compared to the total sales for that channel. The sales percentage should be displayed with two decimal places and include the percent sign (%) at the end.
--Display the result in descending order of SALES

WITH sales_summary AS (
    SELECT
        c.channel_desc AS channel_desc, --selecting sales channel description for reporting
        co.country_region AS country_region,  --selecting customer country region for grouping
        SUM(s.quantity_sold) AS quantity_sold, 
        SUM(s.amount_sold) AS amount_sold
    FROM
        sales s --joining needed TABLES here 
        JOIN channels c ON s.channel_id = c.channel_id
        JOIN customers cu ON s.cust_id = cu.cust_id
        JOIN countries co ON cu.country_id = co.country_id
    GROUP BY --AND GROUP BY channel AND region 
        c.channel_desc,
        co.country_region
),
channel_totals AS ( --I added this part too to get good results because otherwise i got 100% for every sales 
    SELECT
        channel_desc,
        SUM(quantity_sold) AS total_quantity
    FROM
        sales_summary
    GROUP BY
        channel_desc
),
region_rank AS (                --here is fixed part for ranked regions inside each channel
    SELECT  ss.*, t.total_quantity,
    RANK() OVER (PARTITION BY ss.channel_desc 
    			ORDER BY ss.quantity_sold DESC ) AS channel_rank
    FROM    sales_summary ss
    JOIN channel_totals t ON ss.channel_desc = t.channel_desc
)
SELECT
    channel_desc AS CHANNEL_DESC,
    country_region AS COUNTRY_REGION,
    --format quantity sold with 2 decimal places
    TO_CHAR(quantity_sold, '999,999,999') AS sales, --I fixed this part too, there is no more .99
    --calculate percentage of channel's total sales, as well using window functions for getting accurate data
    TO_CHAR(
        (quantity_sold / total_quantity) * 100, 
        '990.00') || '%' AS "SALES %"
FROM
   region_rank 
WHERE channel_rank  = 1
ORDER BY
    sales DESC;


--2.Identify the subcategories of products with consistently higher sales from 1998 to 2001 compared to the previous year. 
--Determine the sales for each subcategory from 1998 to 2001.
--Calculate the sales for the previous year for each subcategory.
--Identify subcategories where the sales from 1998 to 2001 are consistently higher than the previous year.
--Generate a dataset with a single column containing the identified prod_subcategory values.
WITH sales_data AS (
	SELECT 
		p.prod_subcategory ,
		EXTRACT (YEAR FROM t.time_id) AS sales_year,
		SUM(amount_sold) AS current_sales, 
		--Using LAG window function to get the previous year's sales per subcategory
		--we will partition by subcategory because we want to see them in report and order them by time
		LAG(SUM(amount_sold), 1) OVER (PARTITION BY p.prod_subcategory ORDER BY EXTRACT(YEAR FROM t.time_id)) AS prev_year_sales
	FROM sales s --joining TABLES so we can use them 
	JOIN products p ON s.prod_id = p.prod_id
	JOIN times t ON s.time_id = t.time_id
	WHERE 
		EXTRACT(YEAR FROM t.time_id) BETWEEN 1997 AND 2001 --FIRST we will choose 1997 because we must comapre 1998 TO that YEAR 
	GROUP BY 
		p.prod_subcategory, EXTRACT(YEAR FROM t.time_id)
),
filtered_data AS (
	SELECT 
		prod_subcategory,
		sales_year,
		current_sales,
		prev_year_sales,
		CASE 
			WHEN sales_year BETWEEN 1998 AND 2001 --AND here IS needed 1998 AND 2001
				AND current_sales > COALESCE (prev_year_sales,0) --flag years with growth (current year's sales > previous year's)
			THEN 1
			ELSE 0
		END AS year_with_growth
	FROM sales_data
),
consistent_growth AS (
    SELECT
        prod_subcategory
    FROM
        filtered_data
    WHERE
        sales_year BETWEEN 1998 AND 2001 --ONLY PERIOD BETWEEN 1998 AND 2001
    GROUP BY
        prod_subcategory
    HAVING
        COUNT(*) = 4 AND  --must have data for all 4 years
        SUM(year_with_growth) = 4  --must show growth every year
)
SELECT
    prod_subcategory AS consistently_growing_subcategories
FROM
    consistent_growth
ORDER BY
    prod_subcategory;

	
	
--3.Create a query to generate a sales report for the years 1999 and 2000, focusing on quarters and product categories. In the report you have to  analyze the sales of products from the categories 'Electronics,' 'Hardware,' and 'Software/Other,' across the distribution channels 'Partners' and 'Internet'.
--The resulting report should include the following columns:
--CALENDAR_YEAR: The calendar year
--CALENDAR_QUARTER_DESC: The quarter of the year
--PROD_CATEGORY: The product category
--SALES$: The sum of sales (amount_sold) for the product category and quarter with two decimal places
--DIFF_PERCENT: Indicates the percentage by which sales increased or decreased compared to the first quarter of the year. For the first quarter, the column value is 'N/A.' The percentage should be displayed with two decimal places and include the percent sign (%) at the end.
--CUM_SUM$: The cumulative sum of sales by quarters with two decimal places
--The final result should be sorted in ascending order based on two criteria: first by 'calendar_year,' then by 'calendar_quarter_desc'; and finally by 'sales' descending


	
--I found that this way is better, I got more accurate results regarding to photo 

WITH sales_aggregated AS (
    SELECT 
        EXTRACT(YEAR FROM t.time_id) AS calendar_year,
        t.calendar_quarter_desc,
        p.prod_category,
        SUM(s.amount_sold) AS total_amount_sold
    FROM sales s
    JOIN times t ON s.time_id = t.time_id
    JOIN products p ON s.prod_id = p.prod_id
    JOIN channels c ON s.channel_id = c.channel_id
    WHERE EXTRACT(YEAR FROM t.time_id) IN (1999, 2000)
    --filtering data to focus on specific years, channels and categories that are needed
    AND p.prod_category IN ('Electronics', 'Hardware', 'Software/Other')
    AND c.channel_desc IN ('Partners', 'Internet')
    GROUP BY 
        EXTRACT(YEAR FROM t.time_id),
        t.calendar_quarter_desc,
        p.prod_category --in the last query I had a problem because I was getting an error during the first group by, it could not be executed if I did not include s.amount_sold, that's why I did it this way now and I get a more correct result and I don't get an error
),
sales_report AS (
    SELECT 
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        ROUND(total_amount_sold, 2) AS SALES$,
        FIRST_VALUE(ROUND(total_amount_sold, 2)) OVER (
            PARTITION BY calendar_year, prod_category 
            ORDER BY calendar_quarter_desc
        ) AS first_quarter_sales,
        SUM(ROUND(total_amount_sold, 2)) OVER (
            PARTITION BY calendar_year, prod_category
            ORDER BY calendar_quarter_desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ----I tried to use here UNBOUNDED and because of it partition is visible and it will show us better result 
        ) AS cum_sum$
    FROM sales_aggregated
)
SELECT 
    calendar_year AS CALENDAR_YEAR,
    calendar_quarter_desc AS CALENDAR_QUARTER_DESC,
    prod_category AS PROD_CATEGORY,
    SALES$,
    CASE  --show 'N/A' for first quarter, for every else we will have adequat result
        WHEN calendar_quarter_desc LIKE '%-01' THEN 'N/A'
        ELSE CONCAT(ROUND((SALES$ - first_quarter_sales) / first_quarter_sales * 100, 2), '%')
    END AS DIFF_PERCENT,
    ROUND(cum_sum$, 2) AS CUM_SUM$
FROM sales_report 
ORDER BY 
    calendar_year, 
    calendar_quarter_desc, 
    SALES$ DESC; --fixed this part so now I can use sales$ IN ORDER BY


	