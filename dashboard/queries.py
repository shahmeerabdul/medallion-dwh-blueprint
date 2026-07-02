"""Gold-layer SQL queries — read-only analytics (SOC: no ETL logic)."""

KPI_OVERVIEW = """
SELECT
    ROUND(SUM(Sales), 2)              AS total_sales,
    SUM(Quantity)                     AS total_quantity,
    COUNT(DISTINCT OrderID)           AS total_orders,
    COUNT(DISTINCT CustomerID)        AS unique_customers
FROM fact_orders
"""

MONTHLY_SALES_TREND = """
SELECT
    OrderYear,
    OrderMonth,
    CONCAT(OrderYear, '-', LPAD(OrderMonth, 2, '0')) AS year_month,
    ROUND(SUM(Sales), 2)              AS total_sales,
    COUNT(DISTINCT OrderID)           AS order_count
FROM fact_orders
GROUP BY OrderYear, OrderMonth
ORDER BY OrderYear, OrderMonth
"""

CATEGORY_CONTRIBUTION = """
SELECT
    p.Category,
    ROUND(SUM(f.Sales), 2)            AS category_sales,
    SUM(f.Quantity)                   AS category_quantity
FROM fact_orders f
JOIN dim_products p ON f.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY category_sales DESC
"""

SALES_BY_COUNTRY = """
SELECT
    c.Country,
    ROUND(SUM(f.Sales), 2)            AS total_sales,
    COUNT(DISTINCT f.OrderID)         AS order_count
FROM fact_orders f
JOIN dim_customers c ON f.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY total_sales DESC
"""

CUSTOMER_SEGMENTS = """
SELECT
    CustomerValueSegment              AS segment,
    COUNT(*)                          AS customer_count,
    ROUND(AVG(Score), 1)              AS avg_score
FROM dim_customers
GROUP BY CustomerValueSegment
ORDER BY FIELD(segment, 'High', 'Medium', 'Low')
"""

SALESPERSON_YOY = """
WITH salesperson_yearly AS (
    SELECT
        e.EmployeeID,
        e.FullName                      AS sales_person,
        f.OrderYear,
        ROUND(SUM(f.Sales), 2)          AS yearly_sales
    FROM fact_orders f
    JOIN dim_employees e ON f.SalesPersonID = e.EmployeeID
    WHERE e.Department = 'Sales'
    GROUP BY e.EmployeeID, e.FullName, f.OrderYear
)
SELECT
    sales_person,
    OrderYear,
    yearly_sales,
    LAG(yearly_sales) OVER (
        PARTITION BY EmployeeID ORDER BY OrderYear
    )                                 AS previous_year_sales
FROM salesperson_yearly
ORDER BY sales_person, OrderYear
"""

CUMULATIVE_MONTHLY = """
WITH monthly AS (
    SELECT
        OrderYear,
        OrderMonth,
        CONCAT(OrderYear, '-', LPAD(OrderMonth, 2, '0')) AS year_month,
        ROUND(SUM(Sales), 2)            AS monthly_sales
    FROM fact_orders
    GROUP BY OrderYear, OrderMonth
)
SELECT
    OrderYear,
    OrderMonth,
    year_month,
    monthly_sales,
    SUM(monthly_sales) OVER (
        PARTITION BY OrderYear
        ORDER BY OrderMonth
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                 AS running_total
FROM monthly
ORDER BY OrderYear, OrderMonth
"""

SALARY_BY_DEPARTMENT = """
SELECT
    Department,
    COUNT(*)                          AS headcount,
    ROUND(AVG(Salary), 2)             AS avg_salary
FROM dim_employees
GROUP BY Department
ORDER BY avg_salary DESC
"""

TOP_PRODUCTS = """
SELECT
    p.Product,
    p.Category,
    SUM(f.Quantity)                   AS units_sold,
    ROUND(SUM(f.Sales), 2)            AS total_sales
FROM fact_orders f
JOIN dim_products p ON f.ProductID = p.ProductID
GROUP BY p.Product, p.Category
ORDER BY total_sales DESC
LIMIT 10
"""
