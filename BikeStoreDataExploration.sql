--Find the stock for the bikes released in 2018
SELECT 
	prod.product_id,
	prod.product_name,
	prod.model_year,
	SUM(sto.quantity) AS 'StoreQty'
FROM
	production.stocks sto
JOIN
	production.products prod
ON
	sto.product_id = prod.product_id
WHERE
	prod.model_year = '2018' 
GROUP BY
	prod.product_id,
	prod.product_name,
	prod.model_year

--Finds all bikes released in the most recent year
SELECT 
	prod.product_name,
	prod.model_year
FROM
	production.products prod
WHERE prod.model_year = 
	(SELECT 
		MAX(model_year)
	FROM
		production.products)

--Which store had the most sales?
USE BikeStores;

SELECT TOP 1
	stor.store_name,
	ROUND(SUM((ordI.list_price * ordI.quantity) - ((ordI.list_price * ordI.quantity) * (ordI.discount * ordI.quantity))), 2) AS 'sale_amount'
FROM
	sales.stores stor
JOIN
	sales.orders ord
ON
	stor.store_id = ord.store_id
JOIN
	sales.order_items ordI
ON 
	ord.order_id = ordI.order_id
GROUP BY
	stor.store_name
ORDER BY
	ROUND(SUM((ordI.list_price * ordI.quantity) - ((ordI.list_price * ordI.quantity) * (ordI.discount * ordI.quantity))), 2) DESC

--Who was the best sales person? Validate.
SELECT
	sta.staff_id,
	CONCAT(sta.first_name,' ', sta.last_name) AS 'Full_Name',
	COUNT(DISTINCT(ord.order_id)) AS 'Number_of_Orders_Sold',
	SUM(oitm.list_price) AS 'Total_Sales'
FROM
	sales.orders ord
JOIN
	sales.staffs sta
ON 
	ord.staff_id = sta.staff_id
JOIN
	sales.order_items oitm
ON
	oitm.order_id = ord.order_id
GROUP BY
	sta.staff_id,
	sta.first_name,
	sta.last_name
ORDER BY
	SUM(oitm.list_price) DESC

--Create a query using a temporary table that shows the quantity sold each year and what percentage of that belongs to each category
USE BikeStores

WITH quantity_sold (category_name,year,Total_Quantity_Sold) AS (
	SELECT DISTINCT 
		CATE.category_name,
		YEAR(ORD.shipped_date) AS 'Year',
		SUM(ORDI.quantity)  AS 'Total_Quantity_Sold'
	FROM
		sales.orders ORD
	JOIN
		sales.order_items ORDI
	ON
		ORD.order_id = ORDI.order_id
	JOIN
		production.products PROD
	ON
		ORDI.product_id = PROD.product_id
	JOIN
		production.categories CATE
	ON
		PROD.category_id = CATE.category_id
	WHERE
		ORD.shipped_date IS NOT NULL
	GROUP BY
		CATE.category_name,
		YEAR(ORD.shipped_date)
)


SELECT 
    QSOL.category_name, 
    QSOL.year,
	QSOL.Total_Quantity_Sold,
	SUM(QSOL.Total_Quantity_Sold) OVER (PARTITION BY QSOL.year),
	(CAST(QSOL.Total_Quantity_Sold as decimal) / SUM(QSOL.Total_Quantity_Sold) OVER (PARTITION BY QSOL.year)) * 100 AS Total_Quantity_Sold
FROM 
    quantity_sold QSOL
ORDER BY
	QSOL.year

--Create Views to find the store with the most sales
GO
CREATE VIEW 
	SalesPerStore 
AS
SELECT
	STOR.store_id,
	STOR.store_name,
	STOR.state,
	COUNT(ORD.order_id) AS 'Total_Number_of_Orders',
	SUM(ORDI.quantity) AS 'Total_Quantity_Sold',
	CAST(ROUND(SUM(ORDI.list_price - (ORDI.list_price * ORDI.discount / 100)), 2) AS float) AS 'Total_Sales'
FROM
	sales.stores STOR
LEFT JOIN
	sales.orders ORD
ON
	STOR.store_id = ORD.store_id
RIGHT JOIN
	sales.order_items ORDI
ON
	ORD.order_id = ORDI.order_id
WHERE
	ORD.shipped_date IS NOT NULL
GROUP BY
	STOR.store_id,
	STOR.store_name,
	STOR.state
GO

SELECT 
	*
FROM
	SalesPerStore SPS
ORDER BY
	SPS.Total_Sales DESC

--Use query with case statement that gives a rank to employees who sell above the companies sales goals
USE BikeStores

SELECT 
	STA.first_name + ' ' + STA.last_name AS 'Name',
	STO.store_name,
	STO.state,
	COUNT(ORD.order_id) AS 'Total_Orders',
	CAST(ROUND(SUM(ORDI.list_price - (ORDI.list_price * ORDI.discount / 100)), 2) AS float) AS 'Total_Sales',
	CASE
		WHEN SUM(ORDI.list_price) >= 1000000 THEN 'Yes'
		ELSE 'No'
	END AS 'Sales_Goal_Meant'
FROM
	sales.stores STO
JOIN
	sales.staffs STA
ON
	STO.store_id = STA.store_id
JOIN
	sales.orders ORD
ON
	STA.staff_id = ORD.staff_id
JOIN
	sales.order_items ORDI
ON
	ORD.order_id = ORDI.order_id
WHERE
	ORD.shipped_date IS NOT NULL
GROUP BY
	STA.first_name,
	STA.last_name,
	STO.store_name,
	STO.state
ORDER BY
	CAST(ROUND(SUM(ORDI.list_price - (ORDI.list_price * ORDI.discount / 100)), 2) AS float) DESC
