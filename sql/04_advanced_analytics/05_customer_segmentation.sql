-- =============================================================================
-- 05_customer_segmentation.sql
-- Purpose: Data segmentation — classify customers by Score into value tiers.
-- Layer:   Gold (dim_customers, fact_orders)
-- Technique: CASE WHEN for tier assignment; CTEs for segment-level KPIs.
-- SOC:     Business analytics only — no ETL logic.
-- =============================================================================

USE medallion_dw;

-- -----------------------------------------------------------------------------
-- Customer Segmentation Overview
-- Uses CASE WHEN to re-derive segments (mirrors Gold ETL logic for validation).
-- CustomerValueSegment column is also available pre-computed in dim_customers.
-- -----------------------------------------------------------------------------
WITH customer_segments AS (
    SELECT
        CustomerID,
        FullName,
        Country,
        Score,
        CustomerValueSegment,
        CASE
            WHEN Score >= 80 THEN 'High'
            WHEN Score >= 50 THEN 'Medium'
            ELSE 'Low'
        END                                                     AS ComputedSegment
    FROM dim_customers
)
SELECT
    ComputedSegment                                           AS ValueSegment,
    COUNT(*)                                                  AS CustomerCount,
    ROUND(AVG(Score), 1)                                      AS AvgScore,
    MIN(Score)                                                AS MinScore,
    MAX(Score)                                                AS MaxScore
FROM customer_segments
GROUP BY ComputedSegment
ORDER BY FIELD(ComputedSegment, 'High', 'Medium', 'Low');

-- -----------------------------------------------------------------------------
-- Segment Revenue Analysis
-- Joins segmented customers to fact orders for revenue by tier.
-- -----------------------------------------------------------------------------
WITH customer_segments AS (
    SELECT
        CustomerID,
        FullName,
        Country,
        Score,
        CustomerValueSegment
    FROM dim_customers
),

segment_orders AS (
    SELECT
        cs.CustomerValueSegment,
        cs.CustomerID,
        cs.FullName,
        cs.Score,
        f.OrderID,
        f.Sales
    FROM customer_segments cs
    LEFT JOIN fact_orders f ON cs.CustomerID = f.CustomerID
)

SELECT
    CustomerValueSegment,
    COUNT(DISTINCT CustomerID)                                AS CustomerCount,
    COUNT(DISTINCT OrderID)                                   AS TotalOrders,
    COALESCE(SUM(Sales), 0)                                   AS TotalSales,
    ROUND(COALESCE(SUM(Sales), 0) / COUNT(DISTINCT CustomerID), 2)
                                                              AS AvgSalesPerCustomer
FROM segment_orders
GROUP BY CustomerValueSegment
ORDER BY FIELD(CustomerValueSegment, 'High', 'Medium', 'Low');

-- -----------------------------------------------------------------------------
-- Detailed Customer List with Segment Labels
-- RANK() window function ranks customers by Score within each segment.
-- -----------------------------------------------------------------------------
WITH ranked_customers AS (
    SELECT
        CustomerID,
        FullName,
        Country,
        Score,
        CustomerValueSegment,
        RANK() OVER (
            PARTITION BY CustomerValueSegment
            ORDER BY Score DESC
        )                                                     AS RankWithinSegment
    FROM dim_customers
)
SELECT
    CustomerValueSegment,
    RankWithinSegment,
    CustomerID,
    FullName,
    Country,
    Score
FROM ranked_customers
ORDER BY CustomerValueSegment, RankWithinSegment;
