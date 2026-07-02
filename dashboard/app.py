"""
Medallion DW Analytics Dashboard
Simple Streamlit UI — reads Gold layer (MySQL) or CSV fallback.
Run: streamlit run app.py
"""

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

import data_loader as dl

# ---------------------------------------------------------------------------
# Page config & styling
# ---------------------------------------------------------------------------
st.set_page_config(
    page_title="Medallion DW Analytics",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded",
)

st.markdown(
    """
    <style>
    .metric-card {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        padding: 1.2rem 1.5rem;
        border-radius: 12px;
        border: 1px solid #475569;
    }
    .metric-label { color: #94a3b8; font-size: 0.85rem; margin-bottom: 0.25rem; }
    .metric-value { color: #f8fafc; font-size: 1.75rem; font-weight: 700; }
    div[data-testid="stMetric"] {
        background: #1e293b;
        padding: 1rem 1.25rem;
        border-radius: 10px;
        border: 1px solid #334155;
    }
    div[data-testid="stMetric"] label,
    div[data-testid="stMetric"] label p,
    div[data-testid="stMetricLabel"] {
        color: #cbd5e1 !important;
    }
    div[data-testid="stMetric"] [data-testid="stMetricValue"],
    div[data-testid="stMetric"] [data-testid="stMetricValue"] > div,
    div[data-testid="stMetricValue"] {
        color: #ffffff !important;
    }
    div[data-testid="stMetric"] [data-testid="stMetricDelta"] {
        color: #94a3b8 !important;
    }
    </style>
    """,
    unsafe_allow_html=True,
)

PLOTLY_TEMPLATE = "plotly_dark"
COLORS = px.colors.qualitative.Set2


def fmt_currency(value: float) -> str:
    return f"${value:,.2f}"


# ---------------------------------------------------------------------------
# Sidebar
# ---------------------------------------------------------------------------
st.sidebar.title("Medallion DW")
st.sidebar.caption("Gold Layer Analytics")

source = dl.get_data_source_label()
if dl.is_live_db():
    st.sidebar.success(f"Connected: {source}")
else:
    st.sidebar.warning(f"Demo mode: {source}")
    st.sidebar.info("Set DB credentials in `.env` or run the SQL ETL pipeline to use live MySQL.")

page = st.sidebar.radio(
    "Navigation",
    ["Overview", "Trends", "Sales Team", "Customers", "Products"],
    label_visibility="collapsed",
)

st.sidebar.divider()
st.sidebar.markdown("**Architecture**")
st.sidebar.markdown("Bronze → Silver → Gold")
st.sidebar.markdown("UI reads Gold only (SOC)")


# ---------------------------------------------------------------------------
# Overview
# ---------------------------------------------------------------------------
if page == "Overview":
    st.title("Overview")
    st.markdown("Key business metrics from the Gold layer.")

    kpis = dl.get_kpi_overview()
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Sales", fmt_currency(kpis["total_sales"]))
    c2.metric("Total Orders", f"{kpis['total_orders']:,}")
    c3.metric("Units Sold", f"{kpis['total_quantity']:,}")
    c4.metric("Unique Customers", f"{kpis['unique_customers']:,}")

    st.divider()

    col_left, col_right = st.columns(2)

    with col_left:
        st.subheader("Sales by Category")
        cat_df = dl.get_category_contribution()
        cat_df["pct"] = (cat_df["category_sales"] / cat_df["category_sales"].sum() * 100).round(1)
        fig = px.pie(
            cat_df,
            names="Category",
            values="category_sales",
            hole=0.45,
            color_discrete_sequence=COLORS,
            template=PLOTLY_TEMPLATE,
        )
        fig.update_traces(textposition="inside", textinfo="percent+label")
        fig.update_layout(margin=dict(t=20, b=20, l=20, r=20), height=380, showlegend=False)
        st.plotly_chart(fig, use_container_width=True)

    with col_right:
        st.subheader("Sales by Country")
        country_df = dl.get_sales_by_country()
        fig = px.bar(
            country_df,
            x="Country",
            y="total_sales",
            color="Country",
            color_discrete_sequence=COLORS,
            template=PLOTLY_TEMPLATE,
        )
        fig.update_layout(
            xaxis_title="",
            yaxis_title="Sales ($)",
            margin=dict(t=20, b=20),
            height=380,
            showlegend=False,
        )
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("Monthly Sales Trend")
    monthly = dl.get_monthly_sales()
    fig = px.area(
        monthly,
        x="year_month",
        y="total_sales",
        template=PLOTLY_TEMPLATE,
        color_discrete_sequence=["#38bdf8"],
    )
    fig.update_layout(xaxis_title="Month", yaxis_title="Sales ($)", height=350, margin=dict(t=20))
    st.plotly_chart(fig, use_container_width=True)


