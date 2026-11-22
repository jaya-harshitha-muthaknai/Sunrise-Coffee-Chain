# Sunrise Coffee Chain: Store Profitability, Loyalty & Revenue Mix Analysis

Data Cleaning & EDA | Python · Pandas · Seaborn | SQL | MySQL 8

## Project Overview

This project analyses the 2023-2024 trading performance of Sunrise Coffee Chain, a business with 60 coffee stores across the UK, using store, product, date, daily sales and monthly profitability data.

The analysis focuses on store profitability, rent and staffing costs, the loyalty programme, revenue mix and seasonality. The business questions come from the commercial team's need to decide where to expand in 2025, whether to keep funding loyalty, and how to plan staff and stock.

The objective is to find which stores lose money and why, and to test what the EDA suggested using SQL.

## Dataset

- Source: Sunrise Coffee Chain case dataset (synthetic), supplied with the project brief ([docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md))
- Reporting period: January 2023 to December 2024
- Stores: 60 across the UK
- Currency: GBP

| Table | Rows | Grain |
|---|---|---|
| dim_store | 60 | One row per store |
| dim_product | 40 | One row per product |
| dim_date | 730 | One row per day |
| fact_daily_sales | 10,000 | Store x day (a sample, about 7-8 days per store-month) |
| fact_store_monthly_profitability | 1,440 | 60 stores x 24 months |

## Tools & Technologies

- Python: data cleaning and analysis
- Pandas: aggregation, merging and validation
- Matplotlib & Seaborn: visualisations
- Jupyter Notebook: documented analysis
- MySQL 8: CTEs, window functions (RANK, NTILE, AVG OVER) and conditional aggregation

## Methodology

### 1. Data Cleaning
- Checked data types, missing values and duplicates on all five tables.
- Validated keys between fact and dimension tables.
- Checked value ranges, such as rent, staffing cost, loyalty adoption and opening year.
- Saved reviewed tables to `cleaned_data/`.

### 2. Exploratory Data Analysis
- Merged tables with `validate=` and compared row counts before and after each join.
- Built a monthly key to link daily sales to monthly profit.
- Ranked stores by profit and counted profitability status.
- Calculated COGS, staffing and rent as a share of revenue.
- Compared margin by rent band, location type, store opening year and month across years.
- Checked loyalty adoption, footfall and staff hours.

### 3. SQL Analysis
Seven queries in [sql/02_business_questions.sql](sql/02_business_questions.sql) covering unprofitable stores, rent against location, staffing productivity, loyalty adoption, revenue mix, seasonal products and store cohorts.

Every margin is calculated as `SUM(net_profit) / SUM(revenue)`, not as an average of monthly percentages, so small-revenue months do not distort the result.

## Key Findings

### Store Profitability

| Metric | Result |
|---|---|
| Store-months analysed | 1,440 |
| Loss-making store-months | 147 |
| Structural-loss store-months | 17 |
| COGS share of revenue | 32% to 44% in every store |

Worst stores by margin:

| Store | Margin | Months in loss | Main driver |
|---|---|---|---|
| South London Corner | -3.7% | 54.2% | Staffing (51.7% of revenue) |
| Canary Wharf Express | 3.2% | 54.2% | Rent (21.8% of revenue) |
| Manchester Collective | 4.9% | 33.3% | Staffing (46.5%) |
| North London Yard | 5.1% | 29.2% | Rent (20.4%) |
| Canary Wharf Quarter | 8.7% | 33.3% | Rent (19.8%) |

Five of the ten worst stores are driven by staffing and five by rent. COGS never explains a weak store.

### Rent and Location

In City-Centre stores, margin falls as rent rises:

| Rent band | Margin | Rent as % of revenue | Revenue per sq ft |
|---|---|---|---|
| Low | 19.7% | 6.8% | £57.7 |
| Medium | 14.7% | 12.0% | £53.2 |
| High | 10.6% | 19.6% | £47.2 |

High-rent stores also earn less per square foot, so the extra rent is not paid back. High-rent shopping-centre and suburban rows have only 1 and 2 store-months, so they are not reliable.

