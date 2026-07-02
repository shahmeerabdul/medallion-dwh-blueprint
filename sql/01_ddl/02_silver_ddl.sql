-- =============================================================================
-- 02_silver_ddl.sql
-- Purpose: Silver layer DDL — clean, typed, standardized tables.
-- Design: Proper data types, NOT NULL where business-critical, PKs enforced.
--         Foreign keys deferred until Gold to allow independent ETL loads.
-- =============================================================================

USE medallion_dw;

-- -----------------------------------------------------------------------------
-- Silver: Customers
-- Score defaults to 0 when NULL in source (cleansing applied during ETL)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS silver_customers;
CREATE TABLE silver_customers (
    CustomerID   INT          NOT NULL,
    FirstName    VARCHAR(100) NOT NULL,
    LastName     VARCHAR(100) NOT NULL,
    Country      VARCHAR(100) NOT NULL,
    Score        INT          NOT NULL DEFAULT 0,
    loaded_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (CustomerID)
);

-- -----------------------------------------------------------------------------
-- Silver: Employees
-- ManagerID nullable for top-level managers (NULL preserved intentionally)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS silver_employees;
CREATE TABLE silver_employees (
    EmployeeID   INT          NOT NULL,
    FirstName    VARCHAR(100) NOT NULL,
    LastName     VARCHAR(100) NOT NULL,
    Department   VARCHAR(100) NOT NULL,
    BirthDate    DATE         NOT NULL,
    Gender       CHAR(1)      NOT NULL,
    Salary       DECIMAL(12,2) NOT NULL,
    ManagerID    INT          NULL,
    loaded_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (EmployeeID)
);

-- -----------------------------------------------------------------------------
-- Silver: Products
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS silver_products;
CREATE TABLE silver_products (
    ProductID    INT           NOT NULL,
    Product      VARCHAR(200)  NOT NULL,
    Category     VARCHAR(100)  NOT NULL,
    Price        DECIMAL(12,2) NOT NULL,
    loaded_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ProductID)
);

-- -----------------------------------------------------------------------------
-- Silver: Orders (unified current + archive)
-- Single table consolidates both order sources for downstream analytics
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS silver_orders;
CREATE TABLE silver_orders (
    OrderID        INT           NOT NULL,
    ProductID      INT           NOT NULL,
    CustomerID     INT           NOT NULL,
    SalesPersonID  INT           NOT NULL,
    OrderDate      DATE          NOT NULL,
    ShipDate       DATE          NULL,
    OrderStatus    VARCHAR(50)   NOT NULL,
    ShipAddress    VARCHAR(500)  NOT NULL,
    BillAddress    VARCHAR(500)  NOT NULL,
    Quantity       INT           NOT NULL,
    Sales          DECIMAL(12,2) NOT NULL,
    CreationTime   DATETIME      NOT NULL,
    SourceSystem   VARCHAR(20)   NOT NULL COMMENT 'ORDERS or ARCHIVE',
    loaded_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (OrderID)
);
