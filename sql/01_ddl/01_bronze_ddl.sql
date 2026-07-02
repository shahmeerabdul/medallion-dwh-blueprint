-- =============================================================================
-- 01_bronze_ddl.sql
-- Purpose: Bronze layer DDL — raw, unprocessed landing tables mirroring CSVs.
-- Design: All columns stored as VARCHAR/TEXT to preserve source fidelity.
--         No cleansing, casting, or business rules applied at this layer.
-- =============================================================================

USE medallion_dw;

-- -----------------------------------------------------------------------------
-- Bronze: Customers (raw CSV landing)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS bronze_customers;
CREATE TABLE bronze_customers (
    CustomerID   VARCHAR(20),
    FirstName    VARCHAR(100),
    LastName     VARCHAR(100),
    Country      VARCHAR(100),
    Score        VARCHAR(20),
    loaded_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Bronze: Employees (raw CSV landing)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS bronze_employees;
CREATE TABLE bronze_employees (
    EmployeeID   VARCHAR(20),
    FirstName    VARCHAR(100),
    LastName     VARCHAR(100),
    Department   VARCHAR(100),
    BirthDate    VARCHAR(20),
    Gender       VARCHAR(10),
    Salary       VARCHAR(20),
    ManagerID    VARCHAR(20),
    loaded_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Bronze: Products (raw CSV landing)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS bronze_products;
CREATE TABLE bronze_products (
    ProductID    VARCHAR(20),
    Product      VARCHAR(200),
    Category     VARCHAR(100),
    Price        VARCHAR(20),
    loaded_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Bronze: Orders (raw CSV landing — current orders)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS bronze_orders;
CREATE TABLE bronze_orders (
    OrderID        VARCHAR(20),
    ProductID      VARCHAR(20),
    CustomerID     VARCHAR(20),
    SalesPersonID  VARCHAR(20),
    OrderDate      VARCHAR(20),
    ShipDate       VARCHAR(20),
    OrderStatus    VARCHAR(50),
    ShipAddress    VARCHAR(500),
    BillAddress    VARCHAR(500),
    Quantity       VARCHAR(20),
    Sales          VARCHAR(20),
    CreationTime   VARCHAR(30),
    loaded_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Bronze: Orders Archive (raw CSV landing — historical orders)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS bronze_orders_archive;
CREATE TABLE bronze_orders_archive (
    OrderID        VARCHAR(20),
    ProductID      VARCHAR(20),
    CustomerID     VARCHAR(20),
    SalesPersonID  VARCHAR(20),
    OrderDate      VARCHAR(20),
    ShipDate       VARCHAR(20),
    OrderStatus    VARCHAR(50),
    ShipAddress    VARCHAR(500),
    BillAddress    VARCHAR(500),
    Quantity       VARCHAR(20),
    Sales          VARCHAR(20),
    CreationTime   VARCHAR(30),
    loaded_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
