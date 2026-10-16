# SaaS Customer Churn & Revenue Analysis

## Project Overview

This project analyzes a B2B SaaS company's customer, subscription, billing, and product usage data. The main goal is to understand how the company can grow recurring revenue while reducing customer churn.

The analysis uses PostgreSQL to study revenue, customer cancellations, subscription plans, churn trends, retention, payment problems, acquisition channels, and product usage.

The project also includes advanced analysis such as Monthly Recurring Revenue (MRR), Annual Recurring Revenue (ARR), cohort retention, revenue at risk, and high-value churn segments.

## Business Questions

This project answers the following business questions:

1. Which subscription plans generate the most paid invoice value?
2. Which industries, countries, and company sizes generate the most revenue?
3. Which acquisition channels bring the most valuable customers?
4. Which plans have the highest payment failure risk?
5. What are the main reasons customers cancel their subscriptions?
6. Which customer segments have the highest ended-subscription rates?
7. How is Monthly Recurring Revenue (MRR) changing over time?
8. How is the monthly churn rate changing over time?
9. How well are customer cohorts retained after 3, 6, and 12 months?
10. Which plans have the highest revenue at risk from ended subscriptions?
11. Which customer segments have the highest-value churn?
12. How does product usage compare between active and ended customers?

## Dataset

The project uses a B2B SaaS subscription dataset with six main tables:

- `plans` – information about subscription plans, pricing, tiers, and billing type
- `organizations` – company information such as industry, country, company size, and acquisition channel
- `users` – users connected to each organization
- `subscriptions` – subscription history, plan, seats, start date, end date, and cancellation reason
- `invoices` – billing records, payment status, invoice amount, and payment dates
- `usage_events` – product usage activities such as reports, dashboard views, exports, API calls, and integrations

The dataset contains:

- 3,000 organizations
- 26,000 users
- 4,200 subscriptions
- 46,000 invoices
- 180,000 usage events
- 8 subscription plans


## Tools Used

- **PostgreSQL** – used to store and analyze the SaaS data
- **DBeaver** – used to run SQL queries and export results
- **Python** – used to convert Parquet files into CSV files
- **DuckDB** – used inside the Python conversion process
- **Excel** – used to create charts and visuals
- **VS Code** – used to organize SQL files, documentation, and project files
- **GitHub** – used to store the project and track changes


## Data Quality Checks

Before starting the main analysis, I checked the dataset for common data quality problems.

The checks included:

- Duplicate primary keys
- Missing required values
- Invalid dates
- Invalid numeric values
- Foreign key problems
- Blank text values
- Duplicate business records
- Subscription and cancellation consistency
- Invoice duplication
- Payment status and payment date consistency
- Usage events happening before organization signup or user join dates

Some data issues were found, including invalid subscription dates, repeated invoice records, and usage events that happened before valid signup or join dates.

For the final analysis, I kept the raw data unchanged and handled these problems inside the SQL queries. Exact duplicate invoices were removed from revenue analysis, invalid date records were excluded when needed, and invalid usage events were not used in time-based product usage analysis.


## Key Findings

- Monthly Recurring Revenue (MRR) grew from about $237 in January 2023 to a peak of about $887,800 in November 2025.

- MRR dropped slightly to about $874,305 in December 2025, which may show that churn started to affect growth.

- Monthly churn increased near the end of 2025 and reached 11.53% in December 2025.

- Enterprise was the highest-value plan, with about $6.27 million in paid invoice value.

- Price was the biggest cancellation reason at 27.21%, followed by missing features at 23.70%.

- Enterprise also had the highest monthly recurring revenue at risk from ended subscriptions, at about $425,456.

- Organic was the strongest acquisition channel, producing about $4.19 million in paid invoice value.

- Media had the highest ended-subscription rate at about 59.54%.

- Cohort retention was different between signup groups, showing that some customer groups stayed longer than others.

- Payment failure rates were low compared with overall churn, so customer retention is a bigger business problem than payment failure.


## Business Recommendations

