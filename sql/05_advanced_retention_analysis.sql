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
-- 3. MONTHLY SUBSCRIPTION CHURN RATE
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        subscription_id,
        started_on,
        ended_on
    FROM subscriptions
    WHERE ended_on IS NULL
       OR ended_on >= started_on
),
months AS (
    SELECT
        GENERATE_SERIES(
            DATE '2023-01-01',
            DATE '2025-12-01',
            INTERVAL '1 month'
        )::date AS month_start
),
monthly_churn AS (
    SELECT
        m.month_start,
        COUNT(v.subscription_id) FILTER (
            WHERE v.started_on <= m.month_start
              AND (
                    v.ended_on IS NULL
                    OR v.ended_on >= m.month_start
                  )
        ) AS active_at_start,
        COUNT(v.subscription_id) FILTER (
            WHERE v.ended_on >= m.month_start
              AND v.ended_on < m.month_start + INTERVAL '1 month'
        ) AS churned_subscriptions
    FROM months m
    CROSS JOIN valid_subscriptions v
    GROUP BY m.month_start
)
SELECT
    month_start,
    active_at_start,
    churned_subscriptions,
    ROUND(
        100.0 * churned_subscriptions /
        NULLIF(active_at_start, 0),
        2
    ) AS monthly_churn_rate
FROM monthly_churn
ORDER BY month_start;

-- RESULT:
-- Monthly churn was relatively low during the early growth period,
-- partly because the active subscription base was still small.
--
-- Churn generally ranged between about 5% and 10% through most of 2024-2025.
--
-- August 2024 reached 10.22% and September 2024 reached 10.06%.
--
-- Churn increased again late in 2025:
-- October 2025: 9.36%
-- November 2025: 9.70%
-- December 2025: 11.53%
--
-- December 2025 recorded the highest monthly churn rate in the analysis period.
--
-- The increase in churn during late 2025 aligns with the slowdown observed
-- in MRR and ARR and may indicate emerging retention pressure.
--
-- January 2023 has no churn rate because there were no subscriptions
-- active at the beginning of that month.



-- ============================================
-- 4. SUBSCRIPTION COHORT RETENTION
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        subscription_id,
        organization_id,
        started_on,
        ended_on
    FROM subscriptions
    WHERE ended_on IS NULL
       OR ended_on >= started_on
),
analysis_cutoff AS (
    SELECT
        MAX(started_on) AS cutoff_date
    FROM valid_subscriptions
),
first_subscription AS (
    SELECT
        organization_id,
        MIN(started_on) AS first_subscription_date
    FROM valid_subscriptions
    GROUP BY organization_id
),
organization_retention AS (
    SELECT
        f.organization_id,
        f.first_subscription_date,
        DATE_TRUNC(
            'month',
            f.first_subscription_date
        )::date AS cohort_month,
        CASE
            WHEN f.first_subscription_date + INTERVAL '3 months'
                 <= a.cutoff_date
            THEN CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM valid_subscriptions s
                    WHERE s.organization_id = f.organization_id
                      AND s.started_on <=
                          f.first_subscription_date + INTERVAL '3 months'
                      AND (
                          s.ended_on IS NULL
                          OR s.ended_on >=
                             f.first_subscription_date + INTERVAL '3 months'
                      )
                )
                THEN 1 ELSE 0
            END
        END AS retained_3_months,
        CASE
            WHEN f.first_subscription_date + INTERVAL '6 months'
                 <= a.cutoff_date
            THEN CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM valid_subscriptions s
                    WHERE s.organization_id = f.organization_id
                      AND s.started_on <=
                          f.first_subscription_date + INTERVAL '6 months'
                      AND (
                          s.ended_on IS NULL
                          OR s.ended_on >=
                             f.first_subscription_date + INTERVAL '6 months'
                      )
                )
                THEN 1 ELSE 0
            END
        END AS retained_6_months,
        CASE
            WHEN f.first_subscription_date + INTERVAL '12 months'
                 <= a.cutoff_date
            THEN CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM valid_subscriptions s
                    WHERE s.organization_id = f.organization_id
                      AND s.started_on <=
                          f.first_subscription_date + INTERVAL '12 months'
                      AND (
                          s.ended_on IS NULL
                          OR s.ended_on >=
                             f.first_subscription_date + INTERVAL '12 months'
                      )
                )
                THEN 1 ELSE 0
            END
        END AS retained_12_months
    FROM first_subscription f
    CROSS JOIN analysis_cutoff a
)
SELECT
    cohort_month,
    COUNT(*) AS cohort_size,
    ROUND(
        100.0 * SUM(retained_3_months) /
        NULLIF(COUNT(retained_3_months), 0),
        2
    ) AS retention_3_month_pct,
    ROUND(
        100.0 * SUM(retained_6_months) /
        NULLIF(COUNT(retained_6_months), 0),
        2
    ) AS retention_6_month_pct,
    ROUND(
        100.0 * SUM(retained_12_months) /
        NULLIF(COUNT(retained_12_months), 0),
        2
    ) AS retention_12_month_pct
