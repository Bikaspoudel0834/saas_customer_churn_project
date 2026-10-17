-- ============================================
-- PROJECT 2: SAAS CUSTOMER CHURN & REVENUE ANALYSIS
-- FILE: 04_business_analysis.sql
-- PURPOSE: ANSWER CORE BUSINESS QUESTIONS ABOUT
--          REVENUE, CUSTOMERS, PLANS, CHURN,
--          BILLING, AND PRODUCT PERFORMANCE
-- ============================================


-- ============================================
-- BUSINESS QUESTION 1:
-- WHICH PLANS GENERATE THE MOST PAID INVOICE VALUE?
-- ============================================

WITH paid_billing_periods AS (
    SELECT
        subscription_id,
        period_start,
        period_end,
        MAX(amount) AS paid_amount
    FROM invoices
    WHERE status = 'paid'
    GROUP BY
        subscription_id,
        period_start,
        period_end
)
SELECT
    p.plan_name,
    p.tier,
    COUNT(*) AS paid_billing_periods,
    ROUND(SUM(pb.paid_amount), 2) AS paid_invoice_value,
    ROUND(AVG(pb.paid_amount), 2) AS avg_paid_invoice_value
FROM paid_billing_periods pb
JOIN subscriptions s
    ON pb.subscription_id = s.subscription_id
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY
    p.plan_name,
    p.tier
ORDER BY paid_invoice_value DESC;

-- RESULT:
-- Enterprise generates the highest paid invoice value at approximately $6.27M.
-- Business Annual is second at approximately $3.41M.
-- Business Monthly follows at approximately $2.17M.
--
-- Annual plans generally produce much higher average paid invoice values
-- because they cover longer billing periods.
--
-- The Free plan generates $0 in paid invoice value, as expected.
--
-- Enterprise is the strongest revenue-generating plan in the dataset.


-- ============================================
-- BUSINESS QUESTION 2:
-- WHICH INDUSTRIES GENERATE THE MOST PAID INVOICE VALUE?
-- ============================================

WITH paid_billing_periods AS (
    SELECT
        subscription_id,
        period_start,
        period_end,
        MAX(amount) AS paid_amount
    FROM invoices
    WHERE status = 'paid'
    GROUP BY
        subscription_id,
        period_start,
        period_end
)
SELECT
    o.industry,
    COUNT(DISTINCT o.organization_id) AS organizations,
    ROUND(SUM(pb.paid_amount), 2) AS paid_invoice_value,
    ROUND(
        SUM(pb.paid_amount) / COUNT(DISTINCT o.organization_id),
        2
    ) AS avg_paid_value_per_organization
FROM paid_billing_periods pb
JOIN subscriptions s
    ON pb.subscription_id = s.subscription_id
JOIN organizations o
    ON s.organization_id = o.organization_id
GROUP BY o.industry
ORDER BY paid_invoice_value DESC;

-- RESULT:
-- Software generates the highest paid invoice value at approximately $3.54M.
-- Retail is second at approximately $2.14M, followed by finance at $1.65M.
--
-- Software also has the largest number of organizations represented in paid billing.
-- However, average paid value per organization is relatively strong across
-- several industries, including software, logistics, media, and retail.
--
-- Revenue is therefore driven partly by industry size rather than being
-- concentrated entirely in one unusually high-value industry.


-- ============================================
-- BUSINESS QUESTION 3:
-- WHICH COUNTRIES GENERATE THE MOST PAID INVOICE VALUE?
-- ============================================

WITH paid_billing_periods AS (
    SELECT
        subscription_id,
        period_start,
        period_end,
        MAX(amount) AS paid_amount
    FROM invoices
    WHERE status = 'paid'
    GROUP BY
        subscription_id,
        period_start,
        period_end
)
SELECT
    o.country,
    COUNT(DISTINCT o.organization_id) AS organizations,
    ROUND(SUM(pb.paid_amount), 2) AS paid_invoice_value,
    ROUND(
        SUM(pb.paid_amount) / COUNT(DISTINCT o.organization_id),
        2
    ) AS avg_paid_value_per_organization
