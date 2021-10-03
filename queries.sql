-- Part 1: Warm Up

-- Select all rows and all columns from the categories table; order by category ID.
SELECT *  FROM categories ORDER BY category_id;

-- Select name and description of each category; order by ID.
SELECT category_name , description FROM categories ORDER BY category_id;

-- Select all values in the "city" column of the employees table; sort values descending order.
SELECT city FROM employees ORDER BY city DESC;

-- Select a unique set of employees' city names in descending order.
SELECT DISTINCT city FROM employees ORDER BY city DESC;

-- Select ID and name of all discontinued products; order by name.
SELECT   product_id, product_name FROM products WHERE discontinued=1 ORDER BY product_name;


-- Part 2: Orders

-- Select the date of each customer's first order and its corresponding customer ID; sort by customer ID.
SELECT DISTINCT ON(customer_id) order_date , customer_id
FROM orders
ORDER BY customer_id , order_date;

-- Same as previous query, but name the column of date values "first_order_date".
SELECT DISTINCT ON(customer_id) order_date as first_order_date , customer_id
FROM orders
ORDER BY customer_id , first_order_date;

-- Same as previous query, but sort by first_order_date instead of customer ID.
WITH  first_orders AS (SELECT
DISTINCT ON (customer_id)
order_date as first_order_date , customer_id
FROM orders
ORDER BY customer_id, first_order_date)
SELECT *
FROM first_orders
ORDER BY first_order_date;



-- How many orders have been placed?
SELECT COUNT(*) FROM orders;

-- How many orders has each customer made? List customer-ID, order-count pairs; sort by order-count (greatest to least).
SELECT  customer_id, COUNT(*)
FROM orders
GROUP BY customer_id
ORDER BY count DESC;

-- What is the average cost of freight per order?
SELECT SUM(freight)/COUNT(*) AS average_cost FROM orders;

-- For each customer, list customer ID and the average freight cost of their orders; sort by average freight cost.
SELECT customer_id, SUM(freight)/ COUNT(*) AS customer_avg
FROM orders
GROUP BY customer_id
ORDER BY customer_avg;

-- For each customer, list customer ID and the total amount they have spent on freight; sort by cusotmer ID.
SELECT customer_id, SUM(freight) AS customer_freight
FROM orders
GROUP BY customer_id
ORDER BY customer_id;

-- Select the address and the order-count for the address that has received the most orders.
SELECT ship_address, COUNT(*) AS addr_ords
FROM orders
GROUP BY ship_address
ORDER BY addr_ords DESC;

-- Order Subtotal: unit_price * quantity * (1 - discount)
-- Order Total: sum of order's subtotals
-- Given the definitions above, get the Order ID and Order Total for the 50 most expensive orders; sort by Order Total in descending order.
SELECT od.order_id, SUM(od.quantity * od.unit_price* (1-od.discount)) AS order_total
FROM order_details od
GROUP BY od.order_id
ORDER BY order_total DESC
LIMIT 50



-- Part 3: Employees

-- What are first and last name of each Sales Representative? Order by last name.
SELECT first_name, last_name
FROM employees
WHERE title = 'Sales Representative'
ORDER BY last_name

-- Get first name, last name, and notes for employees who don't have anyone to report to (i.e. their reports_to field is blank). Order by last name.
SELECT first_name, last_name, notes
FROM employees
WHERE reports_to IS  NULL
ORDER BY last_name

-- Get first name, last name, and notes for employees who do have someone to report to. Order by last name.
SELECT first_name, last_name, notes
FROM employees
WHERE reports_to IS  NOT NULL
ORDER BY last_name

-- Get first name and last name of the first employee to be hired in London.
SELECT first_name, last_name
FROM employees
WHERE city ='London'
ORDER BY hire_date
LIMIT 1

-- Get first name and home phone of employees whose first names begin with the letter 'A' and whose phone numbers contain the number '4'. Sort by last name.
SELECT first_name, home_phone
FROM employees
WHERE first_name LIKE 'A%' AND home_phone LIKE '%4%'
ORDER BY last_name

-- Get city name and number of Sales Representatives in each city that contains at least 2 Sales Reps. Order by the number of Sales Reps.
SELECT city, COUNT(*) as rep_ct
FROM employees
WHERE title = 'Sales Representative'
GROUP BY city
HAVING COUNT(*) >= 2
ORDER BY rep_ct DESC

