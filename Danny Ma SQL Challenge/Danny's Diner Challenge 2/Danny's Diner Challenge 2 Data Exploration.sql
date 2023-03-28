-- Danny Ma SQL Challenge 2: Pizza Runner
-- Exploratory Data Analysis

-- This section would be used to solve the case study questions for Pizza Runner

-- SECTION A. Pizza Metrics

-- Question 1: How many pizzas were ordered?
SELECT COUNT(*) AS number_of_ordered_pizzas
FROM customer_orders;

-- Question 2: How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS distinct_orders_count
FROM customer_orders;

-- Question 3: How many successful orders were delivered by each runner?
SELECT runner_id, 
	   COUNT(*) AS number_of_successful_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- Question 4: How many of each type of pizza was delivered?

SELECT c.pizza_id,
	   COUNT(*) AS number_of_pizza
FROM customer_orders AS c
	 JOIN runner_orders AS r
     USING(order_id)
WHERE r.cancellation IS NULL
GROUP BY c.pizza_id;


-- Question 5: How many Vegetarian and Meatlovers were ordered by each customer?
SELECT * FROM PIZZA_NAMES;

SELECT c.customer_id,
	   COUNT(CASE WHEN p.pizza_name = 'Meatlovers' THEN pizza_name END) AS count_of_meatlover_pizza_orders,
       COUNT(CASE WHEN p.pizza_name = 'Vegetarian' THEN pizza_name END) AS count_of_vegetarian_pizza_orders			
FROM customer_orders AS c
	 JOIN pizza_names AS p
     USING(pizza_id)
GROUP BY c.customer_id
ORDER BY c.customer_id;


-- Question 6: What was the maximum number of pizzas delivered in a single order?
SELECT MAX(Number_of_pizzas) AS maximum_number_of_pizzas
FROM(
	SELECT c.order_id,
		   COUNT(c.pizza_id) as Number_of_pizzas
	FROM customer_orders AS c
		 JOIN runner_orders AS r
		 USING(order_id)
	WHERE r.cancellation IS NULL
	GROUP BY c.order_id
	ORDER BY Number_of_pizzas DESC
    ) AS number_of_orders;

-- Question 7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT c.customer_id, 
	   COUNT(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 END) AS delivered_pizza_with_least_one_change,
       COUNT(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 END) AS delivered_pizza_with_no_change
FROM customer_orders AS c
		 JOIN runner_orders AS r
		 USING(order_id)
WHERE r.cancellation IS NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;


-- Question 8: How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(c.pizza_id) AS pizza_count
FROM customer_orders AS c
		 JOIN runner_orders AS r
		 USING(order_id)
WHERE r.cancellation IS NULL AND c.exclusions IS NOT NULL 
	  AND c.extras IS NOT NULL;
      

-- Question 9: What was the total volume of pizzas ordered for each hour of the day?
select * from customer_orders;

SELECT HOUR(order_time) AS hour_of_the_day,
	   COUNT(pizza_id) AS volume_of_pizza
FROM customer_orders
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time) ASC;


-- Question 10: What was the volume of orders for each day of the week?
SELECT DAYOFWEEK(order_time) AS day_of_week,
	   DAYNAME(order_time) AS day_name,
	   COUNT(pizza_id) AS volume_of_pizza
FROM customer_orders
GROUP BY DAYOFWEEK(order_time), DAYNAME(order_time)
ORDER BY DAYOFWEEK(order_time) ASC;


-- SECTION B. Runner and Customer Experience

-- Question 1: How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT * from runners;

SELECT WEEK(registration_date + INTERVAL 2 DAY) AS week_number,
	   MIN(registration_date) AS starting_week_date,
       COUNT(*) AS number_of_runners
FROM runners
GROUP BY WEEK(registration_date + INTERVAL 2 DAY)
ORDER BY WEEK(registration_date + INTERVAL 2 DAY) ASC;

-- Question 2: What was the average time in minutes it took for each runner 
-- to arrive at the Pizza Runner HQ to pickup the order?

WITH minute_diff AS (
	SELECT pickup_time,
		   order_time,
		   TIMESTAMPDIFF(MINUTE, order_time, pickup_time) AS timediff_minutes,
           runner_id
	FROM customer_orders AS c
		 JOIN runner_orders AS r
		 USING(order_id)
	)
SELECT runner_id,
	   AVG(timediff_minutes) AS average_time_minutes
FROM minute_diff
GROUP BY runner_id;
     

-- Question 3: Is there any relationship between the number of pizzas 
-- and how long the order takes to prepare?
select * from runner_orders;
select * from customer_orders;

