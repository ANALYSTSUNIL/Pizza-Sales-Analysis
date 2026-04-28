CREATE DATABASE pizzahut;

CREATE TABLE orders (
order_id INT NOT NULL,
order_date DATE NOT NULL,
order_time TIME NOT NULL,
PRIMARY KEY (order_id));

CREATE TABLE order_details (
order_details_id INT NOT NULL,
order_id INT NOT NULL,
pizza_id TEXT NOT NULL,
quantity INT NOT NULL,
PRIMARY KEY (order_details_id));

-- Retrieve the total number of orders placed.

SELECT COUNT(order_ID) AS Total_orders FROM orders;

-- Calculate the total revenue generated from pizza sales.

SELECT 
    ROUND(SUM(od.quantity * p.price), 2) AS Total_revenue
FROM
    order_details AS od
        JOIN
    pizzas AS p ON od.pizza_id = p.pizza_id;
    
    
-- Identify the highest-priced pizza.

SELECT 
    pt.name, p.price
FROM
    pizzas AS p
        JOIN
    pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- Identify the most common pizza size ordered.

SELECT 
    p.size, COUNT(od.order_details_id) AS order_count
FROM
    pizzas AS p
        JOIN
    order_details AS od ON p.pizza_id = od.pizza_id
GROUP BY size
ORDER BY order_count DESC;

-- List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pt.name, SUM(od.quantity) AS pizza_orders
FROM
    pizza_types AS pt
        JOIN
    pizzas AS p ON p.pizza_type_id = pt.pizza_type_id
        JOIN
    order_details AS od ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY pizza_orders DESC
LIMIT 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
    pt.category, SUM(od.quantity) AS total_quantity
FROM
    order_details AS od
        JOIN
    pizzas AS p ON p.pizza_id = od.pizza_id
        JOIN
    pizza_types AS pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.category
ORDER BY total_quantity DESC;

-- Determine the distribution of orders by hour of the day.

SELECT 
    HOUR(order_time) AS hours, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY HOUR(order_time);

-- Join relevant tables to find the
-- category-wise distribution of pizzas.

SELECT 
    category, COUNT(name) AS orders
FROM
    pizza_types
GROUP BY category
ORDER BY orders DESC;

-- Group the orders by date and calculate 
-- the average number of pizzas ordered per day.

with order_quantity as 
(select o.order_date , sum(od.quantity) as total_qty 
from orders as o
join order_details as od
on o.order_id = od.order_id
group by o.order_date)
select round(avg(total_qty), 0) as avg_order_per_day
from order_quantity;

-- Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    pt.name, SUM(od.quantity * p.price) AS Revenue
FROM
    pizzas AS p
        JOIN
    pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
        JOIN
    order_details AS od ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;

ROUND(SUM(od.quantity * p.price), 2) AS revenue,
    ROUND((SUM(od.quantity * p.price) / (SELECT 
                    SUM(od.quantity * p.price)
                FROM
                    order_details AS od
                        JOIN
                    pizzas AS p ON od.pizza_id = p.pizza_id) * 100),
            2) AS revenue_percentage
FROM
    pizzas AS p
        JOIN
    pizza_types AS pt ON p.pizza_type_id = pt.pizza_type_id
        JOIN
    order_details AS od ON od.pizza_id = p.pizza_id
GROUP BY pt.category;

-- Analyze the cumulative revenue generated over time.

with sales as
(select o.order_date, round(sum(od.quantity*p.price),2) as revenue
from orders as o
join order_details as od
on o.order_id = od.order_id
join pizzas as p
on p.pizza_id = od.pizza_id
group by o.order_date)
select *,
round(sum(revenue) over(rows between 
unbounded preceding and current row),2) as commulative_revenue
from sales;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with rev as 
(with sales as 
(select pt.category, pt.name, sum(p.price*od.quantity) as revenue
from pizzas as p
join order_details as od 
on p.pizza_id = od.pizza_id
join pizza_types as pt
on pt.pizza_type_id = p.pizza_type_id
group by pt.category, pt.name)
select *,
row_number() over (partition by category order by revenue desc) as rnk
from sales)
select category, name, revenue from rev
where rnk <=3;