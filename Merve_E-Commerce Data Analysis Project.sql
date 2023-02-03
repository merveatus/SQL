/** E-Commerce Data and Customer Retention Analysis with SQL **/
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Ord_ID]
      ,[Cust_ID]
      ,[Prod_ID]
      ,[Ship_ID]
      ,[Order_Date]
      ,[Ship_Date]
      ,[Customer_Name]
      ,[Province]
      ,[Region]
      ,[Customer_Segment]
      ,[Sales]
      ,[Order_Quantity]
      ,[Order_Priority]
      ,[DaysTakenForShipping]
  FROM [eCommerce].[dbo].[ecom];

--General Overview:

SELECT * FROM ecom;

SELECT * FROM INFORMATION_SCHEMA.Columns WHERE TABLE_NAME = 'ecom';

--Format Change:

ALTER TABLE  ecom
	ALTER COLUMN order_quantity int; 

ALTER TABLE  ecom
	ALTER COLUMN DaysTakenForShipping int;

ALTER TABLE  ecom
	ALTER COLUMN sales int;

ALTER TABLE  ecom
	ALTER COLUMN order_date date;

ALTER TABLE  ecom
	ALTER COLUMN ship_date date;

/* A) Analyze the data by finding the answers to the questions below */
-- Question-A.1. Find the top 3 customers who have the maximum count of orders.SELECT 
	TOP 3 Cust_ID, COUNT(DISTINCT Ord_ID) total_order
FROM 
	ecom
GROUP BY 
	Cust_ID
ORDER BY 	total_order DESC;-- Question-A.2. Find the customer whose order took the maximum time to get shipping.

SELECT 
	TOP 1 Cust_ID
FROM 
	ecom
ORDER BY 
	DaysTakenForShipping DESC;

-- Question-A.3. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011.

WITH monthly_customers AS (
	SELECT Cust_ID, month(Order_Date) AS order_month
	FROM ecom
	WHERE year(Order_Date) = 2011
),
january_customers AS (
	SELECT Cust_ID
	FROM monthly_customers
	WHERE order_month = 1
)
SELECT
  COUNT(DISTINCT Cust_ID) AS total_unique_customers,
  (
    SELECT COUNT(DISTINCT Cust_ID)
    FROM january_customers
    WHERE Cust_ID IN (SELECT Cust_ID FROM monthly_customers)
  ) AS repeat_customers
FROM monthly_customers;

-- Question-A.4. Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID.

WITH Purchases AS (
  SELECT
    Cust_ID,
    Order_Date,
    ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS Purchase_Number
  FROM
    ecom
)
SELECT
  Cust_ID,
  DATEDIFF(DAY, MIN(CASE WHEN Purchase_Number = 1 THEN Order_Date END), MIN(CASE WHEN Purchase_Number = 3 THEN Order_Date END)) AS Elapsed_Time
FROM
  Purchases
GROUP BY
  Cust_ID
HAVING
  COUNT(CASE WHEN Purchase_Number = 3 THEN 1 END) = 1
ORDER BY
  Cust_ID;

-- Question-A.5. Write a query that returns customers who purchased both product 11 and product 14, as well as the ratio of these products to the total number of products purchased by the customer.
WITH CustomerPurchases AS (
  SELECT
    Cust_ID,
    Prod_ID,
    COUNT(*) OVER (PARTITION BY Cust_ID) AS Total_Products
  FROM
    ecom
)
SELECT
  Cust_ID,
  COUNT(CASE WHEN Prod_ID IN ('Prod_11', 'Prod_14') THEN 1 END) AS Specific_Products,
  COUNT(CASE WHEN Prod_ID IN ('Prod_11', 'Prod_14') THEN 1 END) / 
  CAST(Total_Products AS FLOAT) AS Ratio
FROM
  CustomerPurchases
GROUP BY
  Cust_ID, Total_Products
HAVING
  SUM(CASE WHEN Prod_ID = 'Prod_11' THEN 1 END) > 0 AND
  SUM(CASE WHEN Prod_ID = 'Prod_14' THEN 1 END) > 0;

