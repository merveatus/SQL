--RDB&SQL Assignment-2

/*
1. Product Sales
You need to create a report on whether customers who purchased the product named '2TB Red 5400 rpm SATA III 3.5 Internal NAS HDD' buy the product below or not.

1. 'Polk Audio - 50 W Woofer - Black' -- (other_product)
*/

CREATE VIEW customer_product AS
SELECT c.customer_id, c.first_name, c.last_name, p.product_name
FROM sale.customer c
INNER JOIN sale.orders o ON c.customer_id=o.customer_id
INNER JOIN sale.order_item oi ON o.order_id=oi.order_id
INNER JOIN product.product p ON oi.product_id=p.product_id

SELECT DISTINCT customer_id, first_name, last_name,
	CASE
		WHEN product_name='Polk Audio - 50 W Woofer - Black' THEN 'Yes'
		WHEN product_name!='Polk Audio - 50 W Woofer - Black' THEN 'No' END other_product
FROM customer_product
WHERE customer_id IN
		(SELECT DISTINCT customer_id
		FROM customer_product
		WHERE product_name = '2TB Red 5400 rpm SATA III 3.5 Internal NAS HDD')
ORDER BY customer_id

/*
2. Conversion Rate
Below you see a table of the actions of customers visiting the website by clicking on two different types of advertisements given by an E-Commerce company. Write a query to return the conversion rate for each Advertisement type.
*/

--a. Create above table (Actions) and insert values,

CREATE TABLE Actions (
   Visitor_ID INT PRIMARY KEY,
   Adv_Type VARCHAR(255) NOT NULL,
   Action VARCHAR(255) NOT NULL
);

INSERT INTO Actions(Visitor_ID, Adv_Type, Action)
VALUES (1, 'A', 'Left'),
(2, 'A', 'Order'),
(3, 'B', 'Left'),
(4, 'A', 'Order'),
(5, 'A', 'Review'),
(6, 'A', 'Left'),
(7, 'B', 'Left'),
(8, 'B', 'Order'),
(9, 'B', 'Review'),
(10, 'A', 'Review');

SELECT *
FROM Actions


--b. Retrieve count of total Actions and Orders for each Advertisement Type,

CREATE VIEW total_action_order AS
SELECT *,
	CASE 
		WHEN Action='Order' THEN 1 ELSE 0 END order_status
FROM Actions

SELECT Adv_Type, COUNT(Action) total_action, SUM(order_status) total_order
FROM total_action_order
GROUP BY Adv_Type


--c. Calculate Orders (Conversion) rates for each Advertisement Type by dividing by total count of actions casting as float by multiplying by 1.0.

SELECT Adv_Type, CONVERT(DECIMAL(2,2), SUM(order_status)*1.0/COUNT(Action)) 'Conversion_Rate'
FROM total_action_order
GROUP BY Adv_Type;






