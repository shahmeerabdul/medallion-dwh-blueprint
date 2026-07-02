"""Data access layer — MySQL Gold layer with CSV fallback."""

from __future__ import annotations

import pandas as pd

import config
import queries


_db_checked: bool = False
_db_available: bool = False


def _try_mysql() -> bool:
    """Return True if MySQL is reachable and Gold tables exist."""
    if config.FORCE_CSV:
        return False
    try:
        import mysql.connector

        conn = mysql.connector.connect(
            host=config.DB_HOST,
            port=config.DB_PORT,
            user=config.DB_USER,
            password=config.DB_PASSWORD,
            database=config.DB_NAME,
            connection_timeout=3,
        )
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM fact_orders LIMIT 1")
        cursor.fetchone()
        cursor.close()
        conn.close()
        return True
    except Exception:
        return False


def _run_mysql_query(sql: str) -> pd.DataFrame:
    import mysql.connector

    conn = mysql.connector.connect(
        host=config.DB_HOST,
        port=config.DB_PORT,
        user=config.DB_USER,
        password=config.DB_PASSWORD,
        database=config.DB_NAME,
    )
    try:
        return pd.read_sql(sql, conn)
    finally:
        conn.close()


def _load_csv_frames() -> dict[str, pd.DataFrame]:
    """Load raw CSVs and build Gold-equivalent frames in memory."""
    customers = pd.read_csv(config.DATASETS_DIR / "Customers.csv")
    employees = pd.read_csv(config.DATASETS_DIR / "Employees.csv")
    products = pd.read_csv(config.DATASETS_DIR / "Products.csv")
    orders = pd.read_csv(config.DATASETS_DIR / "Orders.csv")
    archive = pd.read_csv(config.DATASETS_DIR / "OrdersArchive.csv")

    orders["SourceSystem"] = "ORDERS"
    archive["SourceSystem"] = "ARCHIVE"
    all_orders = pd.concat([orders, archive], ignore_index=True)

    for col in ["OrderDate", "ShipDate"]:
        all_orders[col] = pd.to_datetime(all_orders[col])
    all_orders["CreationTime"] = pd.to_datetime(all_orders["CreationTime"])
    all_orders["OrderYear"] = all_orders["OrderDate"].dt.year
    all_orders["OrderMonth"] = all_orders["OrderDate"].dt.month

    customers["Score"] = pd.to_numeric(customers["Score"], errors="coerce").fillna(0).astype(int)

    def segment(score: int) -> str:
        if score >= 80:
            return "High"
        if score >= 50:
            return "Medium"
        return "Low"

    customers["CustomerValueSegment"] = customers["Score"].apply(segment)
    customers["FullName"] = customers["FirstName"] + " " + customers["LastName"]

    employees["BirthDate"] = pd.to_datetime(employees["BirthDate"])
    employees["FullName"] = employees["FirstName"] + " " + employees["LastName"]
    employees["Age"] = ((pd.Timestamp.today() - employees["BirthDate"]).dt.days / 365.25).astype(int)

    return {
        "customers": customers,
        "employees": employees,
        "products": products,
        "orders": all_orders,
    }


def get_data_source_label() -> str:
    return "MySQL (Gold Layer)" if is_live_db() else "CSV Demo Mode"


def is_live_db() -> bool:
    global _db_checked, _db_available
    if not _db_checked:
        _db_available = _try_mysql()
        _db_checked = True
    return _db_available


# ---------------------------------------------------------------------------
# Public query functions
# ---------------------------------------------------------------------------

def get_kpi_overview() -> dict:
    if is_live_db():
        row = _run_mysql_query(queries.KPI_OVERVIEW).iloc[0]
        return row.to_dict()
    frames = _load_csv_frames()
    orders = frames["orders"]
    return {
        "total_sales": round(orders["Sales"].sum(), 2),
        "total_quantity": int(orders["Quantity"].sum()),
        "total_orders": orders["OrderID"].nunique(),
        "unique_customers": orders["CustomerID"].nunique(),
    }


def get_monthly_sales() -> pd.DataFrame:
    if is_live_db():
        return _run_mysql_query(queries.MONTHLY_SALES_TREND)
    orders = _load_csv_frames()["orders"]
    df = (
        orders.groupby(["OrderYear", "OrderMonth"], as_index=False)
        .agg(total_sales=("Sales", "sum"), order_count=("OrderID", "nunique"))
        .sort_values(["OrderYear", "OrderMonth"])
    )
    df["year_month"] = df["OrderYear"].astype(str) + "-" + df["OrderMonth"].astype(str).str.zfill(2)
    df["total_sales"] = df["total_sales"].round(2)
    return df


