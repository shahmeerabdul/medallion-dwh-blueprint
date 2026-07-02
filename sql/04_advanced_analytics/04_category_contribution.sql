-- =============================================================================
-- 04_category_contribution.sql
-- Purpose: Part-to-whole analysis — category share of total sales (%).
-- Layer:   Gold (fact_orders, dim_products)
-- Technique: CTE for category totals; window SUM() for grand total denominator.
-- Formula: (Category Sales / Total Sales) * 100
-- SOC:     Business analytics only — no ETL logic.
-- =============================================================================

USE medallion_dw;

WITH category_sales AS (
    -- Step 1: aggregate sales and quantity at product category level
    SELECT
        p.Category,
        SUM(f.Sales)                                            AS CategorySales,
        SUM(f.Quantity)                                         AS CategoryQuantity,
        COUNT(DISTINCT f.OrderID)                               AS CategoryOrders
    FROM fact_orders f
    JOIN dim_products p ON f.ProductID = p.ProductID
    GROUP BY p.Category
),

total_sales AS (
    -- Step 2: compute grand total once for consistent denominator
    SELECT SUM(CategorySales) AS GrandTotalSales
    FROM category_sales
)

SELECT
    cs.Category,
    cs.CategorySales,
    cs.CategoryQuantity,
    cs.CategoryOrders,
    ts.GrandTotalSales,
    -- Part-to-whole percentage: each category's share of total revenue
    ROUND((cs.CategorySales / ts.GrandTotalSales) * 100, 2)     AS SalesContributionPct,
    -- Window function alternative: SUM() OVER() as inline grand total
    ROUND(
        (cs.CategorySales / SUM(cs.CategorySales) OVER ()) * 100,
        2
    )                                                         AS SalesContributionPct_Window
FROM category_sales cs
CROSS JOIN total_sales ts
ORDER BY SalesContributionPct DESC;

-- -----------------------------------------------------------------------------
-- Product-level contribution within each category (nested part-to-whole)
-- -----------------------------------------------------------------------------
WITH product_sales AS (
    SELECT
        p.Category,
        p.Product,
        SUM(f.Sales)                                            AS ProductSales
    FROM fact_orders f
    JOIN dim_products p ON f.ProductID = p.ProductID
    GROUP BY p.Category, p.Product
)
SELECT
    Category,
    Product,
    ProductSales,
    -- Denominator partitioned by Category: share within category, not global
    SUM(ProductSales) OVER (PARTITION BY Category)              AS CategoryTotalSales,
    ROUND(
        (ProductSales / SUM(ProductSales) OVER (PARTITION BY Category)) * 100,
        2
    )                                                         AS PctOfCategorySales
FROM product_sales
ORDER BY Category, PctOfCategorySales DESC;
