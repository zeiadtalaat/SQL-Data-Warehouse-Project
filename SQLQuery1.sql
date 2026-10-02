DROP TABLE IF EXISTS FactSales;

DROP TABLE IF EXISTS DimLocation;

DROP TABLE IF EXISTS DimProduct;

DROP TABLE IF EXISTS DimCustomer;

DROP TABLE IF EXISTS DimDate;
----Normalize the dataset into fact and dimension tables------
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT,
    Month INT,
    MonthName NVARCHAR(20),
    Day INT
);
--
INSERT INTO DimDate
(
    DateKey,
    FullDate,
    Year,
    Month,
    MonthName,
    Day
)
SELECT DISTINCT
    CONVERT(INT, CONVERT(VARCHAR(8), d, 112)),
    d,
    YEAR(d),
    MONTH(d),
    DATENAME(MONTH, d),
    DAY(d)
FROM
(
    SELECT Order_Date AS d
    FROM Central_Superstore
    WHERE Order_Date IS NOT NULL

    UNION

    SELECT Ship_Date AS d
    FROM Central_Superstore
    WHERE Ship_Date IS NOT NULL
) AS Dates;
--
CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    Customer_ID NVARCHAR(50) NOT NULL,
    Customer_Name NVARCHAR(100),
    Segment NVARCHAR(50)
);
--
INSERT INTO DimCustomer
(
    Customer_ID,
    Customer_Name,
    Segment
)
SELECT
    Customer_ID,
    MAX(Customer_Name),
    MAX(Segment)
FROM Central_Superstore
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID;
--
CREATE TABLE DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID NVARCHAR(50) NOT NULL,
    Product_Name NVARCHAR(200),
    Category NVARCHAR(100),
    Sub_Category NVARCHAR(100)
);
--
INSERT INTO DimProduct
(
    Product_ID,
    Product_Name,
    Category,
    Sub_Category
)
SELECT
    Product_ID,
    MAX(Product_Name),
    MAX(Category),
    MAX(Sub_Category)
FROM Central_Superstore
WHERE Product_ID IS NOT NULL
GROUP BY Product_ID;
--
CREATE TABLE DimLocation (
    LocationKey INT IDENTITY(1,1) PRIMARY KEY,
    Country NVARCHAR(100),
    Region NVARCHAR(100),
    State NVARCHAR(100),
    City NVARCHAR(100),
    Postal_Code NVARCHAR(20)
);
--
INSERT INTO DimLocation
(
    Country,
    Region,
    State,
    City,
    Postal_Code
)
SELECT
    Country,
    Region,
    State,
    City,
    CAST(Postal_Code AS NVARCHAR(20))
FROM Central_Superstore
GROUP BY
    Country,
    Region,
    State,
    City,
    Postal_Code;
------------------------
--Create primary and foreign key relationships--
-----------------

CREATE TABLE FactSales (
    SalesKey INT IDENTITY(1,1) PRIMARY KEY,

    Order_ID NVARCHAR(50) NOT NULL,

    OrderDateKey INT,
    ShipDateKey INT,

    CustomerKey INT,
    ProductKey INT,
    LocationKey INT,

    Sales DECIMAL(18,4),
    Quantity INT,
    Discount DECIMAL(18,4),
    Profit DECIMAL(18,4),

    FOREIGN KEY (OrderDateKey)
        REFERENCES DimDate(DateKey),

    FOREIGN KEY (ShipDateKey)
        REFERENCES DimDate(DateKey),

    FOREIGN KEY (CustomerKey)
        REFERENCES DimCustomer(CustomerKey),

    FOREIGN KEY (ProductKey)
        REFERENCES DimProduct(ProductKey),

    FOREIGN KEY (LocationKey)
        REFERENCES DimLocation(LocationKey)
);
--
INSERT INTO FactSales
(
    Order_ID,
    OrderDateKey,
    ShipDateKey,
    CustomerKey,
    ProductKey,
    LocationKey,
    Sales,
    Quantity,
    Discount,
    Profit
)
SELECT
    r.Order_ID,

    CONVERT(INT, CONVERT(VARCHAR(8), r.Order_Date, 112)),

    CONVERT(INT, CONVERT(VARCHAR(8), r.Ship_Date, 112)),

    c.CustomerKey,
    p.ProductKey,
    l.LocationKey,
    r.Sales,
    r.Quantity,
    r.Discount,
    r.Profit

FROM Central_Superstore r

INNER JOIN DimCustomer c
    ON r.Customer_ID = c.Customer_ID

INNER JOIN DimProduct p
    ON r.Product_ID = p.Product_ID

