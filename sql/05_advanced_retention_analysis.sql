-- ============================================
-- PROJECT 2: SAAS CUSTOMER CHURN & REVENUE ANALYSIS
-- FILE: 05_advanced_retention_analysis.sql
-- PURPOSE: ANALYZE RECURRING REVENUE, CHURN,
--          RETENTION, CUSTOMER LIFETIME,
--          REVENUE RISK, AND PRODUCT USAGE
-- ============================================



-- ============================================
-- 1. MONTHLY RECURRING REVENUE (MRR)
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        s.subscription_id,
        s.started_on,
        s.ended_on,
        s.seats,
        p.plan_name,
        p.monthly_price,
        p.seat_price,
 (
            p.monthly_price +
            (p.seat_price * s.seats)
        ) AS subscription_mrr
    FROM subscriptions s
    JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE s.ended_on IS NULL
       OR s.ended_on >= s.started_on
),
months AS (
    SELECT
        GENERATE_SERIES(
            DATE_TRUNC('month', MIN(started_on)),
            DATE_TRUNC(
                'month',
                MAX(COALESCE(ended_on, DATE '2025-12-31'))
            ),
            INTERVAL '1 month'
        )::date AS month_start
   FROM valid_subscriptions
)
SELECT
    m.month_start,
    COUNT(DISTINCT v.subscription_id) AS active_subscriptions,
    ROUND(
        SUM(v.subscription_mrr),
        2
    ) AS mrr
FROM months m
JOIN valid_subscriptions v
    ON v.started_on < (m.month_start + INTERVAL '1 month')
   AND (
        v.ended_on IS NULL
        OR v.ended_on >= m.month_start
   )
GROUP BY m.month_start
ORDER BY m.month_start;


-- RESULT:
-- Monthly Recurring Revenue grew substantially from $237 in January 2023
-- to a peak of approximately $887,800 in November 2025.
--
-- Active subscriptions increased from 4 in January 2023
-- to more than 2,100 by late 2025.
--
-- MRR generally increased throughout the analysis period,
-- indicating strong growth in the recurring-revenue base.
--
-- December 2025 MRR declined slightly to approximately $874,305,
-- alongside a decrease in active subscriptions from 2,124 to 2,076.
--
-- The late-2025 slowdown should be monitored to determine whether it
-- represents normal subscription turnover or an emerging retention issue.


-- ============================================
-- 2. ANNUAL RECURRING REVENUE (ARR)
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        s.subscription_id,
        s.started_on,
        s.ended_on,
        s.seats,
        (
            p.monthly_price +
            (p.seat_price * s.seats)
        ) AS subscription_mrr
    FROM subscriptions s
    JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE s.ended_on IS NULL
       OR s.ended_on >= s.started_on
),
months AS (
    SELECT
        GENERATE_SERIES(
            DATE_TRUNC('month', MIN(started_on)),
            DATE_TRUNC(
                'month',
                MAX(COALESCE(ended_on, DATE '2025-12-31'))
            ),
            INTERVAL '1 month'
        )::date AS month_start

    FROM valid_subscriptions
),
monthly_mrr AS (
    SELECT
        m.month_start,

        SUM(v.subscription_mrr) AS mrr
    FROM months m
    JOIN valid_subscriptions v
        ON v.started_on < (m.month_start + INTERVAL '1 month')
       AND (
            v.ended_on IS NULL
            OR v.ended_on >= m.month_start
       )

    GROUP BY m.month_start
)
SELECT
    month_start,
    ROUND(mrr, 2) AS mrr,
    ROUND(mrr * 12, 2) AS arr
FROM monthly_mrr
ORDER BY month_start;

-- RESULT:
-- Annual Recurring Revenue (ARR), calculated as MRR × 12,
-- increased substantially throughout the analysis period.
--
-- ARR rose from an annualized run rate of $2,844 in January 2023
-- to a peak of approximately $10.65M in November 2025.
--
-- December 2025 ARR decreased slightly to approximately $10.49M,
-- reflecting the same late-2025 decline observed in MRR.
--
-- ARR represents an annualized recurring-revenue run rate rather than
-- actual revenue collected during the year.