/* B) Customer Segmentation
Categorize customers based on their frequency of visits. */

-- Question-B.1. Create a “view” that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)

CREATE VIEW customer_visits_monthly AS
SELECT Cust_ID, YEAR(Order_Date) AS year, MONTH(Order_Date) AS month
FROM ecom;

SELECT * FROM customer_visits_monthly
ORDER BY CAST(SUBSTRING(Cust_ID, PATINDEX('%[0-9]%', Cust_ID), LEN(Cust_ID)) AS INT);

--Alternative solution:
CREATE VIEW log AS (
    SELECT Cust_ID, YEAR(Order_Date) Year, MONTH(Order_Date) Month, DATENAME(MONTH, Order_Date) month_name
    FROM ecom
    GROUP BY Ord_ID, Cust_ID, Order_Date
)
CREATE VIEW log_distinct AS (
    SELECT DISTINCT Cust_ID, YEAR(Order_Date) Year, MONTH(Order_Date) Month
    FROM ecom
);

SELECT * FROM log
ORDER BY CAST(SUBSTRING(Cust_ID, PATINDEX('%[0-9]%', Cust_ID), LEN(Cust_ID)) AS INT);

-- Question-B.2. Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning business)

CREATE VIEW monthly_visits_count AS
SELECT Cust_ID, year, month, COUNT(*) AS visit_count
FROM customer_visits_monthly
GROUP BY Cust_ID, year, month;

SELECT * FROM monthly_visits_count
ORDER BY year, month;

-- Question-B.3 & 4:
--3. For each visit of customers, create the next month of the visit as a separate column.
--4. Calculate the monthly time gap between two consecutive visits by each customer.

WITH CTE AS (
    SELECT 
        Cust_ID, Order_Date,
        LEAD(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) next_visit
    FROM ecom
    GROUP BY Ord_ID, Cust_ID, Order_Date
)
SELECT
    *,
    DATEDIFF(MONTH, Order_Date, next_visit) gap
FROM CTE;

-- Question-B.5. Categorise customers using average time gaps. Choose the most fittedlabeling model for you.

WITH CTE AS (
    SELECT 
        Cust_ID, Order_Date,
        LEAD(Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) next_visit
    FROM ecom
    GROUP BY Ord_ID, Cust_ID, Order_Date
), CTE2 AS (
    SELECT *,
        DATEDIFF(MONTH, Order_Date, next_visit) gap
    FROM CTE
), CTE3 AS (
    SELECT *, 
        CASE WHEN gap <=1 THEN 'regular' WHEN gap <=3 THEN 'mid_regular' ELSE 'churn' END AS monthly_churn
    FROM CTE2
    WHERE gap IS NOT NULL
)
SELECT *
FROM CTE3;

/* C) Month-Wise Retention Rate
Find month-by-month customer retention rate since the start of the business. There are many different variations in the calculation of Retention Rate. But we will try to calculate the month-wise retention rate in this project. So, we will be interested in how many of the customers in the previous month could be retained in the next month.
Proceed step by step by creating “views”. You can use the view you got at the end of the Customer Segmentation section as a source.*/

-- Question-C.1. Find the number of customers retained month-wise. (You can use time gaps)

-- Unique customers per month
CREATE VIEW unique_customers_per_month AS
SELECT year, month, COUNT(DISTINCT Cust_ID) AS unique_customers
FROM customer_visits_monthly
GROUP BY year, month;

SELECT * FROM unique_customers_per_month
ORDER BY year, month;

-- Month-wise customer retention rate
CREATE VIEW customer_retention_rate AS
SELECT a.year, a.month, b.month AS next_month, (a.unique_customers * 1.0 / b.unique_customers) AS retention_rate
FROM unique_customers_per_month a
JOIN unique_customers_per_month b
ON a.year = b.year AND a.month + 1 = b.month;

SELECT * FROM customer_retention_rate
ORDER BY year, month;

-- Question-C.2. Calculate the month-wise retention rate.

SELECT year, month, ROUND(retention_rate * 100, 2) AS retention_rate_percent
FROM customer_retention_rate;


