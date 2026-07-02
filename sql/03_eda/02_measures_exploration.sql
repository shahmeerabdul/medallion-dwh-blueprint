-- =============================================================================
-- 02_measures_exploration.sql
-- Purpose: EDA — calculate key aggregate measures (big numbers) from Gold layer.
-- Layer:   Gold (fact_orders, dim_products)
-- SOC:     Read-only analytics; no ETL or transformation logic.
-- =============================================================================

USE medallion_dw;

-- -----------------------------------------------------------------------------
-- Overall Business KPIs
-- Single-row summary of total revenue, units sold, and average product price.
-- -----------------------------------------------------------------------------
SELECT
    SUM(f.Sales)                                              AS TotalSales,
    SUM(f.Quantity)                                           AS TotalQuantitySold,
    COUNT(DISTINCT f.OrderID)                                 AS TotalOrders,
    COUNT(DISTINCT f.CustomerID)                              AS UniqueCustomers,
    ROUND(AVG(p.Price), 2)                                    AS AvgProductPrice
FROM fact_orders f
JOIN dim_products p ON f.ProductID = p.ProductID;

-- -----------------------------------------------------------------------------
-- Sales and Quantity by Order Status
-- Reveals revenue distribution across fulfillment states.
-- -----------------------------------------------------------------------------
SELECT
    OrderStatus,
    COUNT(DISTINCT OrderID)                                   AS OrderCount,
    SUM(Quantity)                                             AS TotalQuantity,
    SUM(Sales)                                                AS TotalSales,
    ROUND(AVG(Sales), 2)                                      AS AvgOrderLineSales
FROM fact_orders
GROUP BY OrderStatus
ORDER BY TotalSales DESC;

-- -----------------------------------------------------------------------------
-- Revenue by Source System (current vs. archive)
-- Validates data union from Bronze/Silver ETL pipeline.
-- -----------------------------------------------------------------------------
SELECT
    SourceSystem,
    COUNT(DISTINCT OrderID)                                   AS OrderCount,
    SUM(Sales)                                                AS TotalSales,
    SUM(Quantity)                                             AS TotalQuantity
FROM fact_orders
GROUP BY SourceSystem;

-- -----------------------------------------------------------------------------
-- Product Category Performance
-- AVG(Price) at category level complements revenue totals.
-- -----------------------------------------------------------------------------
SELECT
    p.Category,
    COUNT(DISTINCT p.ProductID)                               AS ProductCount,
    SUM(f.Quantity)                                           AS UnitsSold,
    SUM(f.Sales)                                              AS TotalSales,
    ROUND(AVG(p.Price), 2)                                    AS AvgCategoryPrice
FROM fact_orders f
JOIN dim_products p ON f.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY TotalSales DESC;
