-- ============================================
-- PROJECT 2: SAAS CUSTOMER CHURN & REVENUE ANALYSIS
-- FILE: 03_exploratory_analysis.sql
-- PURPOSE: EXPLORE BUSINESS SIZE, CUSTOMER BASE,
--          SUBSCRIPTIONS, REVENUE, AND PRODUCT USAGE
-- ============================================


-- ============================================
-- 1. OVERALL BUSINESS SNAPSHOT
-- ============================================

SELECT
    (SELECT COUNT(*) FROM organizations) AS total_organizations,
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM subscriptions) AS total_subscriptions,
    (SELECT COUNT(*) FROM subscriptions WHERE ended_on IS NULL) AS active_subscriptions,
    (SELECT COUNT(*) FROM subscriptions WHERE ended_on IS NOT NULL) AS ended_subscriptions,
    (SELECT COUNT(*) FROM invoices) AS total_invoice_records,
    (SELECT COUNT(*) FROM usage_events) AS total_usage_events;

    -- RESULT:
-- Total organizations: 3,000
-- Total users: 26,000
-- Total subscriptions: 4,200
-- Active subscriptions: 2,010
-- Ended subscriptions: 2,190
-- Total invoice records: 46,000
-- Total usage events: 180,000


-- ============================================
-- 2. ORGANIZATIONS BY INDUSTRY
-- ============================================

SELECT
    industry,
    COUNT(*) AS organizations,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS organization_pct
FROM organizations
GROUP BY industry
ORDER BY organizations DESC;

-- RESULT:
-- Software is the largest industry with 646 organizations (21.53%).
-- Retail is second with 407 organizations (13.57%).
-- Finance, education, and healthcare each represent about 10–11% of organizations.
-- Government is the smallest segment with 66 organizations (2.20%).


-- ============================================
-- 3. ORGANIZATIONS BY COUNTRY
-- ============================================

SELECT
    country,
    COUNT(*) AS organizations,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS organization_pct
FROM organizations
GROUP BY country
ORDER BY organizations DESC;

-- RESULT:
-- The United States is the largest market with 555 organizations (18.50%).
-- Great Britain is second with 346 organizations (11.53%).
-- Canada and Australia also represent meaningful shares at 8.87% and 8.30%.
-- The customer base is geographically diversified across 17 countries.


-- ============================================
-- 4. ORGANIZATIONS BY EMPLOYEE BAND
-- ============================================

SELECT
    employee_band,
    COUNT(*) AS organizations,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS organization_pct
FROM organizations
GROUP BY employee_band
ORDER BY organizations DESC;

-- RESULT:
-- Organizations with 11-50 employees are the largest segment with 931 organizations (31.03%).
-- Organizations with 1-10 employees represent 27.67%.
-- Together, organizations with 50 or fewer employees make up 58.70% of the customer base.
-- Large organizations with 1,000+ employees represent only 5.10%.


-- ============================================
-- 5. ORGANIZATIONS BY ACQUISITION CHANNEL
-- ============================================

SELECT
    acquisition_channel,
    COUNT(*) AS organizations,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS organization_pct
FROM organizations
GROUP BY acquisition_channel
ORDER BY organizations DESC;

-- RESULT:
-- Organic is the largest acquisition channel with 759 organizations (25.30%).
-- Paid search is second with 545 organizations (18.17%).
-- 528 organizations (17.60%) have a blank acquisition_channel value.
-- Referral, outbound, and partner channels make up the remaining customer acquisition mix.


-- ============================================
-- 6. SUBSCRIPTIONS BY PLAN
-- ============================================

SELECT
    p.plan_name,
    p.tier,
    p.billing_interval,
    COUNT(*) AS subscriptions,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS subscription_pct
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY
    p.plan_name,
    p.tier,
    p.billing_interval
ORDER BY subscriptions DESC;

-- RESULT:
-- Subscription volume is fairly balanced across the eight plans.
-- Enterprise has the largest share with 571 subscriptions (13.60%).
-- Business Annual has the smallest share with 503 subscriptions (11.98%).
-- No single plan dominates the customer base, indicating broad adoption
-- across free, starter, team, business, and enterprise offerings.


-- ============================================
-- 7. ACTIVE VS ENDED SUBSCRIPTIONS BY PLAN
-- ============================================

SELECT
    p.plan_name,
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
    ) AS ended_pct
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY ended_pct DESC;

-- RESULT:
-- Starter Annual has the highest ended-subscription rate at 55.66%.
-- Team Monthly is close behind at 55.43%.
-- Business Annual has the lowest ended-subscription rate at 48.91%.
-- Churn/ending rates are relatively close across plans, suggesting that
-- plan type alone may not fully explain customer retention.


-- ============================================
-- 8. SUBSCRIPTIONS BY TIER AND BILLING INTERVAL
-- ============================================

SELECT
    p.tier,
    p.billing_interval,
    COUNT(*) AS subscriptions,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS subscription_pct
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
GROUP BY
    p.tier,
    p.billing_interval
ORDER BY subscriptions DESC;

-- RESULT:
-- Subscription volume is broadly balanced across tiers and billing intervals.
-- Enterprise Monthly has the largest share at 13.60%.
-- Business Annual has the smallest share at 11.98%.
-- Monthly and annual paid plans both show meaningful adoption,
-- suggesting no single billing interval dominates the customer base.


-- ============================================
-- 9. INVOICE STATUS DISTRIBUTION
-- ============================================

SELECT
    status,
    COUNT(*) AS invoices,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS invoice_pct
FROM invoices
GROUP BY status
ORDER BY invoices DESC;