# ---------------------------------------------------------------------------
# Trends
# ---------------------------------------------------------------------------
elif page == "Trends":
    st.title("Sales Trends")
    st.markdown("Change-over-time and cumulative analysis.")

    monthly = dl.get_monthly_sales()
    cumulative = dl.get_cumulative_monthly()

    tab1, tab2 = st.tabs(["Monthly Trend", "Running Total by Year"])

    with tab1:
        fig = px.line(
            monthly,
            x="year_month",
            y="total_sales",
            markers=True,
            template=PLOTLY_TEMPLATE,
            color_discrete_sequence=["#34d399"],
        )
        fig.update_layout(xaxis_title="Month", yaxis_title="Sales ($)", height=400)
        st.plotly_chart(fig, use_container_width=True)

        # 3-month moving average
        monthly_copy = monthly.copy()
        monthly_copy["moving_avg_3m"] = monthly_copy["total_sales"].rolling(window=3, min_periods=1).mean().round(2)
        fig2 = go.Figure()
        fig2.add_trace(go.Bar(x=monthly_copy["year_month"], y=monthly_copy["total_sales"], name="Monthly Sales", marker_color="#64748b"))
        fig2.add_trace(go.Scatter(x=monthly_copy["year_month"], y=monthly_copy["moving_avg_3m"], name="3-Mo Moving Avg", line=dict(color="#fbbf24", width=3)))
        fig2.update_layout(template=PLOTLY_TEMPLATE, xaxis_title="Month", yaxis_title="Sales ($)", height=400)
        st.plotly_chart(fig2, use_container_width=True)

    with tab2:
        years = sorted(cumulative["OrderYear"].unique())
        selected_year = st.selectbox("Select Year", years)
        year_data = cumulative[cumulative["OrderYear"] == selected_year]
        fig = px.bar(
            year_data,
            x="year_month",
            y="running_total",
            template=PLOTLY_TEMPLATE,
            color_discrete_sequence=["#818cf8"],
            title=f"Running Total Sales — {selected_year}",
        )
        fig.update_layout(xaxis_title="Month", yaxis_title="Cumulative Sales ($)", height=400)
        st.plotly_chart(fig, use_container_width=True)


# ---------------------------------------------------------------------------
# Sales Team
# ---------------------------------------------------------------------------
elif page == "Sales Team":
    st.title("Sales Team Performance")
    st.markdown("Year-over-year comparison using LAG window logic.")

    yoy = dl.get_salesperson_yoy()
    salary = dl.get_salary_by_department()

    col1, col2 = st.columns([2, 1])

    with col1:
        st.subheader("Salesperson Year-over-Year")
        display = yoy.copy()
        display["YoY Change %"] = display.apply(
            lambda r: round((r["yearly_sales"] - r["previous_year_sales"]) / r["previous_year_sales"] * 100, 1)
            if pd.notna(r["previous_year_sales"]) and r["previous_year_sales"] > 0
            else None,
            axis=1,
        )
        st.dataframe(
            display.rename(columns={
                "sales_person": "Sales Person",
                "OrderYear": "Year",
                "yearly_sales": "Current Sales",
                "previous_year_sales": "Previous Year Sales",
            }),
            use_container_width=True,
            hide_index=True,
        )

        pivot = yoy.pivot(index="sales_person", columns="OrderYear", values="yearly_sales").fillna(0)
        fig = px.imshow(
            pivot.values,
            x=[str(c) for c in pivot.columns],
            y=pivot.index.tolist(),
            color_continuous_scale="Blues",
            template=PLOTLY_TEMPLATE,
            aspect="auto",
        )
        fig.update_layout(title="Sales Heatmap by Rep & Year", height=350)
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("Avg Salary by Dept")
        fig = px.bar(
            salary,
            x="avg_salary",
            y="Department",
            orientation="h",
            template=PLOTLY_TEMPLATE,
            color_discrete_sequence=["#f472b6"],
        )
        fig.update_layout(xaxis_title="Avg Salary ($)", yaxis_title="", height=350)
        st.plotly_chart(fig, use_container_width=True)