WITH sub_table AS (
	SELECT c.order_id,
		   c.order_time,
		   r.pickup_time,
		   COUNT(c.pizza_id) AS pizza_count
	FROM customer_orders AS c
			 JOIN runner_orders AS r
			 USING(order_id)
	GROUP BY c.order_id,
		   c.order_time,
		   r.pickup_time
	)
    
SELECT pizza_count,
	   AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS avg_time_of_delivery
FROM sub_table
GROUP BY pizza_count;



-- Question 4: What was the average distance travelled for each customer?
SELECT c.customer_id,
	   AVG(distance) AS avg_distance
FROM customer_orders AS c
	 JOIN runner_orders AS r
	 USING(order_id)
GROUP BY c.customer_id
ORDER BY c.customer_id;


-- Question 5: What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) AS maximum_delivery_time,
	   MIN(duration) AS minimum_delivery_time,
       MAX(duration) - MIN(duration) AS distance_range
FROM runner_orders;


-- Question 6: What was the average speed for each runner for each delivery 
-- and do you notice any trend for these values?

SELECT r.runner_id,
	   ROUND(AVG((100/6) * distance/duration), 2) AS avg_speed_in_metre_per_seconds
FROM runner_orders AS ro
	 JOIN runners AS r
     USING(runner_id)
GROUP BY r.runner_id;


-- Question 7: What is the successful delivery percentage for each runner?
select * from runner_orders;

WITH success as (
	SELECT runner_id,
		   COUNT(*) AS all_order
	FROM runner_orders
    GROUP BY runner_id),
    unsuccessful AS (
    SELECT runner_id,
		   COUNT(*) AS successful_order
	FROM runner_orders
    WHERE cancellation IS NULL
    GROUP BY runner_id)
    
SELECT runner_id,
	   CONCAT(ROUND(successful_order/all_order * 100, 2), '%') AS success_delivery_percentage
FROM success AS s 
	 JOIN unsuccessful AS u
     USING(runner_id)
ORDER BY runner_id;


-- SECTION C. Ingredient Optimisation

-- Question 1: What are the standard ingredients for each pizza?

-- The standard ingredients for each pizza are
select * from pizza_recipes_clean;
select * from pizza_toppings;

WITH ima AS(
SELECT pr.pizza_id,
	   pn.pizza_name,
	   topping_name AS standard_ingredients
FROM pizza_recipes_clean AS pr
	JOIN pizza_toppings AS pt
    ON pr.toppings = pt.topping_id
    JOIN pizza_names AS pn
    ON pn.pizza_id = pr.pizza_id
ORDER BY pizza_id
)
SELECT pizza_id,
	   pizza_name,
       GROUP_CONCAT(standard_ingredients)
FROM ima
GROUP BY pizza_id,
	   pizza_name;
       


-- Question 2: What was the most commonly added extra?
select * from customer_orders_cleaned;
select * from customer_orders;

SELECT extras,
	   topping_name,
	   COUNT(DISTINCT row_num) AS extras_count
FROM customer_orders_cleaned AS coc
	 JOIN pizza_toppings AS pt
     ON coc.extras = pt.topping_id
GROUP BY extras,
	   topping_name;
       

-- Question 3: What was the most common exclusion?
SELECT exclusions,
	   topping_name,
	   COUNT(DISTINCT row_num) AS exclusion_count
FROM customer_orders_cleaned AS coc
	 JOIN pizza_toppings AS pt
     ON coc.exclusions = pt.topping_id
GROUP BY exclusions,
	   topping_name;


-- Question 4: Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT * FROM customer_orders;
SELECT * FROM pizza_names;
SELECT * FROM pizza_toppings;