-- RESULT:
-- Paid invoices represent 88.01% of all invoice records.
-- Failed invoices account for 6.98%.
-- Refunded invoices account for 2.96%.
-- Open invoices represent 2.05%.
-- Most invoice activity is successfully paid, but failed and refunded
-- invoices remain meaningful for later revenue and churn analysis.


-- ============================================
-- 10. SAFE REVENUE / PAYMENT SNAPSHOT
-- ============================================

WITH deduplicated_invoices AS (
    SELECT DISTINCT
        subscription_id,
        issued_on,
        period_start,
        period_end,
        amount,
        status,
        paid_on
    FROM invoices
)
SELECT
    ROUND(SUM(amount) FILTER (
        WHERE status = 'paid'
    ), 2) AS paid_invoice_value,
    ROUND(SUM(amount) FILTER (
        WHERE status = 'refunded'
    ), 2) AS refunded_invoice_value,
    ROUND(SUM(amount) FILTER (
        WHERE status = 'failed'
    ), 2) AS failed_invoice_value,
 ROUND(SUM(amount) FILTER (
        WHERE status = 'open'
    ), 2) AS open_invoice_value
FROM deduplicated_invoices;-- ============================================
-- 10. SAFE REVENUE / PAYMENT SNAPSHOT
-- ============================================

WITH deduplicated_invoices AS (
    SELECT DISTINCT
        subscription_id,
        issued_on,
        period_start,
        period_end,
        amount,
        status,
        paid_on
    FROM invoices
)
SELECT
    ROUND(SUM(amount) FILTER (
        WHERE status = 'paid'
    ), 2) AS paid_invoice_value,
    ROUND(SUM(amount) FILTER (
        WHERE status = 'refunded'
    ), 2) AS refunded_invoice_value,
    ROUND(SUM(amount) FILTER (
        WHERE status = 'failed'
    ), 2) AS failed_invoice_value,
 ROUND(SUM(amount) FILTER (
        WHERE status = 'open'
    ), 2) AS open_invoice_value
FROM deduplicated_invoices;

-- RESULT:
-- Exact-deduplicated paid invoice value: $29,313,100.00
-- Refunded invoice value: $926,807.00
-- Failed invoice value: $2,280,147.00
-- Open invoice value: $695,976.00
--
-- Paid invoice value represents the largest portion of billing activity.
-- Failed and refunded invoice values are significant enough to investigate
-- further in the business and retention analysis.


-- ============================================
-- 11. USAGE EVENT DISTRIBUTION BY EVENT TYPE
-- ============================================

SELECT
    event_type,
    COUNT(*) AS events,
    SUM(quantity) AS total_quantity,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS event_pct
FROM usage_events
GROUP BY event_type
ORDER BY events DESC;

-- RESULT:
-- report_run is the most common usage event with 50,593 events (28.11%).
-- dashboard_view is second with 43,236 events (24.02%).
-- Together, report_run and dashboard_view account for more than half
-- of all recorded usage events.
-- export and api_call are also major product activities.
-- alert_fired is the least common event type at 5.98%.


-- ============================================
-- 12. MONTHLY ORGANIZATION SIGNUP TREND
-- ============================================

SELECT
    DATE_TRUNC('month', signed_up_on)::date AS signup_month,
    COUNT(*) AS new_organizations
FROM organizations
GROUP BY DATE_TRUNC('month', signed_up_on)
ORDER BY signup_month;

-- RESULT:
-- Monthly organization signups remain relatively stable across 2023-2025.
-- Most months recorded roughly 70-100 new organizations.
-- November 2025 had the highest signup count with 112 organizations.
-- February 2025 had the lowest signup count with 64 organizations.
-- Overall, customer acquisition appears steady rather than highly seasonal.



-- ============================================
-- EXPLORATORY ANALYSIS SUMMARY
-- ============================================

-- The SaaS business contains 3,000 organizations, 26,000 users,
-- and 4,200 subscription records.
--
-- Of the 4,200 subscriptions, 2,010 are active and 2,190 have ended.
--
-- Software is the largest customer industry, representing 21.53%
-- of organizations, followed by retail at 13.57%.
--
-- The United States is the largest geographic market with 18.50%
-- of organizations, followed by Great Britain at 11.53%.
--
-- Small and mid-sized organizations dominate the customer base.
-- Organizations with 50 or fewer employees represent 58.70%
-- of all organizations.
--
-- Organic is the largest acquisition channel at 25.30%.
-- However, 17.60% of organizations have a blank acquisition channel,
-- which should be considered in later channel-performance analysis.
--
-- Subscription volume is broadly distributed across plans.
-- Enterprise has the highest subscription share at 13.60%,
-- while Business Annual has the lowest at 11.98%.
--
-- Ended-subscription rates are relatively similar across plans.
-- Starter Annual has the highest ended rate at 55.66%,
-- while Business Annual has the lowest at 48.91%.
--
-- Paid invoices represent 88.01% of invoice records.
-- After exact invoice deduplication, paid invoice value totals
-- approximately $29.31 million.
--
-- Failed invoice value is approximately $2.28 million,
-- refunded invoice value is approximately $926.81 thousand,
-- and open invoice value is approximately $695.98 thousand.
--
-- Product usage is concentrated in report_run and dashboard_view events,
-- which together represent more than half of recorded usage activity.
--
-- Monthly organization signups remain relatively stable from 2023-2025,
-- generally ranging between about 70 and 100 new organizations per month.
-- November 2025 recorded the highest signup count with 112 organizations.
--
-- Overall, the exploratory analysis shows a diversified SaaS customer base,
-- balanced plan adoption, steady customer acquisition, substantial paid
-- billing activity, and several areas requiring deeper business analysis,
-- especially retention, churn, billing performance, and product usage.