-- ============================================
-- ADVANCED ANALYSIS #3:
-- MONTHLY SUBSCRIPTION CHURN RATE
-- Analysis cutoff: 2025-12-31
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        subscription_id,
        started_on,
        ended_on
    FROM subscriptions
    WHERE started_on <= DATE '2025-12-31'
      AND (ended_on IS NULL OR ended_on >= started_on)
),

months AS (
    SELECT GENERATE_SERIES(
        DATE '2023-01-01',
        DATE '2025-12-01',
        INTERVAL '1 month'
    )::date AS month_start
)

SELECT
    m.month_start,

    COUNT(*) FILTER (
        WHERE v.started_on < m.month_start
          AND (
              v.ended_on IS NULL
              OR v.ended_on >= m.month_start
          )
    ) AS active_at_month_start,

    COUNT(*) FILTER (
        WHERE v.ended_on >= m.month_start
          AND v.ended_on < m.month_start + INTERVAL '1 month'
    ) AS churned_subscriptions,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE v.ended_on >= m.month_start
              AND v.ended_on < m.month_start + INTERVAL '1 month'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE v.started_on < m.month_start
                  AND (
                      v.ended_on IS NULL
                      OR v.ended_on >= m.month_start
                  )
            ),
            0
        ),
        2
    ) AS monthly_churn_rate

FROM months m
CROSS JOIN valid_subscriptions v
GROUP BY m.month_start
ORDER BY m.month_start;


-- RESULT:
-- Monthly churn changed throughout the analysis period.
-- Churn became higher near the end of 2025.
--
-- The churn rate increased to 9.38% in October 2025,
-- 9.73% in November 2025,
-- and reached its highest level of 11.63% in December 2025.
--
-- The increase in late 2025 shows that customer retention
-- became a bigger business problem near the end of the year.



-- ============================================
-- ADVANCED ANALYSIS #4:
-- COHORT RETENTION
-- Analysis cutoff: 2025-12-31
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        subscription_id,
        organization_id,
        started_on,
        ended_on
    FROM subscriptions
    WHERE started_on <= DATE '2025-12-31'
      AND (ended_on IS NULL OR ended_on >= started_on)
),

first_subscription AS (
    SELECT
        organization_id,
        MIN(started_on) AS first_started_on
    FROM valid_subscriptions
    GROUP BY organization_id
),

cohort_data AS (
    SELECT
        f.organization_id,
        f.first_started_on,
        DATE_TRUNC('month', f.first_started_on)::date AS cohort_month,

        CASE
            WHEN f.first_started_on + INTERVAL '3 months' <= DATE '2025-12-31'
            THEN CASE WHEN EXISTS (
                SELECT 1
                FROM valid_subscriptions v
                WHERE v.organization_id = f.organization_id
                  AND v.started_on <= f.first_started_on + INTERVAL '3 months'
                  AND (
                      v.ended_on IS NULL
                      OR v.ended_on >= f.first_started_on + INTERVAL '3 months'
                  )
            ) THEN 1 ELSE 0 END
        END AS retained_3m,

        CASE
            WHEN f.first_started_on + INTERVAL '6 months' <= DATE '2025-12-31'
            THEN CASE WHEN EXISTS (
                SELECT 1
                FROM valid_subscriptions v
                WHERE v.organization_id = f.organization_id
                  AND v.started_on <= f.first_started_on + INTERVAL '6 months'
                  AND (
                      v.ended_on IS NULL
                      OR v.ended_on >= f.first_started_on + INTERVAL '6 months'
                  )
            ) THEN 1 ELSE 0 END
        END AS retained_6m,

        CASE
            WHEN f.first_started_on + INTERVAL '12 months' <= DATE '2025-12-31'
            THEN CASE WHEN EXISTS (
                SELECT 1
                FROM valid_subscriptions v
                WHERE v.organization_id = f.organization_id
                  AND v.started_on <= f.first_started_on + INTERVAL '12 months'
                  AND (
                      v.ended_on IS NULL
                      OR v.ended_on >= f.first_started_on + INTERVAL '12 months'
                  )
            ) THEN 1 ELSE 0 END
        END AS retained_12m

    FROM first_subscription f
)