-- Get first names, last names, and hire dates of employees who were hired in 1994; sort by hire date.
SELECT first_name,last_name,hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 1994
ORDER BY hire_date


-- Part 4: Mix and Match

-- List product names that begin with the letter 'C' and their corresponding category names. Order by product ID.
SELECT p.product_name, c.category_name
FROM products p
JOIN categories c
ON c.category_id = p.category_id
WHERE p.product_name ILIKE 'C%'
ORDER BY p.product_id

-- Management wants a "call list" to check on customers who haven't ordered in a while.
-- List contact names, contact titles, company names, phone numbers, and last order dates for no more than 10 customers; sort by last order date (least recent first).
WITH dormant AS(
SELECT customer_id, MAX(order_date) AS last_active
FROM orders
GROUP BY customer_id
ORDER BY last_active
LIMIT 10
)
SELECT c.contact_name, c.contact_title, c.company_name, c.phone, d.last_active
FROM customers c
JOIN dormant d
ON d.customer_id = c.customer_id
ORDER BY d.last_active;

-- Management needs to know which products to order due to low stock levels.
-- Each product has an Item Deficit which is defined as the difference between its reorder_level and units_in_stock
-- A product should be ordered if it meets the following criteria:
--   1. The number of units in stock is less than or equal to its reorder-level
--   2. The product is not discontinued
--   3. The number of units on order is less than the product's Item Deficit
-- List product names, supplier company names, supplier phone numbers, and item deficits for each product that should be ordered. Sort by item deficits (greatest to least).
WITH low_stock AS(
SELECT product_name, supplier_id,(reorder_level - units_in_stock ) as defecit
FROM products
WHERE (reorder_level - units_in_stock )  >= 0
	AND discontinued = 0
	AND  units_on_order < (reorder_level - units_in_stock )
)
SELECT ls.product_name, s.company_name, s.phone,ls.defecit
FROM low_stock ls
JOIN suppliers s
ON s.supplier_id = ls.supplier_id
ORDER BY defecit DESC

-- List company names of suppliers who have not shipped any orders; sort alphabetically.
SELECT company_name
FROM suppliers
WHERE supplier_id IN
(WITH up AS
(SELECT od.product_id
FROM orders o
JOIN order_details od
ON o.order_id = od.order_id
WHERE o.shipped_date IS NULL
GROUP BY od.product_id
)
SELECT p.supplier_id
FROM products p
JOIN up
ON p.product_id = up.product_id
GROUP BY p.supplier_id
)

-- List region description, territory description, employee last name, and employees first name for each territory and region an employee works in.
-- Remove duplicate results and sort first by region description, then territory description, then last name, and finally first name.

WITH  ert AS (
SELECT e.last_name, e.first_name, e.region, et.territory_id
FROM employees e
JOIN employee_territories et
ON et.employee_id = e.employee_id
)
SELECT   t.territory_description, ert.last_name, ert.first_name
FROM ert
JOIN territories t
ON t.territory_id = ert.territory_id
GROUP BY t.territory_description, ert.last_name, ert.first_name

-- Get ALL U.S. state names and abbreviations, along with customer company names for customers based in the USA.
-- If a state does not have any relate customers, fill in NULL for the company_name field. Order by state name.
SELECT s.state_name, s.state_abbr , c.company_name
FROM us_states s
LEFT JOIN customers c
ON c.region = s.state_abbr
ORDER BY s.state_name;

-- List territory ID, employee title of courtesy, and employee last name for all employees in all territories.
-- If a territory has no employees assigned, list its ID with NULL filled in for the relevant employee fields. Sort by territory ID.
SELECT  t.territory_id, e.title_of_courtesy , e.last_name
FROM employees e
JOIN employee_territories t
ON t.employee_id = t.employee_id;

-- For each order, list the order ID and the number of unique products in said order (call this product_count).
-- Filter to only include orders with at least 5 unique products. Sort by product_count in descending order.
SELECT  od.order_id, COUNT(od.product_id) AS product_count
FROM order_details od
GROUP BY od.order_id
HAVING COUNT(*) > 5
ORDER BY product_count DESC

-- Management needs a list of all suppliers and customers for their holiday greetings card!
-- Provide a list with the company name, address, city, region, postal code, and country for all suppliers and customers.
-- Sort by company name.
SELECT  company_name, address, city, region, postal_code, country
FROM customers
ORDER BY company_name;