INNER JOIN DimLocation l
    ON r.Country = l.Country
    AND r.Region = l.Region
    AND r.State = l.State
    AND r.City = l.City
    AND CAST(r.Postal_Code AS NVARCHAR(20)) = l.Postal_Code;

-----------------------
--Write advanced SQL queries using joins, subqueries, CTEs, and CASE statements--
-----------------------
--Q1--total Sales
SELECT
    SUM(Sales) AS Total_Sales
FROM FactSales;
--Q2--Total Profit
Select
    Sum(Profit) AS Total_Profit
FROM FactSales;
--Q3--TotalQuantity
SELECT
    SUM(Quantity) AS Total_Quantity
FROM FactSales;
--Q4--Total sales By year
select
d.Year,
sum(f.sales) as Total_Sales
from FactSales f
INNER JOIN DimDate d
    on f.OrderDateKey=d.DateKey
group by d.Year
order by d.Year ;
--Q5--SALES AND PROFIT BY CATEGORY
select
    p.Category,
    sum(f.sales) as Total_Sales,
    sum(f.profit) as Total_Profit
from FactSales f
inner join DimProduct p
    ON F.ProductKey=P.ProductKey
GROUP BY p.Category
order by Total_Sales desc;
--Q6--Profit by region
select
    l.Region,
    SUM(f.Sales) AS Sales,
    SUM(f.Profit) AS Profit,
CASE
        WHEN SUM(f.Sales) = 0 THEN 0
        ELSE SUM(f.Profit) / SUM(f.Sales) * 100
    END AS Profit_Margin
from FactSales f
inner join DimLocation l
    on f.LocationKey=l.LocationKey
group by l.Region
order by Profit DESC;

--Q7--CUSTOMER ANALYSIS
SELECT 
    c.Customer_ID,
    c.Customer_Name,
    SUM(f.Sales) AS Total_Spent,
    SUM(f.Profit) AS Total_Profit

FROM FactSales f
INNER JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey

GROUP BY c.Customer_ID, c.Customer_Name
ORDER BY Total_Spent DESC;


--Q8--PRODUCT ANALYSIS
SELECT
    p.Product_Name,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit

FROM FactSales f

INNER JOIN DimProduct p
    ON f.ProductKey = p.ProductKey

GROUP BY p.Product_Name
ORDER BY Total_Sales DESC;


--Q9--CUSTOMERS SPENT > AVG(SALES)
SELECT
    c.Customer_ID,
    c.Customer_Name,
    SUM(f.Sales) AS Total_Sales

FROM FactSales f
INNER JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey

GROUP BY c.Customer_ID, c.Customer_Name

HAVING SUM(f.Sales) >
(
    SELECT AVG(CustomerSales)
    FROM
    (
        SELECT
            CustomerKey,
            SUM(Sales) AS CustomerSales

        FROM FactSales
        GROUP BY CustomerKey
    ) AS CustomerTotals
)
ORDER BY Total_Sales DESC;


--Q10--CATEGORY PROFITABILITY USING CTE
WITH CategoryPerformance AS
(
    SELECT
        p.Category,
        SUM(f.Sales) AS Total_Sales,
        SUM(f.Profit) AS Total_Profit

    FROM FactSales f

    INNER JOIN DimProduct p
        ON f.ProductKey = p.ProductKey

    GROUP BY p.Category
)

SELECT
    Category,
    Total_Sales,
    Total_Profit,

    CASE
        WHEN Total_Sales = 0 THEN 0
        ELSE Total_Profit / Total_Sales * 100
    END AS Profit_Margin

FROM CategoryPerformance

ORDER BY Profit_Margin DESC;


--Q11--YEARLY SALES GROWTH USING CTE
WITH YearlySales AS
(
    SELECT
        d.Year,
        SUM(f.Sales) AS Total_Sales

    FROM FactSales f

    INNER JOIN DimDate d
        ON f.OrderDateKey = d.DateKey

    GROUP BY d.Year
)

SELECT
    Year,
    Total_Sales,

    LAG(Total_Sales) OVER
    (
        ORDER BY Year
    ) AS PreviousYearSales,

    Total_Sales -
    LAG(Total_Sales) OVER
    (
        ORDER BY Year
    ) AS SalesDifference,

    CASE
        WHEN LAG(Total_Sales) OVER (ORDER BY Year) IS NULL
            THEN NULL

        WHEN LAG(Total_Sales) OVER (ORDER BY Year) = 0
            THEN 0

        ELSE
        (
            (Total_Sales -
             LAG(Total_Sales) OVER (ORDER BY Year))
            /
            LAG(Total_Sales) OVER (ORDER BY Year)
        ) * 100
    END AS GrowthPercentage

