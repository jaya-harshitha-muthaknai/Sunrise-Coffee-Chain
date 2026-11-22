CREATE DATABASE sunrise_coffee_shop;
show DATABASES;
use sunrise_coffee_shop;
Show tables;
WITH store_cost AS (
  SELECT s.store_id, s.store_name,
         SUM(f.total_monthly_revenue_gbp)   AS rev,
         SUM(f.net_profit_gbp)              AS profit,
         SUM(f.total_monthly_cogs_gbp)      AS cogs,
         SUM(f.monthly_staffing_cost_gbp)   AS staff,
         SUM(f.monthly_rent_gbp)            AS rent,
         SUM(f.net_profit_gbp < 0)          AS loss_months,
         COUNT(*)                           AS months
  FROM fact_store_monthly_profitability_reviewed f
  JOIN dim_store_reviewed s ON s.store_id = f.store_id
  GROUP BY s.store_id, s.store_name
),
ratios AS (
  SELECT *, profit/rev AS margin, cogs/rev AS cogs_pct,
         staff/rev AS staff_pct, rent/rev AS rent_pct,
         AVG(cogs/rev)  OVER () AS avg_cogs,
         AVG(staff/rev) OVER () AS avg_staff,
         AVG(rent/rev)  OVER () AS avg_rent
  FROM store_cost
)
SELECT RANK() OVER (ORDER BY margin) AS worst_rank,
       store_name,
       ROUND(margin*100,1)                 AS margin_pct,
       ROUND(loss_months/months*100,1)     AS pct_months_in_loss,
       ROUND(cogs_pct*100,1)  AS cogs_pct,
       ROUND(staff_pct*100,1) AS staff_pct,
       ROUND(rent_pct*100,1)  AS rent_pct,
       CASE
         WHEN staff_pct-avg_staff >= GREATEST(rent_pct-avg_rent, cogs_pct-avg_cogs) THEN 'Staffing'
         WHEN rent_pct-avg_rent   >= cogs_pct-avg_cogs THEN 'Rent'
         ELSE 'COGS'
       END AS main_driver
FROM ratios
ORDER BY margin
LIMIT 10;

SELECT f.rent_band, s.location_type,
       COUNT(*) AS store_months,
       ROUND(SUM(f.net_profit_gbp)/SUM(f.total_monthly_revenue_gbp)*100,1) AS margin_pct,
       ROUND(SUM(f.monthly_rent_gbp)/SUM(f.total_monthly_revenue_gbp)*100,1) AS rent_pct_of_rev,
       ROUND(AVG(f.revenue_per_sqft_gbp),1) AS rev_per_sqft
FROM fact_store_monthly_profitability_reviewed f
JOIN dim_store_reviewed s ON s.store_id = f.store_id
GROUP BY f.rent_band, s.location_type
ORDER BY FIELD(f.rent_band,'Low','Medium','High'), margin_pct DESC;


-- Part 1: Productivity by shift pattern
SELECT shift_pattern,
       COUNT(*) AS day_records,
       ROUND(SUM(total_revenue_gbp)/SUM(total_staff_hours),1)   AS rev_per_staff_hour,
       ROUND(SUM(total_transactions)/SUM(total_staff_hours),1)  AS txns_per_staff_hour,
       ROUND(SUM(footfall)/SUM(total_staff_hours),1)            AS visitors_per_staff_hour
FROM fact_daily_sales_reviewed
GROUP BY shift_pattern
ORDER BY rev_per_staff_hour DESC;

-- Part 2: Stores with lowest revenue per staff hour
WITH st AS (
  SELECT d.store_id, s.store_name,
         SUM(d.total_revenue_gbp)/SUM(d.total_staff_hours) AS rev_per_hour
  FROM fact_daily_sales_reviewed d
  JOIN dim_store_reviewed s ON s.store_id = d.store_id
  GROUP BY d.store_id, s.store_name
)
SELECT store_name, ROUND(rev_per_hour,1) AS rev_per_staff_hour,
       ROUND(AVG(rev_per_hour) OVER (),1) AS network_avg,
       CASE WHEN rev_per_hour < 0.85*AVG(rev_per_hour) OVER () THEN 'Overstaffed?' ELSE 'OK' END AS flag
FROM st
ORDER BY rev_per_hour
LIMIT 10;


WITH q AS (
  SELECT store_id, loyalty_adoption_rate,
         NTILE(4) OVER (ORDER BY loyalty_adoption_rate) AS adoption_quartile
  FROM dim_store_reviewed
)
SELECT q.adoption_quartile,
       COUNT(DISTINCT q.store_id) AS stores,
       ROUND(AVG(q.loyalty_adoption_rate)*100,1) AS avg_adoption_pct,
       ROUND(SUM(f.net_profit_gbp)/SUM(f.total_monthly_revenue_gbp)*100,1) AS margin_pct,
       ROUND(SUM(f.loyalty_redemption_cost_gbp)/SUM(f.loyalty_member_spend_gbp)*100,1) AS redemption_cost_per_100_member_spend,
       ROUND(AVG(f.loyalty_member_revenue_pct),1) AS avg_member_revenue_pct
FROM q
JOIN fact_store_monthly_profitability_reviewed f ON f.store_id = q.store_id
GROUP BY q.adoption_quartile
ORDER BY q.adoption_quartile;

SELECT dt.year, dt.month_number,
       ROUND(SUM(d.espresso_revenue_gbp)) AS espresso,
       ROUND(SUM(d.filter_revenue_gbp))   AS filter_coffee,
       ROUND(SUM(d.food_revenue_gbp))     AS food,
       ROUND(SUM(d.retail_beans_revenue_gbp)) AS retail_beans
FROM fact_daily_sales_reviewed d
JOIN dim_date_cleaned dt ON dt.date_id = d.date_id
GROUP BY dt.year, dt.month_number
ORDER BY dt.year, dt.month_number;


SELECT CASE WHEN s.opening_year <= 2016 THEN '1: 2010-2016 (mature)'
            WHEN s.opening_year <= 2020 THEN '2: 2017-2020'
            ELSE '3: 2021-2023 (new)' END AS cohort,
       LEFT(f.month_id,4) AS yr,
       COUNT(DISTINCT s.store_id) AS stores,
       ROUND(SUM(f.net_profit_gbp)/SUM(f.total_monthly_revenue_gbp)*100,1) AS margin_pct,
       ROUND(AVG(f.total_monthly_revenue_gbp)) AS avg_monthly_rev
FROM fact_store_monthly_profitability_reviewed f
JOIN dim_store_reviewed s ON s.store_id = f.store_id
GROUP BY cohort, yr
ORDER BY cohort, yr;