FROM paid_billing_periods pb
JOIN subscriptions s
    ON pb.subscription_id = s.subscription_id
JOIN organizations o
    ON s.organization_id = o.organization_id
GROUP BY o.country
ORDER BY paid_invoice_value DESC;

-- RESULT:
-- The United States generates the highest paid invoice value at approximately $2.84M.
-- Great Britain is second at approximately $1.71M, followed by Canada at $1.28M.
--
-- Although the US leads in total paid value, some smaller markets generate
-- higher average paid value per organization.
--
-- Finland has the highest average paid value per organization at approximately $6,333.45,
-- followed by the Netherlands at approximately $6,140.25 and France at $5,956.55.
--
-- This suggests that total market size and customer value should both be considered
-- when evaluating geographic growth opportunities.


-- ============================================
-- BUSINESS QUESTION 4:
-- WHICH COMPANY SIZES GENERATE THE MOST PAID INVOICE VALUE?
-- ============================================

WITH paid_billing_periods AS (
    SELECT
        subscription_id,
        period_start,
        period_end,
        MAX(amount) AS paid_amount
    FROM invoices
    WHERE status = 'paid'
    GROUP BY
        subscription_id,
        period_start,
        period_end
)
SELECT
    o.employee_band,
    COUNT(DISTINCT o.organization_id) AS organizations,
    ROUND(SUM(pb.paid_amount), 2) AS paid_invoice_value,
    ROUND(
        SUM(pb.paid_amount) / COUNT(DISTINCT o.organization_id),
        2
    ) AS avg_paid_value_per_organization
FROM paid_billing_periods pb
JOIN subscriptions s
    ON pb.subscription_id = s.subscription_id
JOIN organizations o
    ON s.organization_id = o.organization_id
GROUP BY o.employee_band
ORDER BY paid_invoice_value DESC;

-- RESULT:
-- Organizations with 11-50 employees generate the highest paid invoice value
-- at approximately $4.80M.
--
-- Organizations with 1-10 employees are second at approximately $4.33M,
-- followed by the 51-200 employee segment at approximately $3.52M.
--
-- Average paid value per organization is fairly similar across most company-size
-- segments, while the 1000+ employee segment has the lowest average at $4,615.56.
--
-- Small and mid-sized organizations therefore contribute the majority of
-- paid invoice value in this dataset.



-- ============================================
-- BUSINESS QUESTION 5:
-- WHICH ACQUISITION CHANNELS GENERATE THE MOST PAID INVOICE VALUE?
-- ============================================

WITH paid_billing_periods AS (
    SELECT
        subscription_id,
        period_start,
        period_end,
        MAX(amount) AS paid_amount
    FROM invoices
    WHERE status = 'paid'
    GROUP BY
        subscription_id,
        period_start,
        period_end
)
SELECT
    CASE
        WHEN TRIM(o.acquisition_channel) = '' THEN 'unknown'
        ELSE o.acquisition_channel
    END AS acquisition_channel,
    COUNT(DISTINCT o.organization_id) AS organizations,
    ROUND(SUM(pb.paid_amount), 2) AS paid_invoice_value,
    ROUND(
        SUM(pb.paid_amount) / COUNT(DISTINCT o.organization_id),
        2
    ) AS avg_paid_value_per_organization
FROM paid_billing_periods pb
JOIN subscriptions s
    ON pb.subscription_id = s.subscription_id
JOIN organizations o
    ON s.organization_id = o.organization_id
GROUP BY
    CASE
        WHEN TRIM(o.acquisition_channel) = '' THEN 'unknown'
        ELSE o.acquisition_channel
    END

ORDER BY paid_invoice_value DESC;

-- RESULT:
-- Organic generates the highest paid invoice value at approximately $4.19M.
-- Paid search is second at approximately $2.97M.
-- Organizations with an unknown acquisition channel generate about $2.47M.
--
-- Partner-acquired organizations have the highest average paid value
-- per organization at approximately $6,513.68.
--
-- Organic leads in total revenue contribution, while the partner channel
-- appears to attract fewer but higher-value organizations.