-- First I create a table using a CTE to get the name of the Pizza
WITH pizza AS(
SELECT order_id,
	   customer_id,
       pizza_id,
       exclusions,
       extras,
       order_time,
       pn.pizza_name
FROM customer_orders AS c
JOIN pizza_names AS pn
USING(pizza_id)
), -- Next is to use the table created earlier to add the name of the exclusions using a case statement
excludes AS(
SELECT order_id,
	   customer_id,
       pizza_id,
       exclusions,
       extras,
       order_time,
       pizza_name,
       CASE WHEN exclusions IS NULL THEN NULL 
		    WHEN CHAR_LENGTH(exclusions) = 1 THEN CONCAT('Exclude ', topping_name)
            ELSE 'Exclude BBQ Sause, Mushrooms' END AS Exclude
FROM pizza 
LEFT JOIN pizza_toppings AS pt
ON pizza.exclusions = pt.topping_id
), -- Next is to use the table created earlier to add the name of the extras using a case statement
extra AS(
SELECT order_id,
	   customer_id,
       pizza_id,
       exclusions,
       extras,
       order_time,
       pizza_name,
       Exclude,
       CASE WHEN extras IS NULL THEN NULL
		    WHEN CHAR_LENGTH(extras) = 1 THEN CONCAT('Extra ', topping_name)
            WHEN CHAR_LENGTH(extras) > 1 AND extras = '1, 5' THEN 'Extra Bacon, Chicken'
            ELSE 'Extra Bacon, Cheese' END AS extra
FROM excludes
LEFT JOIN pizza_toppings AS pt
ON excludes.extras = pt.topping_id
)
-- to create a column that would join the order_item in the format specified in the question
SELECT order_id,
	   customer_id,
       pizza_id,
       exclusions,
       extras,
       order_time,
       pizza_name,
       Exclude,
       extra,
       CASE WHEN exclude IS NULL AND extra IS NULL THEN pizza_name
			WHEN extra IS NULL THEN CONCAT(pizza_name, ' - ', exclude) 
            WHEN exclude IS NULL THEN CONCAT(pizza_name, ' - ', extra)
            WHEN extra IS NOT NULL AND exclude IS NOT NULL THEN CONCAT(pizza_name, ' - ', exclude, ' - ', extra)
            END AS order_item
FROM extra
ORDER BY order_id;







-- Question 6: What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
select * from pizza_recipes_clean;
select * from pizza_toppings;

-- to find the number of ingredients used in all delivered pizzas, we need to first filter for cancellation to be null to confirm that its 
-- delivered. To calculate for the quantity of each ingredients, we need to know that each pizza have their ingredients and ingredients 
-- are in the pizza_toppings table. Pizza 1 contains 1, 2, 3, 4, 5, 6, 8, 10 and they are the toppings used in making just one pizza 1. 
-- if 10 pizza 1 were delivered then 10 of each pizza 1 ingredients were used (disregarding extras and exclusions) and the same thing goes
-- for pizza 2.

-- For this Question, Temporary Tables would be created to solve this question. 

-- this table is created to show the number of each ingredients used for each delivered pizza
DROP TEMPORARY TABLE IF EXISTS pizza_orders;
CREATE TEMPORARY TABLE pizza_orders AS
SELECT tp.topping_id,
           tp.topping_name,
           pr.pizza_id,
           COUNT(c.pizza_id) AS pizza_order
    FROM pizza_toppings AS tp
    JOIN pizza_recipes_clean AS pr ON pr.toppings = tp.topping_id
    JOIN customer_orders AS c ON pr.pizza_id = c.pizza_id
    JOIN runner_orders AS r ON r.order_id = c.order_id
    WHERE r.cancellation IS NULL
    GROUP BY tp.topping_id, tp.topping_name, pr.pizza_id;


 -- a temporary table to count the number of exclusions from the orders for each pizza type      
DROP TEMPORARY TABLE IF EXISTS excludes;
CREATE TEMPORARY TABLE excludes AS
	SELECT pizza_id,
	       exclusions,
           COUNT(DISTINCT row_num) AS exclusion_count
    FROM customer_orders_cleaned AS cc
    JOIN runner_orders AS r USING(order_id)
    WHERE r.cancellation IS NULL
    GROUP BY pizza_id,
	         exclusions;
             
			
 -- a temporary table to count the number of extras from the orders for each pizza type 
DROP TEMPORARY TABLE IF EXISTS extra;
CREATE TEMPORARY TABLE extra AS
	SELECT pizza_id,
		   extras,
           COUNT(DISTINCT row_num) AS extras_count
    FROM customer_orders_cleaned AS ccc
    JOIN runner_orders AS r USING(order_id)
    WHERE r.cancellation IS NULL AND ccc.extras IS NOT NULL
    GROUP BY pizza_id,
			 extras;
             
--  to bring all the tables together to get the quantity of each ingredients used
WITH exclusion_count AS(
SELECT po.topping_id,
       topping_name,
       po.pizza_id,
       pizza_order,
       exclusion_count
FROM pizza_orders AS po
LEFT JOIN excludes 
ON po.pizza_id = excludes.pizza_id AND po.topping_id = excludes.exclusions
), 
extras_count AS (
SELECT topping_id,
       topping_name,
       exclusion_count.pizza_id,
       pizza_order,
       exclusion_count,
       CASE WHEN topping_id = 1 THEN extras_count + 1 -- this is because topping 1 was used as an extra for pizza 2 but topping 1 isnt an ingredients
		    ELSE extras_count END AS extras_count
FROM exclusion_count
left JOIN extra
ON exclusion_count.pizza_id = extra.pizza_id AND exclusion_count.topping_id = extra.extras
)
SELECT topping_id,
	   topping_name,
       SUM(pizza_order + IFNULL(extras_count, 0) - IFNULL(exclusion_count, 0)) AS Quantity_used
