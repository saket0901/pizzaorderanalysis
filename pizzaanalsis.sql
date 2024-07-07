-- retrive the total number of oreders placed
select * from orders;
select count(order_id) from orders; 

-- total revenue
SELECT 
    round(sum(orders_details.quantity * pizzas.price),2) AS total_sales
FROM
    orders_details
        JOIN
    pizzas ON pizzas.pizza_id = orders_details.pizza_id;
    
    

USE pizzahut;
SHOW TABLES;

--  Identify the highest-priced pizza.

select max(price) from pizzas;

select * from pizzas where  price=(select max(price) from pizzas);

SELECT 
    pizza_types.name, pizzas.price
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;


-- Identify the most common pizza size ordered.
select size,count(size) from pizzas group by size;  

SELECT 
    pizzas.size,
    COUNT(orders_details.order_details_id) AS order_count
FROM
    pizzas
        JOIN
    orders_details ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizzas.size
ORDER BY order_count DESC;

-- List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pizza_types.name, SUM(orders_details.quantity) AS quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY quantity DESC
LIMIT 5;


-- Intermediate:
-- Join the necessary tables to find the total quantity of each pizza category ordered.


select category,sum(quantity)
from pizza_types join pizzas
on pizzas.pizza_type_id=pizza_types.pizza_type_id
join orders_details ON orders_details.pizza_id = pizzas.pizza_id
group by pizza_types.category;

-- Determine the distribution of orders by hour of the day.

select hour(order_time),count(order_id) from orders
group by hour(order_time)
order by hour(order_time) desc;

-- Join relevant tables to find the category-wise distribution of pizzas.
select category,count(*) from pizza_types  -- name
group by category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.


SELECT 
    AVG(quantity)
FROM
    (SELECT 
        orders.order_date, SUM(orders_details.quantity) AS quantity
    FROM
        orders
    JOIN orders_details ON orders.order_id = orders_details.order_id
    GROUP BY orders.order_date) AS order_quantity;
    
    
    -- Determine the top 3 most ordered pizza types based on revenue.
select pizza_types.name,sum(orders_details.quantity*pizzas.price) as revenue from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id join orders_details on
orders_details.pizza_id=pizzas.pizza_id
group by pizza_types.name
order by revenue desc limit 3;


-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.

select pizza_types.category,(sum(orders_details.quantity*pizzas.price) / (SELECT 
    round(sum(orders_details.quantity * pizzas.price),2) AS total_sales
FROM
    orders_details
        JOIN
    pizzas ON pizzas.pizza_id = orders_details.pizza_id)) *100 as revenue from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id join orders_details on
orders_details.pizza_id=pizzas.pizza_id
group by pizza_types.category
order by revenue desc;


-- Analyze the cumulative revenue generated over time.
-- 200 200
-- 300 500
-- 450 950
-- 250 1200


select order_date,sum(revenue) over(order by order_date) as cum_revenue
from
(select	orders.order_date,
sum(orders_details.quantity*pizzas.price) as revenue
from orders_details join pizzas
on orders_details.pizza_id=pizzas.pizza_id
join  orders
on orders.order_id=orders_details.order_id
group by orders.order_date) as sales;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.



select name,revenue from(
(select category,name,revenue,rank() over(partition by category order by revenue desc) as rn
from
(
select pizza_types.category,sum(orders_details.quantity*pizzas.price) as revenue from pizza_types join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id join orders_details on
orders_details.pizza_id=pizzas.pizza_id
group by pizza_types.categorypizza_types.name)as a
)as b)
where rn<=3;


SELECT name, revenue 
FROM (
    SELECT category, name, revenue, 
           RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM (
        SELECT pizza_types.category, pizza_types.name, 
               SUM(orders_details.quantity * pizzas.price) AS revenue 
        FROM pizza_types 
        JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id 
        JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id 
        GROUP BY pizza_types.category, pizza_types.name
    ) AS a
) AS b
WHERE rn <= 3;





SELECT
    category,
    MAX(CASE WHEN rn = 1 THEN name END) AS top_1_pizza,
    MAX(CASE WHEN rn = 1 THEN revenue END) AS top_1_revenue,
    MAX(CASE WHEN rn = 2 THEN name END) AS top_2_pizza,
    MAX(CASE WHEN rn = 2 THEN revenue END) AS top_2_revenue,
    MAX(CASE WHEN rn = 3 THEN name END) AS top_3_pizza,
    MAX(CASE WHEN rn = 3 THEN revenue END) AS top_3_revenue
FROM (
    SELECT category, name, revenue,
           RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM (
        SELECT pizza_types.category, pizza_types.name,
               SUM(orders_details.quantity * pizzas.price) AS revenue
        FROM pizza_types
        JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
        GROUP BY pizza_types.category, pizza_types.name
    ) AS subquery
) AS ranked_pizzas
WHERE rn <= 3
GROUP BY category;






SELECT 
    'Top 1' AS rank_label,
    MAX(CASE WHEN category = 'Chicken' THEN top_1_pizza END) AS chicken_top_1,
    MAX(CASE WHEN category = 'Chicken' THEN top_1_revenue END) AS chicken_top_1_revenue,
    MAX(CASE WHEN category = 'Classic' THEN top_1_pizza END) AS classic_top_1,
    MAX(CASE WHEN category = 'Classic' THEN top_1_revenue END) AS classic_top_1_revenue,
    MAX(CASE WHEN category = 'Supreme' THEN top_1_pizza END) AS supreme_top_1,
    MAX(CASE WHEN category = 'Supreme' THEN top_1_revenue END) AS supreme_top_1_revenue,
    MAX(CASE WHEN category = 'Veggie' THEN top_1_pizza END) AS veggie_top_1,
    MAX(CASE WHEN category = 'Veggie' THEN top_1_revenue END) AS veggie_top_1_revenue