-- ============================================
-- BUSINESS QUESTION 6:
-- WHICH PLANS HAVE THE HIGHEST UNRESOLVED
-- PAYMENT-FAILURE RATE?
-- ============================================

WITH billing_periods AS (
    SELECT
        subscription_id,
        period_start,
        period_end,

        MAX(CASE
            WHEN status = 'paid' THEN 1
            ELSE 0
        END) AS has_paid,

        MAX(CASE
            WHEN status = 'failed' THEN 1
            ELSE 0
        END) AS has_failed

    FROM invoices
    GROUP BY
        subscription_id,
        period_start,
        period_end
)
SELECT
    p.plan_name,
    COUNT(*) AS billing_periods,
    SUM(bp.has_failed) AS periods_with_failed_attempt,
    COUNT(*) FILTER (
        WHERE bp.has_failed = 1
          AND bp.has_paid = 0
    ) AS unresolved_failed_periods,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE bp.has_failed = 1
              AND bp.has_paid = 0
        ) / COUNT(*),
        2
    ) AS unresolved_failure_rate
FROM billing_periods bp
JOIN subscriptions s
    ON bp.subscription_id = s.subscription_id
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY unresolved_failure_rate DESC;

-- RESULT:
-- Unresolved payment-failure rates are low across all plans, remaining below 1.20%.
--
-- Free has the highest unresolved failure rate at 1.19%.
-- Among paid plans, Business Monthly has the highest rate at 1.09%,
-- followed by Business Annual at 1.03% and Enterprise at 1.01%.
--
-- Team Monthly has the lowest unresolved failure rate at 0.64%.
--
-- Most failed payment attempts appear to be resolved successfully,
-- but Business Monthly and Enterprise should still be monitored because
-- they combine meaningful billing volume with relatively higher unresolved failures.



-- ============================================
-- BUSINESS QUESTION #7:
-- CANCELLATION REASONS
-- Analysis cutoff: 2025-12-31
-- ============================================

WITH valid_ended_subscriptions AS (
    SELECT
        cancel_reason
    FROM subscriptions
    WHERE started_on <= DATE '2025-12-31'
      AND ended_on IS NOT NULL
      AND ended_on >= started_on
)

SELECT
    cancel_reason,
    COUNT(*) AS cancelled_subscriptions,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS cancellation_pct
FROM valid_ended_subscriptions
GROUP BY cancel_reason
ORDER BY cancelled_subscriptions DESC;


-- RESULT:
-- Price is the biggest cancellation reason at 27.18%.
-- Missing features is second at 23.77%.
--
-- No longer needed and switched vendor are both around 19%.
-- Non-payment is the smallest cancellation reason at 10.89%.
--
-- Pricing and missing product features are the two main reasons
-- customers cancel their subscriptions.


-- ============================================
-- BUSINESS QUESTION 8:
-- WHICH ACQUISITION CHANNELS HAVE THE HIGHEST
-- ENDED-SUBSCRIPTION RATES?
-- ============================================

SELECT
    CASE
        WHEN TRIM(o.acquisition_channel) = '' THEN 'unknown'
        ELSE o.acquisition_channel
    END AS acquisition_channel,
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (
        WHERE s.ended_on IS NULL
    ) AS active_subscriptions,
    COUNT(*) FILTER (
        WHERE s.ended_on IS NOT NULL
    ) AS ended_subscriptions,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE s.ended_on IS NOT NULL
        ) / COUNT(*),
        2
    ) AS ended_subscription_rate
FROM subscriptions s
JOIN organizations o
    ON s.organization_id = o.organization_id
GROUP BY
    CASE
        WHEN TRIM(o.acquisition_channel) = '' THEN 'unknown'
        ELSE o.acquisition_channel
    END
ORDER BY ended_subscription_rate DESC;

-- RESULT:
-- Referral has the highest ended-subscription rate at 55.85%.
-- Organic and outbound are both around 53%.
-- Unknown acquisition channel is also relatively high at 52.69%.
--
-- Paid search and partner have the lowest ended-subscription rates,
-- both at 48.87%.
--
-- Referral brings in customers with the weakest retention profile,
-- while partner and paid search appear to retain customers somewhat better.




