# Medallion Data Warehouse : SQL Analytics Project

An end-to-end SQL Data Warehousing and Analytics project implementing the **Medallion Architecture** (Bronze → Silver → Gold) with strict **Separation of Concerns (SOC)**:

| Layer / Folder | Responsibility |
|---|---|
| `datasets/` | Raw source CSV files |
| `sql/01_ddl/` | Table definitions only (no data logic) |
| `sql/02_etl/` | Data loading and transformation only |
| `sql/03_eda/` | Exploratory analysis (read-only, Gold layer) |
| `sql/04_advanced_analytics/` | Business reporting (read-only, Gold layer) |

---

## Project Structure

```
Systems/
├── datasets/
│   ├── Customers.csv
│   ├── Employees.csv
│   ├── Orders.csv
│   ├── OrdersArchive.csv
│   └── Products.csv
├── sql/
│   ├── 01_ddl/
│   │   ├── 00_create_database.sql
│   │   ├── 01_bronze_ddl.sql
│   │   ├── 02_silver_ddl.sql
│   │   └── 03_gold_ddl.sql
│   ├── 02_etl/
│   │   ├── 01_bronze_load.sql          ← portable INSERT-based load
│   │   ├── 01_bronze_load_infile.sql   ← alternative LOAD DATA INFILE
│   │   ├── 02_silver_etl.sql
│   │   └── 03_gold_etl.sql
│   ├── 03_eda/
│   │   ├── 01_date_exploration.sql
│   │   ├── 02_measures_exploration.sql
│   │   └── 03_magnitude_analysis.sql
│   └── 04_advanced_analytics/
│       ├── 01_sales_trends.sql
│       ├── 02_cumulative_analysis.sql
│       ├── 03_salesperson_performance.sql
│       ├── 04_category_contribution.sql
│       └── 05_customer_segmentation.sql
└── README.md
```

---

## Database Schema

**Database name:** `medallion_dw`

### Bronze Layer (Raw Landing)

All columns stored as `VARCHAR` to preserve source fidelity. No cleansing applied.

| Table | Source CSV |
|---|---|
| `bronze_customers` | Customers.csv |
| `bronze_employees` | Employees.csv |
| `bronze_products` | Products.csv |
| `bronze_orders` | Orders.csv |
| `bronze_orders_archive` | OrdersArchive.csv |

### Silver Layer (Cleaned & Typed)

| Table | Primary Key | Cleansing Applied |
|---|---|---|
| `silver_customers` | CustomerID | NULL/empty Score → 0 |
| `silver_employees` | EmployeeID | Empty ManagerID → NULL; dates cast |
| `silver_products` | ProductID | Numeric price cast |
| `silver_orders` | OrderID | Unified current + archive orders |

### Gold Layer (Star Schema)

| Object | Type | Description |
|---|---|---|
| `dim_customers` | Dimension | Customer attributes + `CustomerValueSegment` (High/Medium/Low) |
| `dim_employees` | Dimension | Employee attributes + computed `Age`; self-referencing FK on ManagerID |
| `dim_products` | Dimension | Product catalog |
| `fact_orders` | Fact | Order line items with denormalized `OrderYear`/`OrderMonth` |
| `vw_monthly_sales_summary` | View | Pre-aggregated monthly sales |

**Foreign Keys (Gold):**

- `fact_orders.CustomerID` → `dim_customers.CustomerID`
- `fact_orders.ProductID` → `dim_products.ProductID`
- `fact_orders.SalesPersonID` → `dim_employees.EmployeeID`
- `dim_employees.ManagerID` → `dim_employees.EmployeeID`

---

## Execution Order

Run scripts in this exact sequence from a MySQL client (`mysql`, MySQL Workbench, DBeaver, etc.):

### Step 1 : DDL (create schema)

```bash
mysql -u root -p < sql/01_ddl/00_create_database.sql
mysql -u root -p < sql/01_ddl/01_bronze_ddl.sql
mysql -u root -p < sql/01_ddl/02_silver_ddl.sql
mysql -u root -p < sql/01_ddl/03_gold_ddl.sql
```

### Step 2 : ETL (load and transform data)