def get_category_contribution() -> pd.DataFrame:
    if is_live_db():
        return _run_mysql_query(queries.CATEGORY_CONTRIBUTION)
    frames = _load_csv_frames()
    merged = frames["orders"].merge(frames["products"], on="ProductID")
    df = (
        merged.groupby("Category", as_index=False)
        .agg(category_sales=("Sales", "sum"), category_quantity=("Quantity", "sum"))
        .sort_values("category_sales", ascending=False)
    )
    df["category_sales"] = df["category_sales"].round(2)
    return df


def get_sales_by_country() -> pd.DataFrame:
    if is_live_db():
        return _run_mysql_query(queries.SALES_BY_COUNTRY)
    frames = _load_csv_frames()
    merged = frames["orders"].merge(frames["customers"], on="CustomerID")
    df = (
        merged.groupby("Country", as_index=False)
        .agg(total_sales=("Sales", "sum"), order_count=("OrderID", "nunique"))
        .sort_values("total_sales", ascending=False)
    )
    df["total_sales"] = df["total_sales"].round(2)
    return df


def get_customer_segments() -> pd.DataFrame:
    if is_live_db():
        return _run_mysql_query(queries.CUSTOMER_SEGMENTS)
    customers = _load_csv_frames()["customers"]
    df = (
        customers.groupby("CustomerValueSegment", as_index=False)
        .agg(customer_count=("CustomerID", "count"), avg_score=("Score", "mean"))
        .rename(columns={"CustomerValueSegment": "segment"})
    )
    df["avg_score"] = df["avg_score"].round(1)
    order = {"High": 0, "Medium": 1, "Low": 2}
    df["_sort"] = df["segment"].map(order)
    return df.sort_values("_sort").drop(columns="_sort")


def get_salesperson_yoy() -> pd.DataFrame:
    if is_live_db():
        return _run_mysql_query(queries.SALESPERSON_YOY)
    frames = _load_csv_frames()
    sales_reps = frames["employees"][frames["employees"]["Department"] == "Sales"]
    merged = frames["orders"].merge(
        sales_reps[["EmployeeID", "FullName"]],
        left_on="SalesPersonID",
        right_on="EmployeeID",
    )
    yearly = (
        merged.groupby(["EmployeeID", "FullName", "OrderYear"], as_index=False)
        .agg(yearly_sales=("Sales", "sum"))
        .rename(columns={"FullName": "sales_person"})
        .sort_values(["EmployeeID", "OrderYear"])
    )
    yearly["yearly_sales"] = yearly["yearly_sales"].round(2)
    yearly["previous_year_sales"] = yearly.groupby("EmployeeID")["yearly_sales"].shift(1)
    return yearly[["sales_person", "OrderYear", "yearly_sales", "previous_year_sales"]]


def get_cumulative_monthly() -> pd.DataFrame:
    if is_live_db():
        return _run_mysql_query(queries.CUMULATIVE_MONTHLY)
    monthly = get_monthly_sales()
    monthly["running_total"] = monthly.groupby("OrderYear")["total_sales"].cumsum().round(2)
    return monthly.rename(columns={"total_sales": "monthly_sales"})


def get_salary_by_department() -> pd.DataFrame:
    if is_live_db():
        return _run_mysql_query(queries.SALARY_BY_DEPARTMENT)
    employees = _load_csv_frames()["employees"]
    df = (
        employees.groupby("Department", as_index=False)
        .agg(headcount=("EmployeeID", "count"), avg_salary=("Salary", "mean"))
        .sort_values("avg_salary", ascending=False)
    )
    df["avg_salary"] = df["avg_salary"].round(2)
    return df


def get_top_products() -> pd.DataFrame:
    if is_live_db():
        return _run_mysql_query(queries.TOP_PRODUCTS)
    frames = _load_csv_frames()
    merged = frames["orders"].merge(frames["products"], on="ProductID")
    df = (
        merged.groupby(["Product", "Category"], as_index=False)
        .agg(units_sold=("Quantity", "sum"), total_sales=("Sales", "sum"))
        .sort_values("total_sales", ascending=False)
        .head(10)
    )
    df["total_sales"] = df["total_sales"].round(2)
    return df
