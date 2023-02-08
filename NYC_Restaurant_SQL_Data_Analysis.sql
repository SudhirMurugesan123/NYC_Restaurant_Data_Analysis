-------------------------------------------------------------------------------------------------
--select 1000 rows of the data 
SELECT TOP (1000) * FROM Port_Projects..nyc_food_orders;
-------------------------------------------------------------------------------------------------
--most ordered cuisine 

SELECT 
	cuisine_type,
	count(*)
FROM
	Port_Projects..nyc_food_orders
GROUP BY 
	cuisine_type
ORDER BY 
	count(*) desc;
-------------------------------------------------------------------------------------------------
--day of the week with the most orders

SELECT 
	day_of_the_week,
	count(*)
FROM
	Port_Projects..nyc_food_orders
GROUP BY 
	day_of_the_week
ORDER BY 
	count(*) desc;
-------------------------------------------------------------------------------------------------
--average delivery time for a meal by day type 

SELECT 
	day_of_the_week,
	Round(AVG(delivery_time),2) 
FROM 
	Port_Projects..nyc_food_orders
GROUP BY 
	day_of_the_week;
-------------------------------------------------------------------------------------------------
-- average food prep time for a meal by day type

SELECT 
	day_of_the_week,
	Round(AVG(food_preparation_time),2) 
FROM 
	Port_Projects..nyc_food_orders
GROUP BY 
	day_of_the_week;
-------------------------------------------------------------------------------------------------
-- top ten restaurant with the fastest average meal preparation time
SELECT 
	TOP (10) restaurant_name,
	Round(AVG(food_preparation_time),2) as avg_food_prep_time
FROM 
	Port_Projects..nyc_food_orders
GROUP BY 
	restaurant_name
ORDER BY 
	 avg_food_prep_time ASC;
-------------------------------------------------------------------------------------------------
--top 5 restaurants that has fastest service time(delivery and prep) using a CTE

WITH avg_delivery_time AS (
	SELECT 
		TOP (4000) restaurant_name,
		Round(AVG(delivery_time),2) as avg_delivery_time
	FROM 
		Port_Projects..nyc_food_orders
	GROUP BY 
		restaurant_name
	ORDER BY 
		 avg_delivery_time ASC
), avg_prep_time AS(
		SELECT 
			TOP (4000) restaurant_name,
			Round(AVG(food_preparation_time),2) as avg_prep_time
		FROM 
			Port_Projects..nyc_food_orders
		GROUP BY 
			restaurant_name
		ORDER BY 
			 avg_prep_time ASC
)
SELECT 
	top (5)avg_delivery_time.restaurant_name,
	avg_delivery_time.avg_delivery_time,
	avg_prep_time.avg_prep_time,
	avg_prep_time.avg_prep_time+avg_delivery_time.avg_delivery_time AS service_time
FROM 
	avg_delivery_time
		JOIN 
	avg_prep_time
		ON avg_delivery_time.restaurant_name = avg_prep_time.restaurant_name
ORDER BY 
	service_time;

-------------------------------------------------------------------------------------------------
--top 5 restaurants that has fastest service time(delivery and prep) shortest query

SELECT 
		TOP (5) restaurant_name,
		Round(AVG(delivery_time),2) as avg_delivery_time,
		Round(AVG(food_preparation_time),2) as avg_prep_time,
		Round(AVG(delivery_time),2) + Round(AVG(food_preparation_time),2) as avg_service_time
	FROM 
		Port_Projects..nyc_food_orders
	GROUP BY 
		restaurant_name
	ORDER BY 
		 avg_service_time ASC

-------------------------------------------------------------------------------------------------
--cuisines most most often ordered together 
/*
SELECT DISTINCT
	a.cuisine_type as cuisine_type_a,
	b.cuisine_type as cuisine_type_b,
	COUNT(*)
FROM 
	Port_Projects..nyc_food_orders a,
	Port_Projects..nyc_food_orders b
WHERE
	a.customer_id = b.customer_id AND
	a.cuisine_type <> b.cuisine_type
GROUP BY 
	a.cuisine_type,
	b.cuisine_type
ORDER BY 
	COUNT(*) DESC;
 */
-------------------------------------------------------------------------------------------------
 --cuisines most most often ordered together
SELECT 
	cuisine_type_a, 
	cuisine_type_b,
	order_number
FROM 
   (SELECT 
        LEAST(a.cuisine_type, b.cuisine_type) AS cuisine_type_a,
        GREATEST(a.cuisine_type, b.cuisine_type) AS cuisine_type_b,
        COUNT(*) AS order_number,
        ROW_NUMBER() OVER (PARTITION BY LEAST(a.cuisine_type, b.cuisine_type), GREATEST(a.cuisine_type, b.cuisine_type) ORDER BY COUNT(*)) AS rn
    FROM 
        Port_Projects..nyc_food_orders a,
        Port_Projects..nyc_food_orders b
    WHERE
        a.customer_id = b.customer_id AND
        a.cuisine_type <> b.cuisine_type  
    GROUP BY 
        a.cuisine_type,
        b.cuisine_type) cuisine_combos
WHERE 
	rn =1
ORDER BY 
	order_number DESC;


-------------------------------------------------------------------------------------------------
-- top 5 restaurants by orders in each cuisine using CTE and window function 
WITH ranked_restaurants AS (
  SELECT 
    restaurant_name, 
    cuisine_type, 
    COUNT(*) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY cuisine_type ORDER BY COUNT(*) DESC) AS restaurant_rank
  FROM 
	Port_Projects..nyc_food_orders
  GROUP BY 
	restaurant_name, cuisine_type
 
)
SELECT 
	restaurant_name, cuisine_type, total_orders,restaurant_rank
FROM 
	ranked_restaurants
WHERE 
	restaurant_rank <= 5;

-------------------------------------------------------------------------------------------------
-- top 5 restaurants by orders in each cuisine using subquery 

SELECT 
	a.* 
FROM 
	(SELECT 
		restaurant_name, 
		cuisine_type, 
		COUNT(*) AS total_orders,
		ROW_NUMBER() OVER (PARTITION BY cuisine_type ORDER BY COUNT(*) DESC) AS restaurant_rank
  FROM 
		Port_Projects..nyc_food_orders
  GROUP BY 
		restaurant_name, cuisine_type) a
WHERE 
	a.restaurant_rank <=5;
------------------------------------------------------------------------------------------------
--Most popular restaurants by number of orders with average rating on the side 
SELECT 
	restaurant_name,
	count(*) as total_orders,
	round(avg(rating),2)as avg_rating
FROM 
	Port_Projects..nyc_food_orders
WHERE 
	rating IS NOT NULL
GROUP BY 
	restaurant_name
ORDER BY 
	--avg(rating) DESC,
	count(*) DESC;