```bash
# Option A: INSERT-based load (recommended — no FILE privilege needed)
mysql -u root -p < sql/02_etl/01_bronze_load.sql
mysql -u root -p < sql/02_etl/02_silver_etl.sql
mysql -u root -p < sql/02_etl/03_gold_etl.sql

# Option B: LOAD DATA INFILE (update @dataset_path in script first)
mysql -u root -p --local-infile=1 < sql/02_etl/01_bronze_load_infile.sql
mysql -u root -p < sql/02_etl/02_silver_etl.sql
mysql -u root -p < sql/02_etl/03_gold_etl.sql
```

### Step 3 : EDA (exploratory analysis)

```bash
mysql -u root -p < sql/03_eda/01_date_exploration.sql
mysql -u root -p < sql/03_eda/02_measures_exploration.sql
mysql -u root -p < sql/03_eda/03_magnitude_analysis.sql
```

### Step 4 : Advanced Analytics (business reporting)

```bash
mysql -u root -p < sql/04_advanced_analytics/01_sales_trends.sql
mysql -u root -p < sql/04_advanced_analytics/02_cumulative_analysis.sql
mysql -u root -p < sql/04_advanced_analytics/03_salesperson_performance.sql
mysql -u root -p < sql/04_advanced_analytics/04_category_contribution.sql
mysql -u root -p < sql/04_advanced_analytics/05_customer_segmentation.sql
```

---

## ETL Strategy

All ETL scripts use a **Full Load (Truncate & Insert)** pattern:

1. **Bronze Load** — ingest raw CSV data as-is into VARCHAR columns.
2. **Silver ETL** — truncate Silver tables, transform and cast Bronze data, union orders + archive.
3. **Gold ETL** — truncate Gold tables, populate star schema with business rules:
   - Customer segmentation: High (Score ≥ 80), Medium (50–79), Low (< 50)
   - Employee age computed via `TIMESTAMPDIFF`
   - Order year/month denormalized onto fact table

Re-run Steps 2a–2c anytime to refresh the warehouse from source data.

---

## Analytics Overview

### EDA (`sql/03_eda/`)

| Script | Focus |
|---|---|
| `01_date_exploration.sql` | Order date ranges, shipping lag (`DATEDIFF`), employee ages |
| `02_measures_exploration.sql` | Total sales, avg price, quantity KPIs |
| `03_magnitude_analysis.sql` | Sales by country, avg salary by department |

### Advanced Analytics (`sql/04_advanced_analytics/`)

| Script | Technique | Business Question |
|---|---|---|
| `01_sales_trends.sql` | CTEs | Sales by year and month |
| `02_cumulative_analysis.sql` | `SUM() OVER`, `AVG() OVER` | Running totals and 3-month moving average |
| `03_salesperson_performance.sql` | `LAG()`, `LEAD()` | YoY sales comparison per salesperson |
| `04_category_contribution.sql` | CTEs + window `SUM()` | Category % of total sales |
| `05_customer_segmentation.sql` | `CASE WHEN`, `RANK()` | High/Medium/Low customer value tiers |

---

## Requirements

- **MySQL 8.0+** (window functions, CTEs)
- MySQL client with access to create databases and tables
- For `LOAD DATA INFILE`: `FILE` privilege and `--local-infile=1` flag

---

## Data Notes

- **15 rows** per CSV file with realistic, referentially consistent mock data.
- `Customers.csv` row 13 (Mark White) has an intentionally empty `Score` to demonstrate Bronze→Silver NULL cleansing.
- `Employees.csv` rows 1, 5, 8 have empty `ManagerID` (top-level managers).
- `OrdersArchive.csv` contains orders from 2022–2023; `Orders.csv` contains 2024–2025 orders.
- All order foreign keys (CustomerID, ProductID, SalesPersonID) reference valid dimension records.

---

## Dashboard (Streamlit)

A simple Python analytics UI lives in `/dashboard/`:

```bash
cd dashboard
pip install -r requirements.txt
streamlit run app.py
```

- **Live mode:** connects to MySQL Gold layer after running the ETL pipeline
- **Demo mode:** auto-falls back to CSV datasets if MySQL is unavailable

See `dashboard/README.md` for details.
