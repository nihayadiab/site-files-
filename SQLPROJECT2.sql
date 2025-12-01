----=======project 2
------========nihaya_diab_hamed---==========

---****ex1

select y.year, y.IncomePerYear,  y.NumberOfDistinctMonths,  
       CAST(y.YearlyLinearIncome  AS DECIMAL(18,2)) AS YearlyLinearIncome, 
       CAST(
        (YearlyLinearIncome - LAG(YearlyLinearIncome) OVER (ORDER BY [year])) * 100.0
        / NULLIF(LAG(YearlyLinearIncome) OVER (ORDER BY [year]), 0)
        AS DECIMAL(5,2)
          ) AS GrowthRate
from(
        select  year(salord.OrderDate) as 'year',
                SUM(salin.ExtendedPrice - salin.TaxAmount) as IncomePerYear,
                count ( distinct month(salord.OrderDate)) as NumberOfDistinctMonths,
                sum (salin.ExtendedPrice - salin.TaxAmount)/ count ( distinct month(salord.OrderDate))*12 as YearlyLinearIncome     
        from
         sales.InvoiceLines salin join Sales.Invoices salor
        on salin.InvoiceID=salor.InvoiceID
        join Sales.Orders salord
        on salor.OrderID=salord.OrderID
        group BY year(salord.OrderDate)
) y
order by 'year'


--****ex 2

select *
from (
        select y.TheYear,
               y.TheQuarter,
               y.CustomerName,
               y.IncomePerYear,
               ROW_NUMBER() OVER (PARTITION BY y.TheYear, y.TheQuarter ORDER BY y.IncomePerYear DESC) AS DNR

        from (
             select YEAR (salord.OrderDate)                    as TheYear,
                    datepart (QUARTER,salord.OrderDate)        as TheQuarter,
                    salcu.CustomerName,
                    SUM(sinl.ExtendedPrice - sinl.TaxAmount)   as IncomePerYear
             from sales.Orders salord 
                  join sales.Customers salcu   on salord.CustomerID=salcu.CustomerID
                  join Sales.Invoices saIn     on salord.OrderID=saIn.OrderID
                  join Sales.InvoiceLines sinl on sain.InvoiceID=sinl.InvoiceID
            group BY   YEAR(salord.OrderDate),
                       DATEPART(QUARTER, salord.OrderDate),
                       salcu.CustomerID,
                       salcu.CustomerName
            ) y
        )ranked
where  ranked.DNR <=5
order by ranked.TheYear,ranked.TheQuarter,ranked.DNR 


--****ex 3

select top (10)
           wsi.StockItemID,
           wsi.StockItemName,
           SUM(sinl.ExtendedPrice - sinl.TaxAmount)   as TotalProfit 
from sales.InvoiceLines sinl JOIN Warehouse.StockItems wsi
     on sinl.StockItemID=wsi.StockItemID
group BY wsi.StockItemID,
         wsi.StockItemName             
order by TotalProfit desc 



--****ex 4

select *
from (
        select ROW_NUMBER() OVER (ORDER BY y.NominalProductProfit DESC) AS RN,
               y.StockItemID,
               y.StockItemName,
               y.UnitPrice,
               y.RecommendedRetailPrice,
               y.NominalProductProfit,
               dense_RANK() OVER (ORDER BY y.NominalProductProfit DESC) AS DNR
        from(  
               select     
               StockItemID,
               StockItemName,
               UnitPrice,
               RecommendedRetailPrice,
               (RecommendedRetailPrice - UnitPrice) as NominalProductProfit
               from Warehouse.StockItems
               where ValidTo >GETDATE()
             ) y
       ) x
       
order by DNR

      
--****ex 5

SELECT  concat (ps.SupplierID, ' - ' ,ps.SupplierName) as SupplierDetails,
        string_agg ( CONCAT (ws.StockItemID ,' ', ws.StockItemName), ' /, ') as ProductDetails
FROM Warehouse.StockItems ws join Purchasing.Suppliers ps
on ws.SupplierID=ps.SupplierID
group by ps.SupplierID, ps.SupplierName


--****ex 6

SELECT TOP (5)
    c.CustomerID,
    ci.CityName,
    co.CountryName,
    co.Continent,
    co.Region,
    CAST(SUM(il.ExtendedPrice) AS DECIMAL(18,2)) AS TotalExtendedPrice
FROM Sales.InvoiceLines      AS il
join Sales.Invoices          AS i   ON i.InvoiceID   = il.InvoiceID
join Sales.Customers         AS c   ON c.CustomerID  = i.CustomerID
join Application.Cities AS ci  ON ci.CityID     = COALESCE(c.DeliveryCityID, c.PostalCityID)
 join Application.StateProvinces AS sp ON sp.StateProvinceID = ci.StateProvinceID
 join Application.Countries      AS co ON co.CountryID       = sp.CountryID
GROUP BY
    c.CustomerID, ci.CityName, co.CountryName, co.Continent, co.Region
ORDER BY TotalExtendedPrice DESC


--****ex 7