SELECT
    cohort_month,
    COUNT(*) AS cohort_size,

    ROUND(
        100.0 * SUM(retained_3m) / NULLIF(COUNT(retained_3m), 0),
        2
    ) AS retention_3_month_pct,

    ROUND(
        100.0 * SUM(retained_6m) / NULLIF(COUNT(retained_6m), 0),
        2
    ) AS retention_6_month_pct,

    ROUND(
        100.0 * SUM(retained_12m) / NULLIF(COUNT(retained_12m), 0),
        2
    ) AS retention_12_month_pct

FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month;


-- RESULT:
-- Retention changes across different customer signup cohorts.
-- Earlier cohorts can be compared at 3, 6, and 12 months,
-- while newer cohorts do not yet have enough time for longer retention periods.
--
-- Some cohorts kept a high percentage of customers after 3 months,
-- while 6-month and 12-month retention was more mixed.
--
-- The final analysis stops at December 2025,
-- so future 2026 subscriptions are not included.
--
-- The company should compare strong and weak cohorts
-- to understand what helps customers stay longer.




-- ============================================
-- 5. SUBSCRIPTION LIFETIME BY PLAN
-- ============================================

WITH ended_valid_subscriptions AS (
    SELECT
        s.subscription_id,
        s.plan_id,
        s.started_on,
        s.ended_on,
        (s.ended_on - s.started_on) AS lifetime_days
    FROM subscriptions s
    WHERE s.ended_on IS NOT NULL
      AND s.ended_on >= s.started_on
)
SELECT
    p.plan_name,
    COUNT(*) AS ended_subscriptions,
    ROUND(
        AVG(e.lifetime_days),
        2
    ) AS avg_lifetime_days,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY e.lifetime_days
        )::numeric,
        2
    ) AS median_lifetime_days
FROM ended_valid_subscriptions e
JOIN plans p
    ON e.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY avg_lifetime_days DESC;

-- RESULT:
-- Team Annual has the longest average subscription lifetime at approximately
-- 143.97 days, with a median lifetime of 103.50 days.
--
-- Business Annual is second at approximately 137.05 average days,
-- followed by Business Monthly at 132.08 days.
--
-- Starter Annual has the shortest average lifetime at approximately
-- 124.91 days.
--
-- Annual plans generally show somewhat longer subscription lifetimes,
-- although the differences across plans are not extreme.
--
-- Median lifetimes are consistently lower than average lifetimes,
-- indicating that some longer-lasting subscriptions pull the averages upward.


-- ============================================
-- 6. REVENUE AT RISK FROM CHURN
-- ============================================

WITH valid_ended_subscriptions AS (
    SELECT
        s.subscription_id,
        s.organization_id,
        s.plan_id,
        s.started_on,
        s.ended_on,
        s.seats,
        (
            p.monthly_price +
            (p.seat_price * s.seats)
        ) AS monthly_revenue_at_risk
    FROM subscriptions s
    JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE s.ended_on IS NOT NULL
      AND s.ended_on >= s.started_on
)
SELECT
    p.plan_name,
    COUNT(*) AS ended_subscriptions,
    ROUND(
        SUM(v.monthly_revenue_at_risk),
        2
    ) AS monthly_revenue_at_risk,
    ROUND(
        SUM(v.monthly_revenue_at_risk) * 12,
        2
    ) AS annualized_revenue_at_risk
FROM valid_ended_subscriptions v
JOIN plans p
    ON v.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY monthly_revenue_at_risk DESC;

-- RESULT:
-- Enterprise represents the largest recurring-revenue exposure from ended
-- subscriptions, with approximately $425,456 in monthly recurring revenue
-- associated with churned subscriptions.
--
-- Annualized, this represents approximately $5.11M in recurring-revenue exposure.
--
-- Business Monthly is second at approximately $169,071 monthly
-- and $2.03M annualized.
--
-- Business Annual follows at approximately $123,590 monthly
-- and $1.48M annualized.
--
-- Enterprise churn therefore has the greatest financial impact,
-- making retention of enterprise customers a major business priority.
--
-- These values are annualized recurring-revenue estimates associated
-- with ended subscriptions, not necessarily realized accounting losses.