### Staffing

- Revenue per staff hour is close across stores: the lowest is £45.1 against a network average of £49.4.
- No store fell below an 85% cutoff of the average.
- Average footfall is almost the same across shift patterns (about 365 to 375 customers a day).
- The cost problem at South London Corner is its monthly staffing bill against revenue, not hours worked per sale.

### Loyalty Programme

| Adoption quartile | Average adoption | Margin | Redemption cost per £100 member spend |
|---|---|---|---|
| 1 (lowest) | 10.6% | 17.8% | £18.4 |
| 2 | 27.5% | 21.8% | £7.1 |
| 3 | 41.9% | 17.6% | £4.6 |
| 4 (highest) | 53.0% | 18.1% | £3.6 |

Margin stays near 18% from the lowest to the highest adoption group. The store-level scatter plot of adoption against margin shows no pattern either.

### Revenue Mix

| Share of sampled receipt revenue | 2023 | 2024 |
|---|---|---|
| Espresso | 45.8% | 45.6% |
| Filter coffee | 19.0% | 19.3% |
| Food | 26.2% | 25.9% |
| Retail beans | 8.9% | 9.2% |

- Food share did not grow. Retail beans edged up.
- Sampled receipts were 1.6% lower in 2024 (£10.15m against £10.31m).
- Espresso peaks in May to July and November, and is weakest in February and April.
- Days tagged with a seasonal product averaged £2,041 against £2,046 for active products, so seasonal items did not lift daily revenue.

### Store Cohorts

| Opening cohort | Stores | 2023 margin | 2024 margin |
|---|---|---|---|
| 2010-2016 | 26 | 17.5% | 17.4% |
| 2017-2020 | 17 | 19.4% | 19.0% |
| 2021-2023 | 17 | 20.3% | 20.8% |

The newest stores have the highest margin and it is rising, so there is no sign of a ramp-up loss.

## Conclusion

The analysis suggests that profit problems in this chain sit in a small number of stores, and that their causes differ: staffing in some, rent in others. High rent lowers margin even within the same location type, while loyalty adoption and seasonal products show no measurable effect on profit or daily revenue.

Recommendations:
1. Review the ten worst stores, starting with South London Corner (staffing) and Canary Wharf Express (rent).
2. Renegotiate high-rent city-centre leases at renewal.
3. Test loyalty redemption cost against extra spend before expanding the scheme.
4. Plan stock and rotas around the May to July and November peaks.
5. Continue opening stores, as recent cohorts match or beat older ones.

## Data Quality Notes

- 34 store, date and product combinations appear more than once in daily sales.
- 249 daily rows are dated before their product's launch date.
- Daily sales is a sample, so its revenue (about £15k per store-month) is far below monthly revenue (£43k to £85k). The two are never mixed.
- Each daily row has one product ID but the whole day's revenue, so product rankings are unreliable. Category revenue columns were used instead.

## Limitations

- Staffing, mix and product results come from a sample, so they show direction, not exact figures.
- Two years of data only, so seasonality rests on two repeats.
- The data is synthetic, so findings are not claims about a real business.
- Only opening year is available, so cohorts are compared, not months since opening.
- Region comparison, weekday against weekend, bank holidays and loyalty net value per store are not covered yet.
- Correlations are descriptive and do not establish causation.

## Repository Structure

```
├── README.md
├── requirements.txt
├── notebooks/
│   ├── 01_data_cleaning.ipynb
│   └── 02_EDA.ipynb
├── sql/
│   └── 02_business_questions.sql
├── cleaned_data/

```

## How to Reproduce

1. Put the source CSV files in a `data/` folder.
2. Run `01_data_cleaning.ipynb`, then `02_EDA.ipynb`.
3. In MySQL, run `sql/01_setup_tables.sql` to create the `sunrise_coffee_shop` database and import the cleaned CSVs.
4. Run `sql/02_business_questions.sql`.

## Author

Jaya Harshitha Muthakani | Aspiring Data / Business Analyst | Vijayawada, India
LinkedIn: www.linkedin.com/in/jaya-harshitha-muthakani