WITH CTE1 AS (   
    SELECT
        YEAR(o.OrderDate)  AS OrderYear,
        MONTH(o.OrderDate) AS OrderMonth,
        SUM(il.ExtendedPrice- il.TaxAmount) AS MonthlyTotal   
    FROM Sales.Invoices i
    JOIN Sales.Orders o        ON i.OrderID   = o.OrderID
    JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
),
CTE2 AS (       
    SELECT
        OrderYear,
        OrderMonth,
        MonthlyTotal,
        SUM(MonthlyTotal) OVER (
            PARTITION BY OrderYear
            ORDER BY OrderMonth
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeTotal
    FROM CTE1
)
SELECT
    OrderYear,
    OrderMonthLabel AS OrderMonth,
    FORMAT(MonthlyTotal,   '#,#.00') AS MonthlyTotal,
    FORMAT(CumulativeTotal,'#,#.00') AS CumulativeTotal
FROM (
    SELECT
        OrderYear,
        CAST(OrderMonth AS nvarchar(12)) AS OrderMonthLabel,
        CAST(MonthlyTotal   AS decimal(18,2)) AS MonthlyTotal,
        CAST(CumulativeTotal AS decimal(18,2)) AS CumulativeTotal,
        OrderMonth AS SortMonth
    FROM CTE2

    UNION ALL

    SELECT
        OrderYear,
        N'Grand Total' AS OrderMonthLabel,
        CAST(SUM(MonthlyTotal) AS decimal(18,2)) AS MonthlyTotal,
        CAST(SUM(MonthlyTotal) AS decimal(18,2)) AS CumulativeTotal,
        99 AS SortMonth
    FROM CTE2
    GROUP BY OrderYear
) U
ORDER BY OrderYear, SortMonth



--****ex 8

select OrderMonth, [2013], [2014],[2015],[2016]
from (select year(orderdate) y , month (orderdate) OrderMonth, orderid
      from Sales.Orders) p
pivot (count (orderid) for y in ( [2013], [2014],[2015],[2016])) t
order by 1


----------ex9 

DECLARE @m date = (SELECT MAX(o.OrderDate) FROM Sales.Orders o);
DECLARE @n decimal(10,2) = 2.0; 

WITH O AS (
    SELECT
        o.CustomerID,
        o.OrderID,
        o.OrderDate,
        LAG(o.OrderDate) OVER (
            PARTITION BY o.CustomerID
            ORDER BY o.OrderDate
        ) AS PreviousOrderDate
    FROM Sales.Orders o
),
S AS (
    SELECT
        CustomerID,
        OrderID,
        OrderDate,
        PreviousOrderDate,
        CASE WHEN PreviousOrderDate IS NULL THEN NULL
             ELSE DATEDIFF(DAY, PreviousOrderDate, OrderDate) END AS DaysBetweenOrders,
        MAX(OrderDate) OVER (PARTITION BY CustomerID) AS LastOrderDate
    FROM O
),
A AS (   
    SELECT
        CustomerID,
        AVG(CAST(DaysBetweenOrders AS decimal(10,2))) AS AvgDaysBetweenOrders
    FROM S
    WHERE DaysBetweenOrders IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    c.CustomerID,
    c.CustomerName,
    s.OrderDate,
    s.PreviousOrderDate,
    DATEDIFF(DAY, s.LastOrderDate, @m)        AS DaysSinceLastOrder,  
    CAST(a.AvgDaysBetweenOrders AS int)          AS AvgDaysBetweenOrders,
    CASE
        WHEN a.AvgDaysBetweenOrders IS NULL THEN 'Active'
        WHEN DATEDIFF(DAY, s.LastOrderDate, @m) > @n * a.AvgDaysBetweenOrders
             THEN 'Potential Churn'
        ELSE 'Active'
    END AS CustomerStatus
FROM S s
JOIN Sales.Customers c ON c.CustomerID = s.CustomerID
LEFT JOIN A a          ON a.CustomerID = s.CustomerID
ORDER BY c.CustomerID, s.OrderDate

----------ex10
SELECT
    X.CustomerCategoryName,
    X.CustomerCOUNT,
    X.TotalCustCount,
    CONCAT(CAST(100.0 * X.CustomerCOUNT / X.TotalCustCount AS DECIMAL(5,2)), '%') AS DistributionFactor
FROM (
    SELECT
        T.CustomerCategoryName,
        T.CustomerCOUNT,
        SUM(T.CustomerCOUNT) OVER () AS TotalCustCount
    FROM (
        SELECT
            C.CustomerCategoryName,
            COUNT(DISTINCT C.CustomerName) AS CustomerCOUNT
        FROM (
            SELECT
                cc.CustomerCategoryName,
                CASE
                    WHEN c.CustomerName LIKE 'Tailspin%' THEN 'Tailspin'
                    WHEN c.CustomerName LIKE 'Wingtip%'  THEN 'Wingtip'
                    ELSE c.CustomerName
                END AS CustomerName
            FROM Sales.Customers AS c
            JOIN Sales.CustomerCategories AS cc
              ON c.CustomerCategoryID = cc.CustomerCategoryID
        ) AS C
        GROUP BY C.CustomerCategoryName
    ) AS T
) AS X
ORDER BY X.CustomerCategoryName