- Focus more on keeping Enterprise and Business customers because they bring the most revenue.

- Review pricing because price was the top cancellation reason.

- Improve important product features because missing features was the second biggest reason customers canceled.

- Watch monthly churn more closely, especially when the rate starts increasing.

- Give more attention to industries with higher churn, especially media and nonprofit customers.

- Continue investing in organic acquisition because it produced the highest paid invoice value.

- Study partner customers more because they had a strong average paid value.

- Use customer usage, subscription history, and cancellation data together to find customers who may be at risk.

- Improve onboarding and customer support so new customers can understand the product better and stay longer.

- Build a simple churn-risk system in the future to help the company contact high-risk customers before they cancel.


## Visualizations

### 1. Monthly Recurring Revenue (MRR) Trend

![Monthly Recurring Revenue Trend](visuals/monthly_mrr_trend.png)

MRR increased strongly over time and reached its highest point in November 2025.

### 2. Monthly Subscription Churn Rate

![Monthly Subscription Churn Rate](visuals/monthly_churn_rate.png)

The churn rate increased near the end of 2025 and reached 11.53% in December.

### 3. Paid Invoice Value by Plan

![Paid Invoice Value by Plan](visuals/paid_invoice_value_by_plan.png)

Enterprise generated the highest paid invoice value among all subscription plans.

### 4. Subscription Cancellations by Reason

![Subscription Cancellations by Reason](visuals/cancellation_reasons.png)

Price was the biggest cancellation reason, followed by missing features.

### 5. Monthly Recurring Revenue at Risk by Plan

![Revenue at Risk by Plan](visuals/revenue_at_risk_by_plan.png)

Enterprise had the highest amount of recurring revenue at risk from ended subscriptions.

### 6. Paid Invoice Value by Acquisition Channel

![Paid Invoice Value by Acquisition Channel](visuals/paid_value_by_acquisition_channel.png)

Organic was the strongest acquisition channel based on paid invoice value.

### 7. Ended-Subscription Rate by Industry

![Ended Subscription Rate by Industry](visuals/ended_rate_by_industry.png)

Media had the highest ended-subscription rate among the industries.

### 8. Cohort Retention

![Cohort Retention](visuals/cohort_retention.png)

Retention was different between customer signup groups at 3, 6, and 12 months.


## Project Structure

```text
saas_customer_churn_project/
├── data/
│   ├── plans.parquet
│   ├── organizations.parquet
│   ├── users.parquet
│   ├── subscriptions.parquet
│   ├── invoices.parquet
│   └── usage_events.parquet
├── sql/
│   ├── 01_data_setup.sql
│   ├── 02_data_quality.sql
│   ├── 03_exploratory_analysis.sql
│   ├── 04_business_analysis.sql
│   └── 05_advanced_retention_analysis.sql
├── visuals/
│   ├── monthly_mrr_trend.png
│   ├── monthly_churn_rate.png
│   ├── paid_invoice_value_by_plan.png
│   ├── cancellation_reasons.png
│   ├── revenue_at_risk_by_plan.png
│   ├── paid_value_by_acquisition_channel.png
│   ├── ended_rate_by_industry.png
│   └── cohort_retention.png
├── docs/
│   ├── saas_subscriptions.schema.sql
│   └── 05_business_insights.md
├── scripts/
│   └── convert_parquet_to_csv.py
├── .gitignore
├── .gitattributes
└── README.md


## Conclusion

This project helped me understand how a SaaS company can use data to improve revenue and reduce customer churn.

The analysis showed that the company had strong MRR growth, but churn became higher near the end of 2025. Enterprise and Business plans were very important because they produced a large part of the revenue. Price and missing features were the biggest cancellation reasons, and some industries had much higher churn than others.

Overall, the company should focus on keeping high-value customers, improving product value, watching churn trends, and using customer data to find problems early.

This project also helped me practice real business analysis using PostgreSQL, data cleaning, revenue analysis, churn analysis, cohort retention, and data visualization.

