-- =============================================================================
-- 03_salesperson_performance.sql
-- Purpose: Compare current-year vs. previous-year sales per SalesPerson.
-- Layer:   Gold (fact_orders, dim_employees)
-- Technique: CTE for yearly rep totals; LAG() window function for YoY comparison.
-- SOC:     Business analytics only — no ETL logic.
-- =============================================================================

USE medallion_dw;

WITH salesperson_yearly_sales AS (
    -- Aggregate sales at SalesPerson × Year grain
    SELECT
        f.SalesPersonID,
        e.FullName                                              AS SalesPersonName,
        e.Department,
        f.OrderYear,
        SUM(f.Sales)                                            AS YearlySales,
        COUNT(DISTINCT f.OrderID)                               AS OrderCount
    FROM fact_orders f
    JOIN dim_employees e ON f.SalesPersonID = e.EmployeeID
    WHERE e.Department = 'Sales'
    GROUP BY f.SalesPersonID, e.FullName, e.Department, f.OrderYear
),

yoy_comparison AS (
    SELECT
        SalesPersonID,
        SalesPersonName,
        Department,
        OrderYear,
        YearlySales,
        OrderCount,
        -- LAG retrieves the prior year's sales for the same salesperson
        -- PARTITION BY SalesPersonID ensures each rep's history is isolated
        LAG(YearlySales) OVER (
            PARTITION BY SalesPersonID
            ORDER BY OrderYear
        )                                                       AS PreviousYearSales,
        LAG(OrderYear) OVER (
            PARTITION BY SalesPersonID
            ORDER BY OrderYear
        )                                                       AS PreviousYear
    FROM salesperson_yearly_sales
)

SELECT
    SalesPersonID,
    SalesPersonName,
    OrderYear                                                 AS CurrentYear,
    YearlySales                                               AS CurrentYearSales,
    PreviousYear,
    PreviousYearSales,
    -- YoY change: absolute and percentage (NULL-safe when no prior year exists)
    ROUND(YearlySales - COALESCE(PreviousYearSales, 0), 2)    AS SalesChange,
    ROUND(
        CASE
            WHEN PreviousYearSales IS NULL OR PreviousYearSales = 0 THEN NULL
            ELSE ((YearlySales - PreviousYearSales) / PreviousYearSales) * 100
        END,
        2
    )                                                         AS YoYChangePct
FROM yoy_comparison
ORDER BY SalesPersonName, OrderYear;

-- -----------------------------------------------------------------------------
-- LEAD function: preview next year's sales for forward-looking comparison
-- -----------------------------------------------------------------------------
WITH salesperson_yearly_sales AS (
    SELECT
        f.SalesPersonID,
        e.FullName                                              AS SalesPersonName,
        f.OrderYear,
        SUM(f.Sales)                                            AS YearlySales
    FROM fact_orders f
    JOIN dim_employees e ON f.SalesPersonID = e.EmployeeID
    WHERE e.Department = 'Sales'
    GROUP BY f.SalesPersonID, e.FullName, f.OrderYear
)
SELECT
    SalesPersonID,
    SalesPersonName,
    OrderYear,
    YearlySales,
    -- LEAD looks ahead one year — useful for identifying upcoming performance gaps
    LEAD(YearlySales) OVER (
        PARTITION BY SalesPersonID
        ORDER BY OrderYear
    )                                                         AS NextYearSales
FROM salesperson_yearly_sales
ORDER BY SalesPersonName, OrderYear;