FROM organization_retention
GROUP BY cohort_month
ORDER BY cohort_month;

-- RESULT:
-- Early cohorts generally show strong 3-month retention, often above 80%.
--
-- Retention typically declines by the 6-month and 12-month horizons,
-- showing that customer loss becomes more meaningful over longer periods.
--
-- Several 2024 cohorts retain roughly 65%-76% of organizations at 12 months,
-- while some earlier 2023 cohorts fall closer to 30%-55%.
--
-- Newer cohorts correctly show NULL values for retention horizons that
-- have not yet been reached, preventing immature cohorts from being
-- incorrectly reported as 100% retained.
--
-- Because organizations can later start another subscription,
-- retention at a later horizon can occasionally exceed an earlier horizon.
-- This analysis therefore measures whether an organization is active
-- at each milestone rather than uninterrupted subscription survival.


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
-- 7. HIGH-VALUE CHURN SEGMENTS
-- ============================================

WITH subscription_value AS (
    SELECT
        s.subscription_id,
        s.organization_id,
        s.ended_on,
        o.industry,
        o.employee_band,
        CASE
            WHEN TRIM(o.acquisition_channel) = '' THEN 'unknown'
            ELSE o.acquisition_channel
        END AS acquisition_channel,
        (
            p.monthly_price +
            (p.seat_price * s.seats)
        ) AS subscription_mrr
    FROM subscriptions s
    JOIN organizations o
        ON s.organization_id = o.organization_id
    JOIN plans p
        ON s.plan_id = p.plan_id

    WHERE s.ended_on IS NULL
       OR s.ended_on >= s.started_on
)
SELECT
    industry,
    acquisition_channel,
    employee_band,
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (
        WHERE ended_on IS NOT NULL
    ) AS ended_subscriptions,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE ended_on IS NOT NULL
        ) / COUNT(*),
        2
    ) AS ended_subscription_rate,
    ROUND(
        SUM(subscription_mrr),
        2
    ) AS total_mrr,
    ROUND(
        SUM(subscription_mrr) FILTER (
            WHERE ended_on IS NOT NULL
        ),
        2
    ) AS churned_mrr
FROM subscription_value
GROUP BY
    industry,
    acquisition_channel,
    employee_band
HAVING COUNT(*) >= 20
ORDER BY churned_mrr DESC
LIMIT 15;

-- RESULT:
-- High-value churn exposure is concentrated heavily in software-related segments.
--
-- Software / Organic / 11-50 employees has the highest churned MRR
-- at approximately $22,648.
--
-- Software / Organic / 1-10 employees follows at approximately $16,544,
-- while Software / Paid Search / 11-50 employees contributes about $15,873
-- in churned MRR.
--
-- Manufacturing / Organic / 11-50 employees has the highest
-- ended-subscription rate among the top-risk segments at 65.71%.
--
-- These results suggest that retention efforts should not focus only on
-- overall churn rate. Management should prioritize customer segments that
-- combine high recurring value with high subscription-ending rates.


-- ============================================
-- 8. PRODUCT USAGE VS RETENTION
-- ============================================

