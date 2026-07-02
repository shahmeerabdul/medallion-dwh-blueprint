-- =============================================================================
-- 02_cumulative_analysis.sql
-- Purpose: Running total of sales by year and 3-month moving average by month.
-- Layer:   Gold (fact_orders)
-- Technique: Window functions — SUM() OVER for running totals,
--            AVG() OVER with ROWS BETWEEN for moving averages.
-- SOC:     Business analytics only — no ETL logic.
-- =============================================================================

USE medallion_dw;

WITH monthly_sales AS (
    -- Base CTE: monthly grain is the foundation for both window calculations
    SELECT
        OrderYear,
        OrderMonth,
        CONCAT(OrderYear, '-', LPAD(OrderMonth, 2, '0'))      AS YearMonth,
        SUM(Sales)                                            AS MonthlySales
    FROM fact_orders
    GROUP BY OrderYear, OrderMonth
),

running_totals AS (
    SELECT
        OrderYear,
        OrderMonth,
        YearMonth,
        MonthlySales,
        -- Running total resets each year via PARTITION BY OrderYear
        -- ORDER BY month ensures cumulative sequence within the partition
        SUM(MonthlySales) OVER (
            PARTITION BY OrderYear
            ORDER BY OrderMonth
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                     AS RunningTotalSalesByYear
    FROM monthly_sales
)

SELECT
    OrderYear,
    OrderMonth,
    YearMonth,
    MonthlySales,
    RunningTotalSalesByYear
FROM running_totals
ORDER BY OrderYear, OrderMonth;

-- -----------------------------------------------------------------------------
-- 3-Month Moving Average of Sales
-- AVG() OVER with a sliding 3-row window smooths short-term volatility.
-- -----------------------------------------------------------------------------
WITH monthly_sales AS (
    SELECT
        OrderYear,
        OrderMonth,
        CONCAT(OrderYear, '-', LPAD(OrderMonth, 2, '0'))      AS YearMonth,
        SUM(Sales)                                            AS MonthlySales
    FROM fact_orders
    GROUP BY OrderYear, OrderMonth
)
SELECT
    OrderYear,
    OrderMonth,
    YearMonth,
    MonthlySales,
    ROUND(
        AVG(MonthlySales) OVER (
            ORDER BY OrderYear, OrderMonth
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    )                                                         AS MovingAvg3MonthSales
FROM monthly_sales
ORDER BY OrderYear, OrderMonth;