-- ============================================
-- ADVANCED ANALYSIS #7:
-- HIGH-VALUE CHURN SEGMENTS
-- Analysis cutoff: 2025-12-31
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        s.subscription_id,
        s.organization_id,
        s.plan_id,
        s.started_on,
        s.ended_on,
        s.seats,
        (p.monthly_price + (p.seat_price * s.seats)) AS subscription_mrr
    FROM subscriptions s
    JOIN plans p
        ON s.plan_id = p.plan_id
    WHERE s.started_on <= DATE '2025-12-31'
      AND (s.ended_on IS NULL OR s.ended_on >= s.started_on)
)

SELECT
    o.industry,
    COALESCE(NULLIF(TRIM(o.acquisition_channel), ''), 'unknown')
        AS acquisition_channel,
    o.employee_band,

    COUNT(*) AS total_subscriptions,

    COUNT(*) FILTER (
        WHERE v.ended_on IS NOT NULL
    ) AS ended_subscriptions,

    ROUND(
        100.0 *
        COUNT(*) FILTER (WHERE v.ended_on IS NOT NULL)
        / COUNT(*),
        2
    ) AS ended_subscription_rate,

    ROUND(SUM(v.subscription_mrr), 2) AS total_mrr,

    ROUND(
        SUM(v.subscription_mrr) FILTER (
            WHERE v.ended_on IS NOT NULL
        ),
        2
    ) AS churned_mrr

FROM valid_subscriptions v
JOIN organizations o
    ON v.organization_id = o.organization_id

GROUP BY
    o.industry,
    COALESCE(NULLIF(TRIM(o.acquisition_channel), ''), 'unknown'),
    o.employee_band

HAVING COUNT(*) >= 20

ORDER BY churned_mrr DESC
LIMIT 15;


-- RESULT:
-- Software / Organic / 11-50 employees has the highest churned MRR
-- at approximately $22,648.
--
-- Software customer segments appear several times among the
-- highest-value churn groups.
--
-- Manufacturing / Organic / 11-50 employees has a high
-- ended-subscription rate of 65.71%.
--
-- The company should focus retention efforts on customer groups
-- that combine high recurring revenue with high churn risk.


-- ============================================
-- ADVANCED ANALYSIS #8:
-- PRODUCT USAGE VS RETENTION
-- Analysis cutoff: 2025-12-31
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        organization_id,
        started_on,
        ended_on
    FROM subscriptions
    WHERE started_on <= DATE '2025-12-31'
      AND (ended_on IS NULL OR ended_on >= started_on)
),
organization_status AS (
    SELECT
        organization_id,
        CASE
            WHEN COUNT(*) FILTER (
                WHERE ended_on IS NULL
                   OR ended_on > DATE '2025-12-31'
            ) > 0
            THEN 'active'
            ELSE 'ended_only'
        END AS retention_status
    FROM valid_subscriptions
    GROUP BY organization_id
),
valid_usage AS (
    SELECT
        ue.organization_id,
        COUNT(*) AS usage_events,
        SUM(ue.quantity) AS usage_quantity
    FROM usage_events ue
    JOIN organizations o
        ON ue.organization_id = o.organization_id
    LEFT JOIN users u
        ON ue.user_id = u.user_id
    WHERE ue.occurred_at < DATE '2026-01-01'
      AND ue.occurred_at::date >= o.signed_up_on
      AND (
            ue.user_id IS NULL
            OR ue.occurred_at::date >= u.joined_on
          )
    GROUP BY ue.organization_id
)
SELECT
    os.retention_status,
    COUNT(*) AS organizations,
    ROUND(AVG(COALESCE(vu.usage_events, 0)), 2) AS avg_valid_usage_events,
    ROUND(AVG(COALESCE(vu.usage_quantity, 0)), 2) AS avg_valid_usage_quantity
FROM organization_status os
LEFT JOIN valid_usage vu
    ON os.organization_id = vu.organization_id
GROUP BY os.retention_status
ORDER BY os.retention_status;


-- RESULT:
-- Active organizations had about 17.33 average valid usage events
-- and about 72.09 average usage quantity.
--
-- Organizations with only ended subscriptions had about 18.44
-- average valid usage events and about 76.64 average usage quantity.
--
-- Ended customers had slightly higher historical usage than active customers.
-- This does not mean that higher usage causes churn.
--
-- Customer lifetime may affect these numbers because ended customers
-- may have had more time to use the product.
--
-- Product usage should be studied together with customer lifetime,
-- pricing, plan type, and cancellation reasons.