WITH valid_usage AS (
    SELECT
        ue.organization_id,
        ue.event_id,
        ue.quantity
    FROM usage_events ue
    JOIN organizations o
        ON ue.organization_id = o.organization_id
    LEFT JOIN users u
        ON ue.user_id = u.user_id
    WHERE ue.occurred_at::date >= o.signed_up_on
      AND (
            ue.user_id IS NULL
            OR ue.occurred_at::date >= u.joined_on
          )
),
organization_usage AS (
    SELECT
        organization_id,
        COUNT(*) AS valid_usage_events,
        SUM(quantity) AS total_usage_quantity
    FROM valid_usage
    GROUP BY organization_id
),
organization_status AS (
    SELECT
        o.organization_id,
        CASE
            WHEN COUNT(*) FILTER (
                WHERE s.ended_on IS NULL
            ) > 0
            THEN 'active'
            ELSE 'ended_only'
        END AS retention_status
    FROM organizations o
    JOIN subscriptions s
        ON o.organization_id = s.organization_id
    WHERE s.ended_on IS NULL
       OR s.ended_on >= s.started_on
    GROUP BY o.organization_id
)
SELECT
    os.retention_status,
    COUNT(*) AS organizations,
    ROUND(
        AVG(COALESCE(ou.valid_usage_events, 0)),
        2
    ) AS avg_usage_events_per_org,
    ROUND(
        AVG(COALESCE(ou.total_usage_quantity, 0)),
        2
    ) AS avg_usage_quantity_per_org
FROM organization_status os
LEFT JOIN organization_usage ou
    ON os.organization_id = ou.organization_id
GROUP BY os.retention_status
ORDER BY retention_status;

-- RESULT:
-- Organizations with active subscriptions average 16.05 valid usage events
-- and 66.73 units of usage quantity per organization.
--
-- Organizations with only ended subscriptions average 19.54 valid usage events
-- and 81.28 units of usage quantity per organization.
--
-- In this dataset, ended-only organizations show higher historical product usage
-- than organizations that still have an active subscription.
--
-- Higher usage therefore does not appear to guarantee stronger retention.
-- However, this comparison should not be interpreted as causal because
-- ended organizations may have had more time to accumulate historical usage.
--
-- A tenure-adjusted usage analysis would be needed before concluding that
-- usage intensity increases or decreases churn risk.



-- ============================================
-- ADVANCED RETENTION ANALYSIS SUMMARY
-- ============================================

-- Monthly Recurring Revenue (MRR) grew from $237 in January 2023
-- to a peak of approximately $887,800 in November 2025.
--
-- Annual Recurring Revenue (ARR) reached an annualized peak
-- of approximately $10.65M in November 2025.
--
-- Both MRR and ARR declined slightly in December 2025,
-- suggesting that late-2025 retention trends should be monitored.
--
-- Monthly subscription churn generally ranged between about 5% and 10%
-- during most of the mature analysis period.
-- December 2025 recorded the highest churn rate at 11.53%.
--
-- Cohort analysis shows that retention generally weakens as customers
-- progress from 3-month to 6-month and 12-month milestones.
-- More recent cohorts were excluded from retention horizons they had
-- not yet reached.
--
-- Subscription lifetime varies moderately across plans.
-- Team Annual has the longest average lifetime at approximately 143.97 days,
-- while Starter Annual has the shortest at approximately 124.91 days.
--
-- Enterprise subscriptions create the greatest recurring-revenue exposure
-- when they end, representing approximately $425,456 in monthly recurring
-- revenue and $5.11M on an annualized basis.
--
-- Business Monthly and Business Annual also represent substantial
-- recurring-revenue exposure from ended subscriptions.
--
-- High-value churn risk is concentrated in several software customer segments,
-- especially organizations acquired organically or through paid search.
--
-- Software / Organic / 11-50 employees has the highest churned MRR
-- among the analyzed customer segments at approximately $22,648.
--
-- Manufacturing / Organic / 11-50 employees shows especially high retention
-- risk, with an ended-subscription rate of 65.71%.
--
-- Timeline-valid product usage does not show a simple positive relationship
-- with retention. Organizations with only ended subscriptions actually show
-- higher average historical usage than currently active organizations.
--
-- This indicates that churn cannot be explained by usage volume alone.
-- Pricing, missing features, customer segment, acquisition source,
-- product fit, and customer lifecycle should all be considered together.
--
-- Overall, management should prioritize:
-- 1. Protecting Enterprise and Business recurring revenue.
-- 2. Addressing late-2025 increases in churn.
-- 3. Improving pricing and product capabilities, the two leading
--    cancellation drivers identified earlier.
-- 4. Targeting high-value customer segments with elevated churn exposure.
-- 5. Using tenure-adjusted product engagement metrics before making
--    retention decisions based on usage alone.

