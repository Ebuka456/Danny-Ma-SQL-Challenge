-- Danny Ma SQL Challenge: Danny's Dinner

-- Creating Database and Creating the Tables in the database

DROP DATABASE IF EXISTS dannys_diner; -- delete the database if it exists

CREATE DATABASE dannys_diner; -- creates the database

USE dannys_diner; -- sets the database as the default database


-- creating the menu table
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

-- inserting values into the menu table
INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
  
-- creating the members table
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

-- inserting values into the menu table
INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
-- creating the sales table
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
 );

-- inserting values into the sales table
INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

-- CASE STUDY QUESTIONS

-- QUESTION 1: What is the total amount each customer spent at the restaurant?
SELECT s.customer_id,
	   SUM(m.price) AS total_amount_spent
FROM sales AS s
     INNER JOIN menu m 
     USING(product_id)
GROUP BY s.customer_id
ORDER BY total_amount_spent DESC;

-- QUESTION 2: How many days has each customer visited the restaurant?
SELECT customer_id,
	   COUNT(DISTINCT order_date) AS number_of_days
FROM sales
GROUP BY customer_id
ORDER BY number_of_days DESC;


-- QUESTION 3: What was the first item from the menu purchased by each customer?
WITH first_purchase AS(
	 SELECT customer_id,
			MIN(order_date) AS min_date
	 FROM sales 
     GROUP BY customer_id
     )
SELECT DISTINCT s.customer_id,
	   f.min_date,
       s.product_id,
       m.product_name
FROM sales AS s
	 INNER JOIN first_purchase AS f
		ON f.customer_id = s.customer_id 
		AND f.min_date = s.order_date
	 INNER JOIN menu m 
		ON m.product_id = s.product_id
ORDER BY s.customer_id;


-- QUESTION 4: What is the most purchased item on the menu and how many times 
-- was it purchased by all customers?
SELECT m.product_id,
	   m.product_name,
	   COUNT(*) AS number_of_orders
FROM sales AS s 
	 INNER JOIN menu m
     USING(product_id)
GROUP BY m.product_id, 
		 m.product_name
ORDER BY number_of_orders DESC
LIMIT 1;


-- QUESTION 5: Which item was the most popular for each customer?
SELECT customer_id,
	   product_name
FROM(
	SELECT s.customer_id,
		   m.product_name,
		   COUNT(*) AS number_of_orders,
		   RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS row_num
	FROM sales AS s 
		 INNER JOIN menu m
		 USING(product_id)
	GROUP BY s.customer_id, 
			 m.product_name
) AS pop
WHERE row_num = 1
ORDER BY customer_id;


-- QUESTION 6: Which item was purchased first by the customer after they became a member?
SELECT * from members;
select * from sales;
select * from menu;


SELECT customer_id,
	   product_name
FROM(
	SELECT s.customer_id,
		   s.order_date,
		   m.join_date,
		   s.product_id,
		   me.product_name,
		   ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS row_num
	FROM sales AS s
		 INNER JOIN members m 
		 ON m.customer_id = s.customer_id
		 AND m.join_date < s.order_date
		 INNER JOIN menu me 
		 ON me.product_id = s.product_id
	) AS first_purchase
WHERE row_num = 1
ORDER BY customer_id;


-- QUESTION 7: Which item was purchased just before the customer became a member?

SELECT customer_id,
	   product_name
FROM(
	SELECT s.customer_id,
		   s.order_date,
		   m.join_date,
		   s.product_id,
		   me.product_name,
		   RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS ranks
	FROM sales AS s
		 INNER JOIN members m 
		 ON m.customer_id = s.customer_id
		 AND m.join_date > s.order_date
		 INNER JOIN menu me 
		 ON me.product_id = s.product_id
	) AS last_purchase
WHERE ranks = 1
ORDER BY customer_id;


-- QUESTION 8: What is the total items and amount spent for each member before they became a member?

WITH previous_sales AS(
	SELECT s.customer_id,
		   s.order_date,
		   m.join_date,
		   s.product_id,
		   me.product_name,
		   me.price
	FROM sales AS s
		 INNER JOIN members m 
		 ON m.customer_id = s.customer_id
		 AND m.join_date > s.order_date
		 INNER JOIN menu me 
		 ON me.product_id = s.product_id)
SELECT customer_id,
	   COUNT(*) AS number_of_orders,
       SUM(price) AS amount_spent
FROM previous_sales
GROUP BY customer_id
ORDER BY customer_id;


-- QUESTION 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
SELECT s.customer_id,
	   SUM(CASE WHEN m.product_name = 'sushi' THEN 10 * 2 * m.price
		   ELSE 10 * m.price END) AS total_points
FROM sales AS s
	 INNER JOIN menu AS m
     ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY customer_id;



-- QUESTION 10: In the first week after a customer joins the program (including 
-- their join date) they earn 2x points on all items, not just sushi - how many points 
-- do customer A and B have at the end of January?

WITH pointers AS (
	SELECT s.customer_id,
		   s.order_date,
		   m.join_date,
		   DATE_ADD(m.join_date, INTERVAL 7 DAY) AS week_after_join_date,
		   me.product_name,
		   me.price
	FROM sales AS s
		 INNER JOIN menu AS me
		 ON me.product_id = s.product_id
		 INNER JOIN members AS m
		 ON m.customer_id = s.customer_id
)
SELECT customer_id,
	   SUM(CASE WHEN order_date BETWEEN join_date AND week_after_join_date THEN 2 * 10 * price
		    WHEN order_date NOT BETWEEN join_date AND week_after_join_date AND product_name = 'sushi' THEN 2 * 10 * price
            WHEN order_date NOT BETWEEN join_date AND week_after_join_date AND product_name != 'sushi' THEN 10 * price
            END) AS total_points
FROM pointers
WHERE MONTH(order_date) = 1
GROUP BY customer_id
ORDER BY customer_id;



-- to look at the calculations clearly
SELECT customer_id,
	   order_date,
	   join_date,
       week_after_join_date,
       product_name,
       price,
	   CASE WHEN order_date BETWEEN join_date AND week_after_join_date THEN 2 * 10 * price
		    WHEN order_date NOT BETWEEN join_date AND week_after_join_date AND product_name = 'sushi' THEN 2 * 10 * price
            WHEN order_date NOT BETWEEN join_date AND week_after_join_date AND product_name != 'sushi' THEN 10 * price
            END AS points
FROM pointers
WHERE MONTH(order_date) = 1
ORDER BY customer_id, order_date;




-- Bonus Questions

-- Recreating the table (JOIN ALL THINGS)
CREATE TEMPORARY TABLE IF NOT EXISTS updated_customers
SELECT s.customer_id,
	   s.order_date,
       me.product_name,
       me.price,
       CASE WHEN s.order_date < m.join_date THEN 'N'
		    WHEN s.order_date >= m.join_date THEN 'Y'
            ELSE 'N' 
            END AS member
FROM sales AS s
	 LEFT JOIN menu AS me
	 ON me.product_id = s.product_id
	 LEFT JOIN members AS m
	 ON m.customer_id = s.customer_id;



-- RANKING ALL THE THINGS
SELECT *,
	   CASE WHEN member = 'Y' THEN 
       RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
       END AS ranking
FROM updated_customers