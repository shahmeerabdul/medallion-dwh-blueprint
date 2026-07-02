-- =============================================================================
-- 03_magnitude_analysis.sql
-- Purpose: EDA — group measures by dimensions to understand magnitude patterns.
-- Layer:   Gold (fact_orders, dim_customers, dim_employees, dim_products)
-- SOC:     Read-only analytics; no ETL or transformation logic.
-- =============================================================================

USE medallion_dw;

-- -----------------------------------------------------------------------------
-- Total Sales by Country
-- Joins fact to customer dimension for geographic revenue breakdown.
-- -----------------------------------------------------------------------------
SELECT
    c.Country,
    COUNT(DISTINCT c.CustomerID)                              AS CustomerCount,
    COUNT(DISTINCT f.OrderID)                                 AS OrderCount,
    SUM(f.Sales)                                              AS TotalSales,
    ROUND(SUM(f.Sales) / COUNT(DISTINCT f.OrderID), 2)        AS AvgSalesPerOrder
FROM fact_orders f
JOIN dim_customers c ON f.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalSales DESC;

-- -----------------------------------------------------------------------------
-- Average Salary by Department
-- Workforce compensation baseline from employee dimension.
-- -----------------------------------------------------------------------------
SELECT
    Department,
    COUNT(*)                                                  AS Headcount,
    ROUND(AVG(Salary), 2)                                     AS AvgSalary,
    MIN(Salary)                                               AS MinSalary,
    MAX(Salary)                                               AS MaxSalary,
    ROUND(SUM(Salary), 2)                                     AS TotalPayroll
FROM dim_employees
GROUP BY Department
ORDER BY AvgSalary DESC;

-- -----------------------------------------------------------------------------
-- Sales by Sales Person (Employee)
-- Links fact orders to employee dimension for rep-level magnitude.
-- -----------------------------------------------------------------------------
SELECT
    e.EmployeeID,
    e.FullName,
    e.Department,
    COUNT(DISTINCT f.OrderID)                                 AS OrdersHandled,
    SUM(f.Quantity)                                           AS UnitsSold,
    SUM(f.Sales)                                              AS TotalSales
FROM fact_orders f
JOIN dim_employees e ON f.SalesPersonID = e.EmployeeID
GROUP BY e.EmployeeID, e.FullName, e.Department
ORDER BY TotalSales DESC;

-- -----------------------------------------------------------------------------
-- Customer Value Segment Distribution
-- Validates Gold ETL segmentation logic applied during dim_customers load.
-- -----------------------------------------------------------------------------
SELECT
    CustomerValueSegment,
    COUNT(*)                                                  AS CustomerCount,
    ROUND(AVG(Score), 1)                                      AS AvgScore,
    MIN(Score)                                                AS MinScore,
    MAX(Score)                                                AS MaxScore
FROM dim_customers
GROUP BY CustomerValueSegment
ORDER BY FIELD(CustomerValueSegment, 'High', 'Medium', 'Low');

-- -----------------------------------------------------------------------------
-- Quantity Sold by Product Category
-- Cross-dimensional magnitude: product category × units.
-- -----------------------------------------------------------------------------
SELECT
    p.Category,
    p.Product,
    SUM(f.Quantity)                                           AS TotalQuantity,
    SUM(f.Sales)                                              AS TotalSales
FROM fact_orders f
JOIN dim_products p ON f.ProductID = p.ProductID
GROUP BY p.Category, p.Product
ORDER BY p.Category, TotalSales DESC;
