-- =============================================================================
-- 01_date_exploration.sql
-- Purpose: EDA — explore date ranges, shipping lag, and employee age/tenure.
-- Layer:   Gold (fact_orders, dim_employees)
-- SOC:     Read-only analytics; no ETL or transformation logic.
-- =============================================================================

USE medallion_dw;

-- -----------------------------------------------------------------------------
-- Order Date Range and Shipping Duration
-- Uses MIN/MAX to establish the temporal boundaries of the order dataset.
-- DATEDIFF measures days between order placement and shipment.
-- -----------------------------------------------------------------------------
SELECT
    'Order Date Range'                                        AS Metric,
    MIN(OrderDate)                                            AS MinOrderDate,
    MAX(OrderDate)                                            AS MaxOrderDate,
    DATEDIFF(MAX(OrderDate), MIN(OrderDate))                  AS TotalDaysSpan
FROM fact_orders;

SELECT
    OrderID,
    OrderDate,
    ShipDate,
    DATEDIFF(ShipDate, OrderDate)                             AS DaysToShip
FROM fact_orders
ORDER BY OrderDate;

-- -----------------------------------------------------------------------------
-- Employee Age and Tenure Exploration
-- Age derived from BirthDate using DATEDIFF in years.
-- Tenure approximated as years since birth date threshold (proxy for workforce age).
-- -----------------------------------------------------------------------------
SELECT
    EmployeeID,
    FullName,
    Department,
    BirthDate,
    Age,
    DATEDIFF(CURDATE(), BirthDate)                            AS DaysSinceBirth,
    ROUND(DATEDIFF(CURDATE(), BirthDate) / 365.25, 1)         AS AgeInYears
FROM dim_employees
ORDER BY Age DESC;

-- Average age by department — baseline for workforce demographics
SELECT
    Department,
    COUNT(*)                                                  AS EmployeeCount,
    ROUND(AVG(Age), 1)                                        AS AvgAge,
    MIN(Age)                                                  AS MinAge,
    MAX(Age)                                                  AS MaxAge
FROM dim_employees
GROUP BY Department
ORDER BY AvgAge DESC;

-- Order volume by year — temporal distribution baseline
SELECT
    OrderYear,
    COUNT(DISTINCT OrderID)                                   AS TotalOrders,
    MIN(OrderDate)                                            AS FirstOrderInYear,
    MAX(OrderDate)                                            AS LastOrderInYear
FROM fact_orders
GROUP BY OrderYear
ORDER BY OrderYear;
