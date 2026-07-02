-- =============================================================================
-- 01_sales_trends.sql
-- Purpose: Change-over-time analysis — total sales by Year and Month.
-- Layer:   Gold (fact_orders)
-- Technique: CTE aggregates at monthly grain; outer query adds readable labels.
-- SOC:     Business analytics only — no ETL logic.
-- =============================================================================

USE medallion_dw;

WITH monthly_sales AS (
    -- CTE isolates the monthly aggregation logic for clarity and reuse
    SELECT
        OrderYear,
        OrderMonth,
        COUNT(DISTINCT OrderID)                               AS OrderCount,
        SUM(Quantity)                                         AS TotalQuantity,
        SUM(Sales)                                            AS TotalSales
    FROM fact_orders
    GROUP BY OrderYear, OrderMonth
)
SELECT
    OrderYear,
    OrderMonth,
    -- CONCAT produces a human-readable period label for reporting
    CONCAT(OrderYear, '-', LPAD(OrderMonth, 2, '0'))          AS YearMonth,
    OrderCount,
    TotalQuantity,
    TotalSales
FROM monthly_sales
ORDER BY OrderYear, OrderMonth;

-- Year-level rollup derived from the same CTE pattern
WITH yearly_sales AS (
    SELECT
        OrderYear,
        COUNT(DISTINCT OrderID)                               AS OrderCount,
        SUM(Quantity)                                         AS TotalQuantity,
        SUM(Sales)                                            AS TotalSales
    FROM fact_orders
    GROUP BY OrderYear
)
SELECT
    OrderYear,
    OrderCount,
    TotalQuantity,
    TotalSales,
    ROUND(TotalSales / OrderCount, 2)                         AS AvgSalesPerOrder
FROM yearly_sales
ORDER BY OrderYear;
