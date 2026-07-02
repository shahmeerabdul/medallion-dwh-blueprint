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

## Deploy (share a public link)

**Recommended: [Streamlit Community Cloud](https://share.streamlit.io)** — free, connects to your GitHub repo.

### Steps

1. Go to **[share.streamlit.io](https://share.streamlit.io)** and sign in with GitHub.
2. Click **Create app**.
3. Select repo: `shahmeerabdul/medallion-dwh-blueprint`
4. Set **Main file path** to:
   ```
   dashboard/app.py
   ```
5. Click **Deploy**.

Streamlit auto-detects `dashboard/requirements.txt`. No MySQL needed — the app falls back to your `/datasets/` CSVs on Cloud, so charts work immediately.

Your public URL will look like:
```
https://medallion-dwh-blueprint.streamlit.app
```
(exact subdomain depends on what you choose at deploy time)

### Optional: live MySQL on Cloud

Only needed if you want real Gold-layer data instead of CSVs:

1. Host MySQL somewhere (e.g. [PlanetScale](https://planetscale.com), [Railway](https://railway.app), or [Aiven](https://aiven.io)).
2. Run the SQL ETL pipeline against that database.
3. In Streamlit Cloud → **App settings → Secrets**, add:

```toml
DB_HOST = "your-host"
DB_PORT = 3306
DB_USER = "your-user"
DB_PASSWORD = "your-password"
DB_NAME = "medallion_dw"
```

### Other options

| Platform | Best for |
|---|---|
| [Hugging Face Spaces](https://huggingface.co/spaces) | Streamlit + portfolio visibility |
| [Render](https://render.com) | Always-on web service (free tier sleeps) |
| [Railway](https://railway.app) | App + MySQL in one place |

For a portfolio demo, **Streamlit Cloud + CSV mode** is the fastest path — one deploy, shareable link, zero database setup.