-- ============================================
-- BUSINESS QUESTION #9:
-- ENDED-SUBSCRIPTION RATE BY INDUSTRY
-- Analysis cutoff: 2025-12-31
-- ============================================

WITH valid_subscriptions AS (
    SELECT
        s.subscription_id,
        s.organization_id,
        s.started_on,
        s.ended_on
    FROM subscriptions s
    WHERE s.started_on <= DATE '2025-12-31'
      AND (s.ended_on IS NULL OR s.ended_on >= s.started_on)
)

SELECT
    o.industry,
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (
        WHERE v.ended_on IS NOT NULL
    ) AS ended_subscriptions,
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE v.ended_on IS NOT NULL
        ) / COUNT(*),
        2
    ) AS ended_subscription_rate
FROM valid_subscriptions v
JOIN organizations o
    ON v.organization_id = o.organization_id
GROUP BY o.industry
ORDER BY ended_subscription_rate DESC;


-- RESULT:
-- Media has the highest ended-subscription rate at 61.18%.
-- Nonprofit is second at 55.92%, followed by government at 54.65%
-- and manufacturing at 54.45%.
--
-- Finance has the lowest ended-subscription rate at 50.45%.
-- Healthcare is also relatively lower at 52.66%.
--
-- Media customers have the weakest retention profile,
-- so the company should study why customers in this industry leave more often.


-- ============================================
-- BUSINESS QUESTION 10:
-- WHICH COMPANY SIZES HAVE THE HIGHEST
-- ENDED-SUBSCRIPTION RATES?
-- ============================================

SELECT
    o.employee_band,
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (
        WHERE s.ended_on IS NULL
    ) AS active_subscriptions,
    COUNT(*) FILTER (
        WHERE s.ended_on IS NOT NULL
    ) AS ended_subscriptions,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE s.ended_on IS NOT NULL
        ) / COUNT(*),
        2
    ) AS ended_subscription_rate
FROM subscriptions s
JOIN organizations o
    ON s.organization_id = o.organization_id
GROUP BY o.employee_band
ORDER BY ended_subscription_rate DESC;

-- RESULT:
-- Organizations with 201-1000 employees have the highest
-- ended-subscription rate at 54.10%.
--
-- The 11-50 and 1000+ employee segments are both around 52.6%.
-- The 1-10 employee segment has an ended rate of 52.07%.
--
-- Organizations with 51-200 employees have the lowest ended-subscription
-- rate at 50.21%.
--
-- Retention differences by company size are present but relatively modest
-- compared with some of the industry-level differences.


- ============================================
-- BUSINESS QUESTION 11:
-- WHICH COUNTRIES HAVE THE HIGHEST
-- ENDED-SUBSCRIPTION RATES?
-- ============================================

SELECT
    o.country,
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (
        WHERE s.ended_on IS NULL
    ) AS active_subscriptions,
    COUNT(*) FILTER (
        WHERE s.ended_on IS NOT NULL
    ) AS ended_subscriptions,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE s.ended_on IS NOT NULL
        ) / COUNT(*),
        2
    ) AS ended_subscription_rate
FROM subscriptions s
JOIN organizations o
    ON s.organization_id = o.organization_id
GROUP BY o.country
ORDER BY ended_subscription_rate DESC;

-- RESULT:
-- Slovenia has the highest ended-subscription rate at 57.28%,
-- followed by Sweden at 55.78% and Norway at 54.92%.
--
-- Canada has the lowest ended-subscription rate at 48.49%,
-- followed by Finland at 49.14%.
--
-- The United States, the largest market by subscription volume,
-- has an ended-subscription rate of 52.69%.
--
-- Retention varies across countries, but market size should be considered
-- together with ended-subscription rate when prioritizing retention efforts.



-- ============================================
-- BUSINESS QUESTION 12:
-- WHICH PLANS COMBINE HIGH REVENUE WITH
-- HIGH ENDED-SUBSCRIPTION RATES?
-- ============================================

