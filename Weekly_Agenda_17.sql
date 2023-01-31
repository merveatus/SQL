--Weekly_Agenda_17

----1. Select the least 3 products in stock according to stores.

WITH CTE AS (
	SELECT*, DENSE_RANK () OVER (PARTITION BY store_id ORDER BY quantity) AS rank_
	FROM product.stock
	WHERE quantity > 0
	)
SELECT * FROM CTE
WHERE rank_ in (1, 2, 3);

------------

WITH CTE AS (
	SELECT*, row_number () OVER (PARTITION BY store_id ORDER BY quantity) AS rank_
	FROM product.stock
	WHERE quantity > 0
	)
SELECT * FROM CTE
WHERE rank_ in (1, 2, 3);

----2. Return the average number of sales orders in 2020 sales.

SELECT *
FROM sale.orders
WHERE YEAR(order_date) = 2020;

WITH CTE AS (
	SELECT order_id, COUNT(item_id) total_item, SUM(quantity) total_quantity
	FROM sale.order_item
	WHERE order_id in (
		SELECT order_id
		FROM sale.orders
		WHERE YEAR(order_date) = 2020)
	GROUP BY order_id)
SELECT 2020 AS year_, 
	AVG(total_item * 1.0) AS avg_total_item,
	AVG(total_quantity * 1.0) AS avg_total_quantity 
FROM CTE;

----3. Assign a rank to each product by list price in each brand and get products with rank less than or equal to three.

WITH CTE AS (	SELECT *, dense_rank () OVER (PARTITION BY brand_id ORDER BY list_price DESC) AS rank_	FROM product.product	)	SELECT * FROM CTE	WHERE rank_ <= 3;

--------

WITH ranked_products AS ( 
	SELECT DISTINCT (p.product_id) ,p.brand_id, o.list_price, DENSE_RANK() OVER(PARTITION BY  p.brand_id ORDER BY o.list_price) AS denserank
	FROM sale.order_item o join product.product p on o.product_id=p.product_id)
SELECT product_id, brand_id,list_price,denserank 
FROM ranked_products
WHERE denserank <= 3;

----4. Write a query that returns the highest daily turnover amount for each week on a yearly basis.

WITH cte AS(
	SELECT 
		DISTINCT
		DATEPART(YEAR, a.order_date) order_year,
		DATEPART(WEEK, a.order_date) order_week,
		SUM(b.quantity * b.list_price * (1-b.discount)) OVER(PARTITION BY a.order_date) daily_turnover
	FROM
		sale.orders a
		LEFT JOIN
		sale.order_item b ON a.order_id=b.order_id
)
SELECT
	DISTINCT
	order_year,order_week,
	MAX(daily_turnover) OVER(PARTITION BY order_year, order_week) highest_turnover
FROM
	cte;

-----with group by

SELECT 
	DISTINCT
	YEAR(a.order_date) order_year,
	DATEPART(ISOWW, a.order_date) order_week,
	FIRST_VALUE(SUM(b.quantity * b.list_price * (1-b.discount))) OVER(
			PARTITION BY YEAR(a.order_date), DATEPART(ISOWW, a.order_date)
			ORDER BY SUM(b.quantity * b.list_price * (1-b.discount)) DESC) highest_turnover
FROM
	sale.orders a
	LEFT JOIN
	sale.order_item b ON a.order_id=b.order_id
GROUP BY
	a.order_date;

----5. Write a query that returns the cumulative distribution of the list price in product table by brand.
​
SELECT
	brand_id, list_price,
	ROUND(CUME_DIST() OVER(PARTITION BY brand_id ORDER BY list_price), 3) cume_distr
FROM
	product.product;

----6. Write a query that returns the relative standing of the list price in the product table by brand.

SELECT
	brand_id, list_price, product_id, product_name, list_price,
	FORMAT(ROUND(PERCENT_RANK() OVER(PARTITION BY brand_id ORDER BY list_price), 3), 'P') percent_rnk
FROM
	product.product;

----7. Divide customers into 5 groups based on the quantity of product they order.

WITH T1 AS(	SELECT customer_id, SUM(quantity) AS total_quantity	FROM sale.order_item AS o	JOIN sale.orders AS b	ON o.order_id = b.order_id	GROUP BY b.customer_id	)SELECT *, NTILE(5)  OVER(ORDER BY total_quantity) AS  group_distFROM T1ORDER BY 2, 3 DESC;

--------

WITH t1 AS
(
SELECT A.customer_id, SUM(quantity) product_quantity
FROM sale.orders A, sale.order_item B
WHERE A.order_id=B.order_id
GROUP BY A.customer_id
)
SELECT customer_id, product_quantity,
       NTILE(5) OVER(ORDER BY product_quantity) group_dist
FROM t1
ORDER BY 2,3 DESC;

----8. List customers whose have at least 2 consecutive orders are not shipped.

WITH t2 AS (		SELECT customer_id, order_date, shipped_date, LEAD (shipped_date) OVER(PARTITION BY customer_id ORDER BY order_date) AS next_shipped_date		FROM sale.orders		),		t3 AS(		SELECT *, row_number() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rank_		FROM t2		)SELECT DISTINCT customer_id FROM t3WHERE rank_ != 1 and  shipped_date is null and next_shipped_date is null;

---------

;WITH t1 AS(
	SELECT
		order_id, customer_id, order_date, shipped_date,
		CASE WHEN shipped_date IS NULL THEN 'not delivered' ELSE 'delivered' END delivery_status
	FROM
		sale.orders
), t2 AS(
	SELECT *,
		LEAD(delivery_status) OVER(PARTITION BY customer_id ORDER BY order_id) next_delivery_status
	FROM
		t1
)
SELECT
	customer_id
FROM
	t2
WHERE
	delivery_status='not delivered' AND next_delivery_status='not delivered';
​​
----------
​
SELECT customer_id
FROM(
	SELECT
		order_id, customer_id, order_date, shipped_date,
		CASE WHEN shipped_date IS NULL THEN 'not delivered' ELSE 'delivered' END delivery_status,
		LEAD(CASE WHEN shipped_date IS NULL THEN 'not delivered' ELSE 'delivered' END) OVER(
			PARTITION BY customer_id ORDER BY order_date) next_delivery_status
	FROM
		sale.orders
) t
WHERE 
	delivery_status='not delivered' AND next_delivery_status='not delivered';
