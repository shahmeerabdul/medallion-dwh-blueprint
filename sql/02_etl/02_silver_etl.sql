-- =============================================================================
-- 02_silver_etl.sql
-- Purpose: Bronze → Silver full load (Truncate & Insert).
-- Method:  Full Load — truncate Silver tables and reload from Bronze each run.
-- Cleansing rules applied:
--   • Customer Score: NULL/empty → 0
--   • Employee ManagerID: empty string → NULL (preserves org hierarchy intent)
--   • Dates: CAST to DATE/DATETIME with STR_TO_DATE
--   • Numeric fields: CAST to INT/DECIMAL
--   • Orders: union current + archive with SourceSystem tag
-- =============================================================================

USE medallion_dw;

-- =============================================================================
-- Silver: Customers
-- =============================================================================
TRUNCATE TABLE silver_customers;

INSERT INTO silver_customers (CustomerID, FirstName, LastName, Country, Score)
SELECT
    CAST(CustomerID AS UNSIGNED)                              AS CustomerID,
    TRIM(FirstName)                                           AS FirstName,
    TRIM(LastName)                                            AS LastName,
    TRIM(Country)                                             AS Country,
    -- Cleanse NULL/empty Score values to 0 for downstream segmentation logic
    COALESCE(NULLIF(TRIM(Score), ''), 0)                      AS Score
FROM bronze_customers;

-- =============================================================================
-- Silver: Employees
-- =============================================================================
TRUNCATE TABLE silver_employees;

INSERT INTO silver_employees (EmployeeID, FirstName, LastName, Department, BirthDate, Gender, Salary, ManagerID)
SELECT
    CAST(EmployeeID AS UNSIGNED)                              AS EmployeeID,
    TRIM(FirstName)                                           AS FirstName,
    TRIM(LastName)                                            AS LastName,
    TRIM(Department)                                          AS Department,
    STR_TO_DATE(BirthDate, '%Y-%m-%d')                        AS BirthDate,
    UPPER(TRIM(Gender))                                       AS Gender,
    CAST(Salary AS DECIMAL(12,2))                             AS Salary,
    -- Cleanse empty ManagerID to NULL for top-level managers
    NULLIF(CAST(NULLIF(TRIM(ManagerID), '') AS UNSIGNED), 0) AS ManagerID
FROM bronze_employees;

-- =============================================================================
-- Silver: Products
-- =============================================================================
TRUNCATE TABLE silver_products;

INSERT INTO silver_products (ProductID, Product, Category, Price)
SELECT
    CAST(ProductID AS UNSIGNED)                               AS ProductID,
    TRIM(Product)                                             AS Product,
    TRIM(Category)                                            AS Category,
    CAST(Price AS DECIMAL(12,2))                              AS Price
FROM bronze_products;

-- =============================================================================
-- Silver: Orders (unified from current + archive)
-- =============================================================================
TRUNCATE TABLE silver_orders;

INSERT INTO silver_orders (
    OrderID, ProductID, CustomerID, SalesPersonID,
    OrderDate, ShipDate, OrderStatus, ShipAddress, BillAddress,
    Quantity, Sales, CreationTime, SourceSystem
)
SELECT
    CAST(OrderID AS UNSIGNED)                                 AS OrderID,
    CAST(ProductID AS UNSIGNED)                               AS ProductID,
    CAST(CustomerID AS UNSIGNED)                              AS CustomerID,
    CAST(SalesPersonID AS UNSIGNED)                           AS SalesPersonID,
    STR_TO_DATE(OrderDate, '%Y-%m-%d')                        AS OrderDate,
    STR_TO_DATE(NULLIF(TRIM(ShipDate), ''), '%Y-%m-%d')       AS ShipDate,
    TRIM(OrderStatus)                                         AS OrderStatus,
    TRIM(ShipAddress)                                         AS ShipAddress,
    TRIM(BillAddress)                                         AS BillAddress,
    CAST(Quantity AS UNSIGNED)                                AS Quantity,
    CAST(Sales AS DECIMAL(12,2))                              AS Sales,
    STR_TO_DATE(CreationTime, '%Y-%m-%d %H:%i:%s')            AS CreationTime,
    'ORDERS'                                                  AS SourceSystem
FROM bronze_orders

UNION ALL

SELECT
    CAST(OrderID AS UNSIGNED)                                 AS OrderID,
    CAST(ProductID AS UNSIGNED)                               AS ProductID,
    CAST(CustomerID AS UNSIGNED)                              AS CustomerID,
    CAST(SalesPersonID AS UNSIGNED)                           AS SalesPersonID,
    STR_TO_DATE(OrderDate, '%Y-%m-%d')                        AS OrderDate,
    STR_TO_DATE(NULLIF(TRIM(ShipDate), ''), '%Y-%m-%d')       AS ShipDate,
    TRIM(OrderStatus)                                         AS OrderStatus,
    TRIM(ShipAddress)                                         AS ShipAddress,
    TRIM(BillAddress)                                         AS BillAddress,
    CAST(Quantity AS UNSIGNED)                                AS Quantity,
    CAST(Sales AS DECIMAL(12,2))                              AS Sales,
    STR_TO_DATE(CreationTime, '%Y-%m-%d %H:%i:%s')            AS CreationTime,
    'ARCHIVE'                                                 AS SourceSystem
FROM bronze_orders_archive;
