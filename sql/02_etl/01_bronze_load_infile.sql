-- =============================================================================
-- 01_bronze_load_infile.sql
-- Purpose: Alternative Bronze load using MySQL LOAD DATA INFILE (bulk CSV ingest).
-- Prerequisite: MySQL server must have FILE privilege and local_infile enabled.
--               Update @dataset_path to your absolute datasets directory path.
-- Windows example: SET @dataset_path = 'C:/Users/shahm/Desktop/Systems/datasets/';
-- Linux example:   SET @dataset_path = '/var/data/medallion_dw/datasets/';
-- =============================================================================

USE medallion_dw;

-- Enable local infile for this session (MySQL 8+)
SET GLOBAL local_infile = 1;

-- *** UPDATE THIS PATH to match your environment ***
SET @dataset_path = 'C:/Users/shahm/Desktop/Systems/datasets/';

-- Truncate Bronze tables before reload
TRUNCATE TABLE bronze_customers;
TRUNCATE TABLE bronze_employees;
TRUNCATE TABLE bronze_products;
TRUNCATE TABLE bronze_orders;
TRUNCATE TABLE bronze_orders_archive;

-- -----------------------------------------------------------------------------
-- Load: Customers.csv
-- IGNORE 1 LINES skips the header row
-- -----------------------------------------------------------------------------
SET @sql = CONCAT(
    'LOAD DATA LOCAL INFILE ''', @dataset_path, 'Customers.csv'' ',
    'INTO TABLE bronze_customers ',
    'FIELDS TERMINATED BY '','' ENCLOSED BY ''"'' ',
    'LINES TERMINATED BY ''\n'' ',
    'IGNORE 1 LINES ',
    '(CustomerID, FirstName, LastName, Country, Score)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- Load: Employees.csv
-- -----------------------------------------------------------------------------
SET @sql = CONCAT(
    'LOAD DATA LOCAL INFILE ''', @dataset_path, 'Employees.csv'' ',
    'INTO TABLE bronze_employees ',
    'FIELDS TERMINATED BY '','' ENCLOSED BY ''"'' ',
    'LINES TERMINATED BY ''\n'' ',
    'IGNORE 1 LINES ',
    '(EmployeeID, FirstName, LastName, Department, BirthDate, Gender, Salary, ManagerID)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- Load: Products.csv
-- -----------------------------------------------------------------------------
SET @sql = CONCAT(
    'LOAD DATA LOCAL INFILE ''', @dataset_path, 'Products.csv'' ',
    'INTO TABLE bronze_products ',
    'FIELDS TERMINATED BY '','' ENCLOSED BY ''"'' ',
    'LINES TERMINATED BY ''\n'' ',
    'IGNORE 1 LINES ',
    '(ProductID, Product, Category, Price)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- Load: Orders.csv
-- -----------------------------------------------------------------------------
SET @sql = CONCAT(
    'LOAD DATA LOCAL INFILE ''', @dataset_path, 'Orders.csv'' ',
    'INTO TABLE bronze_orders ',
    'FIELDS TERMINATED BY '','' ENCLOSED BY ''"'' ',
    'LINES TERMINATED BY ''\n'' ',
    'IGNORE 1 LINES ',
    '(OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, ',
    'OrderStatus, ShipAddress, BillAddress, Quantity, Sales, CreationTime)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- -----------------------------------------------------------------------------
-- Load: OrdersArchive.csv
-- -----------------------------------------------------------------------------
SET @sql = CONCAT(
    'LOAD DATA LOCAL INFILE ''', @dataset_path, 'OrdersArchive.csv'' ',
    'INTO TABLE bronze_orders_archive ',
    'FIELDS TERMINATED BY '','' ENCLOSED BY ''"'' ',
    'LINES TERMINATED BY ''\n'' ',
    'IGNORE 1 LINES ',
    '(OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, ',
    'OrderStatus, ShipAddress, BillAddress, Quantity, Sales, CreationTime)'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
