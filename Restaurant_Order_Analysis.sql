CREATE DATABASE Restaurant_orders;

-- Retrieving all columns from menu_items
SELECT * FROM dbo.menu_items
--	Display the first 5 rows from the order_details table.
SELECT TOP 5 * FROM dbo.menu_items;

-- Select the item_name and price columns for items in the 'Main Course' category.
-- Sort the result by price in descending order
SELECT item_name, price FROM dbo.menu_items
WHERE category= 'Main Course'
ORDER BY price DESC

-- Calculate the average price of menu items.
SELECT AVG(price) as avg_price FROM dbo.menu_items

-- Find the total number of orders placed.
SELECT COUNT(DISTINCT(order_details_id)) as total_orders FROM order_details

-- Retrieve the item_name, order_date, and order_time for all items in the order_details table, including their respective menu item details
SELECT item_name, order_date, order_time,menu.menu_item_id as item_id, category,price FROM order_details AS orders
LEFT OUTER JOIN menu_items AS menu
	ON menu.menu_item_id= orders.item_id
	;

-- List the menu items (item_name) with a price greater than the average price of all menu items
SELECT item_name FROM menu_items
WHERE price> (SELECT AVG(price) FROM menu_items);

-- Extract the month from the order_date and count the number of orders placed in each month.
SELECT MONTH(order_date) AS months,
	COUNT(order_details_id) AS num_orders_placed
	FROM order_details 
GROUP BY MONTH(order_date)
ORDER BY 1;

-- - Show the categories with the average price greater than $15.
SELECT category,AVG(price) AS avg_price
FROM menu_items
GROUP BY category
HAVING AVG(price)>15

-- Include the count of items in each category.
SELECT category,AVG(price),COUNT(category) AS avg_price
FROM menu_items
GROUP BY category

-- Display the item_name and price, and indicate if the item is priced above $20 with a new column named 'Expensive'.

SELECT item_name,price,
CASE
	WHEN price>20 THEN 'Yes' 
	ELSE 'No'
END AS Expenisve
FROM menu_items

-- Update the price of the menu item with item_id = 101 to $25

UPDATE menu_items
SET price=25 WHERE 
menu_item_id = 101;
SELECT * FROM menu_items -- To see the changes
WHERE 
menu_item_id = 101;

-- Insert a new record into the menu_items table for a dessert item.
INSERT INTO menu_items
VALUES(133,'Dessert','Sweet',2);
SELECT * FROM menu_items -- To see the changes
WHERE item_name='Dessert'

-- Delete all records from the order_details table where the order_id is less than 100.
DELETE FROM order_details
WHERE order_id<100

SELECT * FROM order_details
WHERE order_id<100

-- Rank menu items based on their prices, displaying the item_name and its rank
SELECT item_name,
RANK() OVER(ORDER BY price) as "rank"
FROM menu_items

-- Display the item_name and the price difference from the previous and next menu item.
SELECT item_name,price,
CASE
	WHEN prev_item_price=0 THEN 0
	ELSE	
	ABS(price-prev_item_price)
END as prev_price_diff,
CASE
	WHEN next_item_price=0 THEN 0
	ELSE	
	ABS(price-next_item_price)
END as next_price_diff
FROM(SELECT item_name,price,
LAG(price,1,0) OVER(ORDER BY menu_item_id) as prev_item_price,
LEAD(price,1,0) OVER(ORDER BY menu_item_id) as next_item_price
FROM menu_items) as sub

-- Create a CTE that lists menu items with prices above $15.
-- Use the CTE to retrieve the count of such items.
WITH menu_item AS 
(SELECT * FROM menu_items
WHERE price>15)
SELECT COUNT(*) as count_above_$15
FROM menu_item

-- Retrieve the order_id, item_name, and price for all orders with their respective menu item details.
-- Include rows even if there is no matching menu item.
SELECT order_id,item_name,price,menu_item_id,category
FROM order_details as orders
FULL JOIN menu_items as menu
	ON orders.item_id=menu.menu_item_id

-- Unpivot the menu_items table to show a list of menu item properties (item_id, item_name, category, price).
SELECT 
    menu_item_id, 
    item_name, 
    property,
    value
FROM 
    (SELECT 
        menu_item_id, 
        item_name, 
        CAST(category AS VARCHAR(50)) AS category, 
        CAST(price AS VARCHAR(50)) AS price
     FROM 
        menu_items
    ) AS source
UNPIVOT
(
    value FOR property IN (category, price)
) AS unpvt;

SELECT * FROM menu_items

--Write a dynamic SQL query that allows users to filter menu items based on category and price range.

DECLARE @Category NVARCHAR(50) = NULL; -- Set to NULL for all categories, or specify like 'Asian'
DECLARE @MinPrice DECIMAL(5,2) = NULL; -- Set to NULL for no minimum, or specify like 10.00
DECLARE @MaxPrice DECIMAL(5,2) = NULL; -- Set to NULL for no maximum, or specify like 15.00

DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
SELECT menu_item_id, item_name, category, price
FROM menu_items
WHERE 1=1';

IF @Category IS NOT NULL
BEGIN
    SET @SQL = @SQL + N' AND category = @Category';
END

IF @MinPrice IS NOT NULL
BEGIN
    SET @SQL = @SQL + N' AND price >= @MinPrice';
END

IF @MaxPrice IS NOT NULL
BEGIN
    SET @SQL = @SQL + N' AND price <= @MaxPrice';
END

SET @SQL = @SQL + N' ORDER BY price';

PRINT @SQL; -- This will show you the constructed query

EXEC sp_executesql @SQL, 
    N'@Category NVARCHAR(50), @MinPrice DECIMAL(5,2), @MaxPrice DECIMAL(5,2)',
    @Category, @MinPrice, @MaxPrice;

-- Create a stored procedure that takes a menu category as input and returns the average price for that category

CREATE PROCEDURE avg_price_provider
	@menu_category VARCHAR(50)=NULL
AS
BEGIN
	SELECT AVG(price) as avg_price FROM menu_items
	WHERE category=@menu_category;
END
EXEC avg_price_provider @menu_category= 'Asian'

-- Design a trigger that updates a log table whenever a new order is inserted into the order_details table.
CREATE TABLE order_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    order_details_id INT,
    order_id INT,
    log_date DATETIME,
    action VARCHAR(50)
);
CREATE TRIGGER tr_LogNewOrder
ON order_details
AFTER INSERT
AS
BEGIN
    INSERT INTO order_log (order_details_id, order_id, log_date, action)
    SELECT 
        i.order_details_id,
        i.order_id,
        GETDATE(),
        'New Order Inserted'
    FROM 
        inserted i;
END
INSERT INTO order_details (order_details_id, order_id, order_date, order_time, item_id)
VALUES (12235,5371, '2023-06-26', '14:30:00', 5001);
SELECT * FROM order_log;