# ---------------------------------------------------------------------------
# Customers
# ---------------------------------------------------------------------------
elif page == "Customers":
    st.title("Customer Segmentation")
    st.markdown("High / Medium / Low value tiers based on Score.")

    segments = dl.get_customer_segments()
    country = dl.get_sales_by_country()

    c1, c2 = st.columns(2)

    with c1:
        fig = px.bar(
            segments,
            x="segment",
            y="customer_count",
            color="segment",
            color_discrete_map={"High": "#34d399", "Medium": "#fbbf24", "Low": "#f87171"},
            template=PLOTLY_TEMPLATE,
            text="customer_count",
        )
        fig.update_layout(xaxis_title="Segment", yaxis_title="Customers", showlegend=False, height=350)
        st.plotly_chart(fig, use_container_width=True)

    with c2:
        fig = px.scatter(
            segments,
            x="segment",
            y="avg_score",
            size="customer_count",
            color="segment",
            color_discrete_map={"High": "#34d399", "Medium": "#fbbf24", "Low": "#f87171"},
            template=PLOTLY_TEMPLATE,
            size_max=40,
        )
        fig.update_layout(xaxis_title="Segment", yaxis_title="Avg Score", height=350)
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("Revenue by Country")
    fig = px.treemap(
        country,
        path=["Country"],
        values="total_sales",
        template=PLOTLY_TEMPLATE,
        color="total_sales",
        color_continuous_scale="Teal",
    )
    fig.update_layout(height=400, margin=dict(t=20))
    st.plotly_chart(fig, use_container_width=True)


# ---------------------------------------------------------------------------
# Products
# ---------------------------------------------------------------------------
elif page == "Products":
    st.title("Product Analytics")
    st.markdown("Top products and category contribution.")

    top = dl.get_top_products()
    cat = dl.get_category_contribution()

    c1, c2 = st.columns(2)

    with c1:
        st.subheader("Top 10 Products by Revenue")
        fig = px.bar(
            top,
            x="total_sales",
            y="Product",
            orientation="h",
            color="Category",
            color_discrete_sequence=COLORS,
            template=PLOTLY_TEMPLATE,
        )
        fig.update_layout(xaxis_title="Sales ($)", yaxis_title="", height=450, yaxis={"categoryorder": "total ascending"})
        st.plotly_chart(fig, use_container_width=True)

    with c2:
        st.subheader("Category Share (%)")
        cat["pct"] = (cat["category_sales"] / cat["category_sales"].sum() * 100).round(1)
        fig = px.bar(
            cat,
            x="Category",
            y="pct",
            color="Category",
            color_discrete_sequence=COLORS,
            template=PLOTLY_TEMPLATE,
            text="pct",
        )
        fig.update_traces(texttemplate="%{text}%", textposition="outside")
        fig.update_layout(xaxis_title="", yaxis_title="Share of Total Sales (%)", showlegend=False, height=450)
        st.plotly_chart(fig, use_container_width=True)

    st.subheader("Product Detail")
    st.dataframe(top, use_container_width=True, hide_index=True)