FROM extras_count
GROUP BY topping_id,
	   topping_name
ORDER BY Quantity_used DESC;



-- D. Pricing and Ratings

-- Question 1: If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes
-- - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT pizza_name,
	   pizza_count * pizza_price AS total_Amount_per_pizza,
       SUM(pizza_count * pizza_price) OVER() AS total_amount
FROM(
	SELECT pizza_name,
		   COUNT(*) AS pizza_count,
		   CASE WHEN pizza_name = 'Meatlovers' THEN 12 ELSE 10 END AS pizza_price
	FROM pizza_names AS p
	JOIN customer_orders AS c
	USING(pizza_id)
	GROUP BY pizza_name
) pizza;



-- Question 2: What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

WITH pizza AS(
		SELECT pizza_name,
			   COUNT(*) AS pizza_count,
			   CASE WHEN pizza_name = 'Meatlovers' THEN 12 
					ELSE 10 END AS pizza_price,
			   SUM(CASE WHEN extras IS NULL THEN 0 
					WHEN CHAR_LENGTH(extras) = 1 THEN 1 
                    WHEN extras LIKE '%4%' 
						THEN CHAR_LENGTH(REPLACE(REPLACE(extras, ',', ''), ' ', '')) + 1
					ELSE 2 END) AS extras_count 
		FROM pizza_names AS p
		JOIN customer_orders AS c
		USING(pizza_id)
		GROUP BY pizza_name
		)
SELECT pizza_name,
	   (pizza_count * pizza_price) + extras_count AS total_Amount_per_pizza,
       SUM((pizza_count * pizza_price) + extras_count) OVER() AS total_amount
FROM pizza;



-- Question 3: The Pizza Runner team now wants to add an additional ratings 
-- system that allows customers to rate their runner, how would you design an additional 
-- table for this new dataset - generate a schema for this new table and insert your own data 
-- or ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS runner_ratings;

CREATE TABLE runner_ratings AS
SELECT order_id,
	   runner_id,
       CASE WHEN cancellation IS NOT NULL THEN NULL 
			ELSE FLOOR(1 + RAND() * (5 - 1)) END AS ratings
FROM runner_orders;

SELECT * FROM runner_ratings;


-- Question 4: Using your newly generated table - can you join all of the information 
-- together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

SELECT customer_id,
	   ro.order_id,
       ro.runner_id,
       r.ratings,
       c.order_time,
       ro.pickup_time,
       TIMESTAMPDIFF(MINUTE, c.order_time, ro.pickup_time) AS time_diff_minutes,
       duration,
       AVG(distance/duration) AS avg_speed_km_hr,
       COUNT(pizza_id) AS pizza_count
FROM runner_orders AS ro
JOIN runner_ratings AS r
ON r.runner_id = ro.runner_id AND r.order_id = ro.order_id
JOIN customer_orders AS c
ON c.order_id = ro.order_id
GROUP BY customer_id,
	   ro.order_id,
       ro.runner_id,
       r.ratings,
       c.order_time,
       ro.pickup_time,
       TIMESTAMPDIFF(MINUTE, c.order_time, ro.pickup_time),
       duration;
       
       

-- Question 5: If a Meat Lovers pizza was $12 and Vegetarian
--  $10 fixed prices with no cost for extras and each runner is paid $0.30 per 
-- kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH distance AS(
		SELECT pizza_name,
			   COUNT(*) AS pizza_count,
			   CASE WHEN pizza_name = 'Meatlovers' THEN 12 
					ELSE 10 END AS pizza_price,
			   SUM(duration * 0.30) AS distance_cost
		FROM pizza_names AS p
		JOIN customer_orders AS c
		ON p.pizza_id = c.pizza_id
		JOIN runner_orders AS r
		ON r.order_id = c.order_id
		GROUP BY pizza_name
)
SELECT pizza_name,
	   pizza_count,
       pizza_price,
       (pizza_count * pizza_price) - distance_cost AS Amount_left,
       SUM((pizza_count * pizza_price) - distance_cost) OVER() AS total_amount_left
FROM distance
