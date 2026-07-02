-- =============================================================================
-- 03_gold_ddl.sql
-- Purpose: Gold layer DDL — business-ready star schema (dimensions + fact).
-- Design: Conformed dimensions with surrogate-free natural keys.
--         Foreign keys enforce referential integrity for analytics consumers.
-- =============================================================================

USE medallion_dw;

-- -----------------------------------------------------------------------------
-- Gold Dimension: Customers
-- Includes customer_value_segment populated during ETL for segmentation analysis
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_customers;
CREATE TABLE dim_customers (
    CustomerID            INT          NOT NULL,
    FirstName             VARCHAR(100) NOT NULL,
    LastName              VARCHAR(100) NOT NULL,
    FullName              VARCHAR(201) NOT NULL,
    Country               VARCHAR(100) NOT NULL,
    Score                 INT          NOT NULL,
    CustomerValueSegment  VARCHAR(10)  NOT NULL COMMENT 'High, Medium, or Low',
    loaded_at             TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (CustomerID)
);

-- -----------------------------------------------------------------------------
-- Gold Dimension: Employees
-- Includes computed Age column for EDA tenure/age exploration
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_employees;
CREATE TABLE dim_employees (
    EmployeeID   INT           NOT NULL,
    FirstName    VARCHAR(100)  NOT NULL,
    LastName     VARCHAR(100)  NOT NULL,
    FullName     VARCHAR(201)  NOT NULL,
    Department   VARCHAR(100)  NOT NULL,
    BirthDate    DATE          NOT NULL,
    Age          INT           NOT NULL,
    Gender       CHAR(1)       NOT NULL,
    Salary       DECIMAL(12,2) NOT NULL,
    ManagerID    INT           NULL,
    loaded_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (EmployeeID),
    CONSTRAINT fk_dim_employees_manager
        FOREIGN KEY (ManagerID) REFERENCES dim_employees (EmployeeID)
);

-- -----------------------------------------------------------------------------
-- Gold Dimension: Products
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS dim_products;
CREATE TABLE dim_products (
    ProductID    INT           NOT NULL,
    Product      VARCHAR(200)  NOT NULL,
    Category     VARCHAR(100)  NOT NULL,
    Price        DECIMAL(12,2) NOT NULL,
    loaded_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ProductID)
);

-- -----------------------------------------------------------------------------
-- Gold Fact: Orders
-- Grain: one row per order line (OrderID + ProductID)
-- Denormalized date keys for efficient time-based analytics
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS fact_orders;
CREATE TABLE fact_orders (
    OrderID        INT           NOT NULL,
    ProductID      INT           NOT NULL,
    CustomerID     INT           NOT NULL,
    SalesPersonID  INT           NOT NULL,
    OrderDate      DATE          NOT NULL,
    OrderYear      INT           NOT NULL,
    OrderMonth     INT           NOT NULL,
    ShipDate       DATE          NULL,
    OrderStatus    VARCHAR(50)   NOT NULL,
    ShipAddress    VARCHAR(500)  NOT NULL,
    BillAddress    VARCHAR(500)  NOT NULL,
    Quantity       INT           NOT NULL,
    Sales          DECIMAL(12,2) NOT NULL,
    CreationTime   DATETIME      NOT NULL,
    SourceSystem   VARCHAR(20)   NOT NULL,
    loaded_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (OrderID, ProductID),
    CONSTRAINT fk_fact_orders_customer
        FOREIGN KEY (CustomerID) REFERENCES dim_customers (CustomerID),
    CONSTRAINT fk_fact_orders_product
        FOREIGN KEY (ProductID) REFERENCES dim_products (ProductID),
    CONSTRAINT fk_fact_orders_salesperson
        FOREIGN KEY (SalesPersonID) REFERENCES dim_employees (EmployeeID)
);

-- -----------------------------------------------------------------------------
-- Gold View: Monthly Sales Summary (pre-aggregated for dashboard consumption)
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_monthly_sales_summary;
CREATE VIEW vw_monthly_sales_summary AS
SELECT
    OrderYear,
    OrderMonth,
    COUNT(DISTINCT OrderID)  AS TotalOrders,
    SUM(Quantity)            AS TotalQuantity,
    SUM(Sales)               AS TotalSales
FROM fact_orders
GROUP BY OrderYear, OrderMonth;
