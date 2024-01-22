/* 
Below are SQL queries used in the current project to extract data. 
Data collected will address several questions and information gathered will be presented using three Tableau dashboards: Orders, Inventory and Staff.
*/

/*
Dashboard 1: Orders
- What is the total number of orders?
- What is the total sales?
- What is the total number of items?
- What is the average order value?
- What proportion of total sales does each category represent?
- What are the top selling items?
- What are the total orders by hour?
- What are the total sales by hour?
- What proportion of orders are via delivery versus pick up?
*/

SELECT
	o.order_id,
	i.item_price,
	o.quantity,
	i.item_cat,
	i.item_name,
	o.created_at,
	a.delivery_address1,
	a.delivery_address2,
	a.delivery_city,
	a.delivery_zipcode,
	o.delivery 
FROM
	orders o
	LEFT JOIN item i ON o.item_id = i.item_id
	LEFT JOIN address a ON o.add_id = a.add_id;

/*
Dashboard 2: Inventory
- What is the total quantity for each ingredient? 
- What is the total cost for each ingredient? 
- What is the remaining inventory percentage for each ingredient?
- What is the list of ingredients to reorder based on the remaining inventory?

- What is the total ingredient cost?
- What is the cost to make each pizza?
*/

SELECT 
	s1.item_name,
	s1.ing_id,
	s1.ing_name,
	s1.ing_weight,
	s1.ing_price,
	s1.order_quantity,
	s1.recipe_quantity, 
	s1.order_quantity * s1.recipe_quantity AS ordered_weight, -- calculate total quantity for each ingredient
	s1.ing_price/s1.ing_weight AS unit_cost,
	(s1.order_quantity * s1.recipe_quantity) * (s1.ing_price/s1.ing_weight) AS ingredient_cost -- calculate total cost for each ingredient
FROM (SELECT
	o.item_id,
	i.sku,
	i.item_name,
	r.ing_id,
	ing.ing_name,
	r.quantity AS recipe_quantity, -- ingredient quantity in recipe
	SUM(o.quantity) AS order_quantity, -- number of orders
	ing.ing_weight,
	ing.ing_price
	FROM
		orders o 
		LEFT JOIN item i ON o.item_id = i.item_id
		LEFT JOIN recipe r ON i.sku = r.recipe_id
		LEFT JOIN ingredient ing ON ing.ing_id = r.ing_id
	GROUP BY
		o.item_id,
		i.sku,
		i.item_name,
		r.ing_id,
		r.quantity,
		ing.ing_name,
		ing.ing_weight,
		ing.ing_price) s1;

-- Create a new view "stock1"

SELECT 
	s2.ing_name,
	s2.ordered_weight,
	ing.ing_weight * inv.quantity AS total_inv_weight, -- inventory amount 
	(ing.ing_weight * inv.quantity) - s2.ordered_weight AS remaining_weight -- remaining amount for each ingredient
FROM 
	(SELECT 
		ing_id,
		ing_name,
		SUM(ordered_weight) AS ordered_weight -- total weight ordered
	FROM
		stock1
	GROUP BY	
		ing_name,
		ing_id) s2
	LEFT JOIN inventory inv ON inv.item_id = s2.ing_id
	LEFT JOIN ingredient ing ON ing.ing_id = s2.ing_id;

/*
Dashboard 3: Staff
- What is the total staff cost?
- What is the total number of hours worked?
- How many hours does each staff member work during each shift?
- What is the hourly rate for each staff member?
- What is the cost for each staff member?
*/

SELECT
	r.date,
	s.first_name,
	s.last_name,
	s.hourly_rate,
	sh.start_time,
	sh.end_time,
	((HOUR(TIMEDIFF(sh.end_time,sh.start_time)))*60 + (MINUTE(TIMEDIFF(sh.end_time, sh.start_time))))/60 AS hours_in_shift, -- convert hr to min, add mins then divide by 60 to get hr
	(((HOUR(TIMEDIFF(sh.end_time,sh.start_time)))*60 + (MINUTE(TIMEDIFF(sh.end_time, sh.start_time))))/60) * s.hourly_rate AS staff_cost
FROM rota r
	LEFT JOIN staff s ON r.staff_id = s.staff_id
	LEFT JOIN shift sh ON r.shift_id = sh.shift_id;
