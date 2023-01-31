/*
RDB&SQL Assignment-3

**Discount Effects**
Generate a report including product IDs and discount effects on whether the increase in the discount rate positively impacts the number of orders for the products.

In this assignment, you are expected to generate a solution using SQL with a logical approach.

Product_id : 1, 2, 3, 4
Discount Effect: Positive, Negative, Negative, Neutral
*/

-- General view --

/*
SELECT *
FROM product.product

SELECT *
FROM sale.order_item

SELECT *
FROM sale.order_item
*/

-- Solution --

WITH t AS (
SELECT 
	DISTINCT product_id, discount, SUM(quantity) OVER(PARTITION BY product_id, discount) as total_quantity
FROM 
	sale.order_item),

t1 AS (
SELECT 
	*, AVG(total_quantity) OVER(PARTITION BY product_id ORDER BY product_id) as avg_quantity
FROM 
	t)

SELECT 
	DISTINCT *, 
CASE
	WHEN total_quantity > avg_quantity THEN 'Positive'
	WHEN total_quantity < avg_quantity THEN 'Negative' ELSE 'Neutral' END as discount_effect
FROM 
	t1
ORDER BY 
	product_id;