WITH paid_billing_periods AS (
    SELECT
        subscription_id,
        period_start,
        period_end,
        MAX(amount) AS paid_amount
    FROM invoices
    WHERE status = 'paid'
    GROUP BY
        subscription_id,
        period_start,
        period_end
),
plan_revenue AS (
    SELECT
        p.plan_id,
        p.plan_name,
        ROUND(SUM(pb.paid_amount), 2) AS paid_invoice_value
    FROM paid_billing_periods pb
    JOIN subscriptions s
        ON pb.subscription_id = s.subscription_id
    JOIN plans p
        ON s.plan_id = p.plan_id
    GROUP BY
        p.plan_id,
        p.plan_name
),
plan_retention AS (
    SELECT
        p.plan_id,
        p.plan_name,
        COUNT(*) AS total_subscriptions,
        COUNT(*) FILTER (
            WHERE s.ended_on IS NOT NULL
        ) AS ended_subscriptions,
        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE s.ended_on IS NOT NULL
            ) / COUNT(*),
            2
        ) AS ended_subscription_rate
    FROM subscriptions s
    JOIN plans p
        ON s.plan_id = p.plan_id
    GROUP BY
        p.plan_id,
        p.plan_name
)
SELECT
    r.plan_name,
    r.paid_invoice_value,
    p.total_subscriptions,
    p.ended_subscriptions,
    p.ended_subscription_rate
FROM plan_revenue r
JOIN plan_retention p
    ON r.plan_id = p.plan_id
ORDER BY r.paid_invoice_value DESC;


-- RESULT:
-- Enterprise generates the highest paid invoice value at approximately $6.27M
-- while maintaining an ended-subscription rate of 50.26%.
--
-- Business Annual is the second-highest revenue plan at approximately $3.41M
-- and has the lowest ended-subscription rate among all plans at 48.91%.
--
-- Business Monthly generates approximately $2.17M but has a higher
-- ended-subscription rate of 53.54%.
--
-- Team Monthly and Starter Annual have relatively high ended-subscription
-- rates at 55.43% and 55.66%, respectively, while generating much less
-- revenue than Enterprise and Business plans.
--
-- Business Annual appears particularly strong because it combines
-- high paid invoice value with the lowest ended-subscription rate.



-- ============================================
-- BUSINESS ANALYSIS SUMMARY
-- ============================================

-- Enterprise is the strongest revenue-generating plan, producing
-- approximately $6.27M in paid invoice value.
--
-- Business Annual is also strategically important because it generates
-- approximately $3.41M while having the lowest ended-subscription rate
-- among all plans at 48.91%.
--
-- Software is the highest-revenue industry at approximately $3.54M,
-- followed by retail and finance.
--
-- The United States is the largest geographic market by paid invoice value,
-- generating approximately $2.84M.
-- However, smaller markets such as Finland, the Netherlands, and France
-- show higher average paid value per organization.
--
-- Organizations with 11-50 employees generate the highest paid invoice value
-- at approximately $4.80M.
-- Small and mid-sized organizations contribute the majority of revenue.
--
-- Organic is the highest-revenue acquisition channel at approximately $4.19M.
-- Partner-acquired organizations have the highest average paid value per
-- organization at approximately $6,513.68.
--
-- Unresolved payment-failure rates remain low across all plans,
-- generally below 1.20%.
--
-- Price is the most common cancellation reason at 27.21%,
-- followed by missing features at 23.70%.
-- Together, these two reasons represent more than half of cancellations.
--
-- Referral has the highest ended-subscription rate among acquisition channels
-- at 55.85%, while partner and paid search have the lowest rates at 48.87%.
--
-- Media has the highest ended-subscription rate among industries at 59.54%,
-- while finance has the lowest at 47.88%.
--
-- Organizations with 201-1000 employees have the highest ended-subscription
-- rate by employee band at 54.10%.
--
-- Slovenia, Sweden, and Norway show the highest ended-subscription rates
-- among countries, while Canada and Finland show the lowest.
--
-- Overall, the strongest business opportunities appear to be:
-- protecting high-value Enterprise and Business customers,
-- improving retention around pricing and missing features,
-- investigating weaker-retention segments such as media and referral customers,
-- and expanding acquisition channels and geographic markets that combine
-- strong customer value with better retention.