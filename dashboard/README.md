# Medallion DW — Streamlit Dashboard

Simple Python analytics dashboard for the Gold layer. Reads from **MySQL** when available, otherwise falls back to **CSV demo mode** automatically.

## Quick Start

```bash
cd dashboard
pip install -r requirements.txt
streamlit run app.py
```

Open **http://localhost:8501** in your browser.

## Pages

| Page | Charts |
|---|---|
| **Overview** | KPI cards, category pie, country bar, monthly area chart |
| **Trends** | Monthly line chart, 3-month moving average, running total by year |
| **Sales Team** | YoY salesperson table, heatmap, salary by department |
| **Customers** | Segment bar/scatter, country treemap |
| **Products** | Top 10 products, category share % |

## Data Sources

### Live MySQL (recommended)

1. Run the SQL pipeline from the project root (see main `README.md`)
2. Copy `.env.example` to `.env` and set your credentials
3. Restart the dashboard

The app queries Gold tables only: `fact_orders`, `dim_customers`, `dim_employees`, `dim_products`.

### CSV Demo Mode

If MySQL is unavailable, the dashboard loads `../datasets/*.csv` and computes the same metrics in pandas. No setup required.

Force demo mode: `USE_CSV=1 streamlit run app.py`

## Architecture (SOC)

```
datasets/  →  sql/02_etl/  →  Gold (MySQL)  →  dashboard/ (read-only)
```

The dashboard never runs ETL — it only reads analytics-ready data.

## Project Files

| File | Purpose |
|---|---|
| `app.py` | Streamlit UI and charts |
| `data_loader.py` | MySQL + CSV data access |
| `queries.py` | Gold-layer SQL (mirrors `/sql/03_eda` and `/sql/04_advanced_analytics`) |
| `config.py` | Connection settings |