FROM YearlySales

ORDER BY Year;
--Q12-- CASE تصنيف المبيعات باستخدام  

SELECT
    Order_ID,
    Sales,

    CASE
        WHEN Sales >= 1000 THEN 'High Sales'
        WHEN Sales >= 500 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS SalesCategory

FROM FactSales;
--Q13--MONTHLY SALES TREND
SELECT
    d.Year,
    d.Month,
    d.MonthName,

    SUM(f.Sales) AS TotalSales

FROM FactSales f

INNER JOIN DimDate d
    ON f.OrderDateKey = d.DateKey

GROUP BY
    d.Year,
    d.Month,
    d.MonthName

ORDER BY
    d.Year,
    d.Month;
--Q14--TOP 10 PRODUCTS BY PROFIT
SELECT TOP 10
    p.Product_Name,
    p.Category,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit

FROM FactSales f

INNER JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
GROUP BY
    p.Product_Name,
    p.Category

ORDER BY Total_Profit DESC;

--Q15--SALES AND PROFIT BY STATE

SELECT
    l.State,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Profit,
    SUM(f.Quantity) AS Total_Quantity

FROM FactSales f

INNER JOIN DimLocation l
    ON f.LocationKey = l.LocationKey

GROUP BY l.State

ORDER BY Total_Sales DESC;
--VIEW FOR KPI 
DROP VIEW IF EXISTS vw_SalesKPI;
GO

CREATE VIEW  vw_SalesKPI
AS
SELECT

    SUM(Sales) AS Total_Sales,

    SUM(Profit) AS Total_Profit,

    SUM(Quantity) AS Total_Quantity,

    COUNT(DISTINCT CustomerKey) AS Total_Customers,

    CASE
        WHEN SUM(Sales) = 0 THEN 0
        ELSE SUM(Profit) / SUM(Sales) * 100
    END AS Profit_Margin

FROM FactSales;
GO
---
SELECT *
FROM vw_SalesKPI;
----SWORED PROCEDURE FRO KPI 
DROP PROCEDURE IF EXISTS GetSalesKPIByYear;
GO
CREATE PROCEDURE GetSalesKPIByYear
    @Year INT
AS
BEGIN

    SELECT

        d.Year,

        SUM(f.Sales) AS Total_Sales,

        SUM(f.Profit) AS Total_Profit,

        SUM(f.Quantity) AS Total_Quantity,

        CASE
            WHEN SUM(f.Sales) = 0 THEN 0
            ELSE SUM(f.Profit) / SUM(f.Sales) * 100
        END AS Profit_Margin

    FROM FactSales f

    INNER JOIN DimDate d
        ON f.OrderDateKey = d.DateKey

    WHERE d.Year = @Year

    GROUP BY d.Year;

END;
GO

-- عرض السنوات الموجودة
SELECT DISTINCT
    Year
FROM DimDate
ORDER BY Year;

EXEC GetSalesKPIByYear @Year = 2013;
----
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_FactSales_OrderDateKey'
      AND object_id = OBJECT_ID('FactSales')
)
BEGIN

    CREATE INDEX IX_FactSales_OrderDateKey
    ON FactSales(OrderDateKey);

END;
----
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_FactSales_CustomerKey'
      AND object_id = OBJECT_ID('FactSales')
)
BEGIN

    CREATE INDEX IX_FactSales_CustomerKey
    ON FactSales(CustomerKey);

END;
-----
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_FactSales_ProductKey'
      AND object_id = OBJECT_ID('FactSales')
)
BEGIN

    CREATE INDEX IX_FactSales_ProductKey
    ON FactSales(ProductKey);

END;
----
IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_FactSales_LocationKey'
      AND object_id = OBJECT_ID('FactSales')
)
BEGIN

    CREATE INDEX IX_FactSales_LocationKey
    ON FactSales(LocationKey);

END;
--
-- عدد الـ Customers
SELECT
    COUNT(*) AS Customers
FROM DimCustomer;


-- عدد الـ Products
SELECT
    COUNT(*) AS Products
FROM DimProduct;


-- عدد الـ Dates
SELECT
    COUNT(*) AS Dates
FROM DimDate;


-- عدد الـ Locations
SELECT
    COUNT(*) AS Locations
FROM DimLocation;


-- عدد الـ Fact Rows
SELECT
    COUNT(*) AS FactRows
FROM FactSales;


-- اختبار الـ KPI View
SELECT *
FROM vw_SalesKPI;


-- عرض السنوات الموجودة
SELECT DISTINCT
    Year
FROM DimDate
ORDER BY Year;