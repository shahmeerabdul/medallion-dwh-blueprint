-- =============================================================================
-- 03_gold_etl.sql
-- Purpose: Silver → Gold full load (Truncate & Insert).
-- Method:  Full Load — rebuild star schema from cleansed Silver tables.
-- Business logic applied:
--   • CustomerValueSegment: High (Score >= 80), Medium (50-79), Low (< 50)
--   • Employee Age: computed from BirthDate relative to current date
--   • OrderYear/OrderMonth: denormalized date keys for analytics performance
-- =============================================================================

USE medallion_dw;

-- Disable FK checks to allow truncate/reload of interdependent Gold tables
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE fact_orders;
TRUNCATE TABLE dim_customers;
TRUNCATE TABLE dim_employees;
TRUNCATE TABLE dim_products;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- Gold Dimension: Customers
-- =============================================================================
INSERT INTO dim_customers (
    CustomerID, FirstName, LastName, FullName, Country, Score, CustomerValueSegment
)
SELECT
    CustomerID,
    FirstName,
    LastName,
    CONCAT(FirstName, ' ', LastName)                          AS FullName,
    Country,
    Score,
    -- Segment customers by Score for downstream segmentation analytics
    CASE
        WHEN Score >= 80 THEN 'High'
        WHEN Score >= 50 THEN 'Medium'
        ELSE 'Low'
    END                                                       AS CustomerValueSegment
FROM silver_customers;

-- =============================================================================
-- Gold Dimension: Employees
-- Load all employees in one pass; self-referencing FK allows NULL ManagerID
-- =============================================================================
INSERT INTO dim_employees (
    EmployeeID, FirstName, LastName, FullName, Department,
    BirthDate, Age, Gender, Salary, ManagerID
)
SELECT
    EmployeeID,
    FirstName,
    LastName,
    CONCAT(FirstName, ' ', LastName)                          AS FullName,
    Department,
    BirthDate,
    TIMESTAMPDIFF(YEAR, BirthDate, CURDATE())                 AS Age,
    Gender,
    Salary,
    ManagerID
FROM silver_employees;

-- =============================================================================
-- Gold Dimension: Products
-- =============================================================================
INSERT INTO dim_products (ProductID, Product, Category, Price)
SELECT
    ProductID,
    Product,
    Category,
    Price
FROM silver_products;

-- =============================================================================
-- Gold Fact: Orders
-- =============================================================================
INSERT INTO fact_orders (
    OrderID, ProductID, CustomerID, SalesPersonID,
    OrderDate, OrderYear, OrderMonth,
    ShipDate, OrderStatus, ShipAddress, BillAddress,
    Quantity, Sales, CreationTime, SourceSystem
)
SELECT
    OrderID,
    ProductID,
    CustomerID,
    SalesPersonID,
    OrderDate,
    YEAR(OrderDate)                                           AS OrderYear,
    MONTH(OrderDate)                                          AS OrderMonth,
    ShipDate,
    OrderStatus,
    ShipAddress,
    BillAddress,
    Quantity,
    Sales,
    CreationTime,
    SourceSystem
FROM silver_orders;