FROM (
    SELECT
        category,
        MAX(CASE WHEN rn = 1 THEN name END) AS top_1_pizza,
        MAX(CASE WHEN rn = 1 THEN revenue END) AS top_1_revenue,
        MAX(CASE WHEN rn = 2 THEN name END) AS top_2_pizza,
        MAX(CASE WHEN rn = 2 THEN revenue END) AS top_2_revenue,
        MAX(CASE WHEN rn = 3 THEN name END) AS top_3_pizza,
        MAX(CASE WHEN rn = 3 THEN revenue END) AS top_3_revenue
    FROM (
        SELECT category, name, revenue,
               RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
        FROM (
            SELECT pizza_types.category, pizza_types.name,
                   SUM(orders_details.quantity * pizzas.price) AS revenue
            FROM pizza_types
            JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
            JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
            GROUP BY pizza_types.category, pizza_types.name
        ) AS subquery
    ) AS ranked_pizzas
    WHERE rn <= 3
    GROUP BY category
) AS top_pizzas

UNION ALL

SELECT 
    'Top 2' AS rank_label,
    MAX(CASE WHEN category = 'Chicken' THEN top_2_pizza END) AS chicken_top_2,
    MAX(CASE WHEN category = 'Chicken' THEN top_2_revenue END) AS chicken_top_2_revenue,
    MAX(CASE WHEN category = 'Classic' THEN top_2_pizza END) AS classic_top_2,
    MAX(CASE WHEN category = 'Classic' THEN top_2_revenue END) AS classic_top_2_revenue,
    MAX(CASE WHEN category = 'Supreme' THEN top_2_pizza END) AS supreme_top_2,
    MAX(CASE WHEN category = 'Supreme' THEN top_2_revenue END) AS supreme_top_2_revenue,
    MAX(CASE WHEN category = 'Veggie' THEN top_2_pizza END) AS veggie_top_2,
    MAX(CASE WHEN category = 'Veggie' THEN top_2_revenue END) AS veggie_top_2_revenue
FROM (
    SELECT
        category,
        MAX(CASE WHEN rn = 1 THEN name END) AS top_1_pizza,
        MAX(CASE WHEN rn = 1 THEN revenue END) AS top_1_revenue,
        MAX(CASE WHEN rn = 2 THEN name END) AS top_2_pizza,
        MAX(CASE WHEN rn = 2 THEN revenue END) AS top_2_revenue,
        MAX(CASE WHEN rn = 3 THEN name END) AS top_3_pizza,
        MAX(CASE WHEN rn = 3 THEN revenue END) AS top_3_revenue
    FROM (
        SELECT category, name, revenue,
               RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
        FROM (
            SELECT pizza_types.category, pizza_types.name,
                   SUM(orders_details.quantity * pizzas.price) AS revenue
            FROM pizza_types
            JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
            JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
            GROUP BY pizza_types.category, pizza_types.name
        ) AS subquery
    ) AS ranked_pizzas
    WHERE rn <= 3
    GROUP BY category
) AS top_pizzas

UNION ALL

SELECT 
    'Top 3' AS rank_label,
    MAX(CASE WHEN category = 'Chicken' THEN top_3_pizza END) AS chicken_top_3,
    MAX(CASE WHEN category = 'Chicken' THEN top_3_revenue END) AS chicken_top_3_revenue,
    MAX(CASE WHEN category = 'Classic' THEN top_3_pizza END) AS classic_top_3,
    MAX(CASE WHEN category = 'Classic' THEN top_3_revenue END) AS classic_top_3_revenue,
    MAX(CASE WHEN category = 'Supreme' THEN top_3_pizza END) AS supreme_top_3,
    MAX(CASE WHEN category = 'Supreme' THEN top_3_revenue END) AS supreme_top_3_revenue,
    MAX(CASE WHEN category = 'Veggie' THEN top_3_pizza END) AS veggie_top_3,
    MAX(CASE WHEN category = 'Veggie' THEN top_3_revenue END) AS veggie_top_3_revenue
FROM (
    SELECT
        category,
        MAX(CASE WHEN rn = 1 THEN name END) AS top_1_pizza,
        MAX(CASE WHEN rn = 1 THEN revenue END) AS top_1_revenue,
        MAX(CASE WHEN rn = 2 THEN name END) AS top_2_pizza,
        MAX(CASE WHEN rn = 2 THEN revenue END) AS top_2_revenue,
        MAX(CASE WHEN rn = 3 THEN name END) AS top_3_pizza,
        MAX(CASE WHEN rn = 3 THEN revenue END) AS top_3_revenue
    FROM (
        SELECT category, name, revenue,
               RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rn
        FROM (
            SELECT pizza_types.category, pizza_types.name,
                   SUM(orders_details.quantity * pizzas.price) AS revenue
            FROM pizza_types
            JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
            JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
            GROUP BY pizza_types.category, pizza_types.name
        ) AS subquery
    ) AS ranked_pizzas
    WHERE rn <= 3
    GROUP BY category
) AS top_pizzas;








