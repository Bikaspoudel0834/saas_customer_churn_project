-- ============================================
-- PROJECT 2: SAAS CUSTOMER CHURN & REVENUE ANALYSIS
-- FILE: 02_data_quality.sql
-- PURPOSE: IDENTIFY DATA QUALITY ISSUES BEFORE ANALYSIS
-- ============================================

-- ============================================
-- 1. DUPLICATE PRIMARY KEY CHECK
-- ============================================

SELECT 'plans' AS table_name,
       COUNT(*) AS total_rows,
       COUNT(DISTINCT plan_id) AS unique_ids
FROM plans

UNION ALL

SELECT 'organizations',
       COUNT(*),
       COUNT(DISTINCT organization_id)
FROM organizations

UNION ALL

SELECT 'users',
       COUNT(*),
       COUNT(DISTINCT user_id)
FROM users

UNION ALL

SELECT 'subscriptions',
       COUNT(*),
       COUNT(DISTINCT subscription_id)
FROM subscriptions

UNION ALL

SELECT 'invoices',
       COUNT(*),
       COUNT(DISTINCT invoice_id)
FROM invoices

UNION ALL

SELECT 'usage_events',
       COUNT(*),
       COUNT(DISTINCT event_id)
FROM usage_events;

-- RESULT:
-- No duplicate primary keys found.
-- total_rows matched unique_ids in all six tables.

-- ============================================
-- 2. REQUIRED NULL VALUE CHECK
-- ============================================

SELECT
    'plans' AS table_name,
    COUNT(*) FILTER (
        WHERE plan_id IS NULL
           OR plan_name IS NULL
           OR tier IS NULL
           OR monthly_price IS NULL
           OR seat_price IS NULL
           OR billing_interval IS NULL
           OR is_active IS NULL
    ) AS rows_with_missing_required_fields
FROM plans
UNION ALL
SELECT
    'organizations',
    COUNT(*) FILTER (
        WHERE organization_id IS NULL
           OR org_name IS NULL
           OR industry IS NULL
           OR country IS NULL
           OR employee_band IS NULL
           OR signed_up_on IS NULL
    )
FROM organizations
UNION ALL
SELECT
    'users',
    COUNT(*) FILTER (
        WHERE user_id IS NULL
           OR organization_id IS NULL
           OR email IS NULL
           OR role IS NULL
           OR joined_on IS NULL
    )
FROM users
UNION ALL
SELECT
    'subscriptions',
    COUNT(*) FILTER (
        WHERE subscription_id IS NULL
           OR organization_id IS NULL
           OR plan_id IS NULL
           OR started_on IS NULL
           OR seats IS NULL
    )
FROM subscriptions
UNION ALL
SELECT
    'invoices',
    COUNT(*) FILTER (
        WHERE invoice_id IS NULL
           OR subscription_id IS NULL
           OR issued_on IS NULL
           OR period_start IS NULL
           OR period_end IS NULL
           OR amount IS NULL
           OR status IS NULL
    )
FROM invoices
UNION all 
SELECT
    'usage_events',
    COUNT(*) FILTER (
        WHERE event_id IS NULL
           OR organization_id IS NULL
           OR occurred_at IS NULL
           OR event_type IS NULL
           OR quantity IS NULL
    )
FROM usage_events;

-- RESULT:
-- No missing values were found in required fields across all six tables.
-- ============================================
-- 3. INTENTIONAL NULL VALUE CHECK
-- ============================================

SELECT
    COUNT(*) FILTER (
        WHERE acquisition_channel IS NULL
    ) AS missing_acquisition_channel
FROM organizations;

SELECT
    COUNT(*) FILTER (
        WHERE deactivated_on IS NULL
    ) AS active_users_without_deactivation_date
FROM users;

SELECT
    COUNT(*) FILTER (
        WHERE ended_on IS NULL
    ) AS active_subscriptions,
    COUNT(*) FILTER (
        WHERE cancel_reason IS NULL
    ) AS subscriptions_without_cancel_reason
FROM subscriptions;

SELECT
    COUNT(*) FILTER (
        WHERE paid_on IS NULL
    ) AS invoices_without_payment_date
FROM invoices;

SELECT
    COUNT(*) FILTER (
        WHERE user_id IS NULL
    ) AS events_without_user_id
FROM usage_events;

-- RESULT:
-- acquisition_channel: 0 NULL values.
-- deactivated_on: 22,437 NULL values, representing users without a deactivation date.
-- ended_on: 2,010 NULL values, representing subscriptions without an end date.
-- cancel_reason: 0 NULL values.
-- paid_on: 5,514 NULL values.
-- user_id in usage_events: 25,211 NULL values.
--
-- These nullable fields require business-context validation before being treated
-- as data-quality problems.

-- ============================================
-- 4. ORPHAN FOREIGN KEY CHECK
-- ============================================

SELECT
    'users.organization_id' AS relationship,
    COUNT(*) AS orphan_records
FROM users u
LEFT JOIN organizations o
    ON u.organization_id = o.organization_id
WHERE o.organization_id IS NULL
UNION ALL
SELECT
    'subscriptions.organization_id',
    COUNT(*)
FROM subscriptions s
LEFT JOIN organizations o
    ON s.organization_id = o.organization_id
WHERE o.organization_id IS NULL
UNION ALL
SELECT
    'subscriptions.plan_id',
    COUNT(*)
FROM subscriptions s
LEFT JOIN plans p
    ON s.plan_id = p.plan_id
WHERE p.plan_id IS NULL
UNION ALL
SELECT
    'invoices.subscription_id',
    COUNT(*)
FROM invoices i
LEFT JOIN subscriptions s
    ON i.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL
UNION ALL
SELECT
    'usage_events.organization_id',
    COUNT(*)
FROM usage_events ue
LEFT JOIN organizations o
    ON ue.organization_id = o.organization_id
WHERE o.organization_id IS NULL
UNION ALL
SELECT
    'usage_events.user_id',
    COUNT(*)
FROM usage_events ue
LEFT JOIN users u
    ON ue.user_id = u.user_id
WHERE ue.user_id IS NOT NULL
  AND u.user_id IS NULL;

-- RESULT:
-- No orphan foreign keys were found.
-- All users reference valid organizations.
-- All subscriptions reference valid organizations and plans.
-- All invoices reference valid subscriptions.
-- All usage events reference valid organizations.
-- All non-NULL usage_events.user_id values reference valid users.


-- ============================================
-- 5. INVALID DATE RELATIONSHIP CHECK
-- ============================================

SELECT
    'users: deactivated_on before joined_on' AS issue,
    COUNT(*) AS issue_count
FROM users
WHERE deactivated_on IS NOT NULL
  AND deactivated_on < joined_on
UNION ALL
SELECT
    'subscriptions: ended_on before started_on',
    COUNT(*)
FROM subscriptions
WHERE ended_on IS NOT NULL
  AND ended_on < started_on
UNION ALL
SELECT
    'invoices: period_end before period_start',
    COUNT(*)
FROM invoices
WHERE period_end < period_start
UNION ALL
SELECT
    'invoices: paid_on before issued_on',
    COUNT(*)
FROM invoices
WHERE paid_on IS NOT NULL
  AND paid_on < issued_on;

  -- RESULT:
-- 2 users have deactivated_on dates earlier than their joined_on dates.
-- 23 subscriptions have ended_on dates earlier than their started_on dates.
-- 0 invoices have period_end dates earlier than period_start.
-- 0 invoices have paid_on dates earlier than issued_on.
--
-- The 25 invalid user/subscription date records should be documented
-- and handled carefully in later analysis rather than automatically deleted.

-- ============================================
-- 6. INVALID NUMERIC / BUSINESS VALUE CHECK
-- ============================================

SELECT
    'plans: negative monthly_price' AS issue,
    COUNT(*) AS issue_count
FROM plans
WHERE monthly_price < 0
UNION ALL
SELECT
    'plans: negative seat_price',
    COUNT(*)
FROM plans
WHERE seat_price < 0
UNION ALL
SELECT
    'subscriptions: seats <= 0',
    COUNT(*)
FROM subscriptions
WHERE seats <= 0
UNION ALL
SELECT
    'invoices: negative amount',
    COUNT(*)
FROM invoices
WHERE amount < 0
UNION ALL
SELECT
    'usage_events: quantity <= 0',
    COUNT(*)
FROM usage_events
WHERE quantity <= 0;

-- RESULT:
-- No invalid numeric values were found.
-- All plan prices are non-negative.
-- All subscriptions have more than 0 seats.
-- All invoice amounts are non-negative.
-- All usage-event quantities are greater than 0.


-- ============================================
-- 7. SUBSCRIPTION STATUS CONSISTENCY CHECK
-- ============================================

SELECT
    'active subscription with cancel_reason' AS issue,
    COUNT(*) AS issue_count
FROM subscriptions
WHERE ended_on IS NULL
  AND cancel_reason IS NOT NULL
UNION ALL
SELECT
    'ended subscription without cancel_reason',
    COUNT(*)
FROM subscriptions
WHERE ended_on IS NOT NULL
  AND cancel_reason IS NULL;

-- RESULT:
-- 2,010 active subscriptions contain a non-NULL cancel_reason value.
-- 0 ended subscriptions are missing a cancel_reason.
--
-- This requires further inspection because active subscriptions may use
-- a placeholder value rather than NULL for cancel_reason.


-- ============================================
-- 8. CANCEL REASON VALUE INSPECTION
-- ============================================

SELECT
    cancel_reason,
    COUNT(*) AS subscription_count
FROM subscriptions
GROUP BY cancel_reason
ORDER BY subscription_count DESC;

-- RESULT:
-- 2,010 subscriptions have a blank cancel_reason value.
-- These correspond to active subscriptions without an end date.
--
-- Ended subscriptions contain actual cancellation reasons:
-- price: 596
-- missing_features: 519
-- no_longer_needed: 421
-- switched_vendor: 416
-- non_payment: 238
--
-- The dataset uses blank strings rather than NULL values
-- to represent subscriptions that have not been cancelled.


-- ============================================
-- 9. BLANK / EMPTY TEXT VALUE CHECK
-- ============================================

SELECT
    'plans.plan_name' AS column_name,
    COUNT(*) AS blank_count
FROM plans
WHERE TRIM(plan_name) = ''
UNION ALL
SELECT
    'plans.tier',
    COUNT(*)
FROM plans
WHERE TRIM(tier) = ''
UNION ALL
SELECT
    'organizations.org_name',
    COUNT(*)
FROM organizations
WHERE TRIM(org_name) = ''
UNION ALL
SELECT
    'organizations.industry',
    COUNT(*)
FROM organizations
WHERE TRIM(industry) = ''
UNION ALL
SELECT
    'organizations.country',
    COUNT(*)
FROM organizations
WHERE TRIM(country) = ''
UNION all
SELECT
    'users.email',
    COUNT(*)
FROM users
WHERE TRIM(email) = ''
UNION ALL
SELECT
    'users.role',
    COUNT(*)
FROM users
WHERE TRIM(role) = ''
UNION ALL
SELECT
    'invoices.status',
    COUNT(*)
FROM invoices
WHERE TRIM(status) = ''
UNION ALL
SELECT
    'usage_events.event_type',
    COUNT(*)
FROM usage_events
WHERE TRIM(event_type) = '';

-- RESULT:
-- No blank or empty values were found in the required text fields checked.
-- plan_name, tier, org_name, industry, country, email, role,
-- invoice status, and usage event type all contain populated values.

-- ============================================
-- 10. DUPLICATE BUSINESS RECORD CHECK
-- ============================================

SELECT
    'users: duplicate email' AS issue,
    COUNT(*) AS duplicate_groups
FROM (
    SELECT email
    FROM users
    GROUP BY email
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT
    'organizations: duplicate org_name',
    COUNT(*)
FROM (
    SELECT org_name
    FROM organizations
    GROUP BY org_name
    HAVING COUNT(*) > 1
) x
UNION ALL
SELECT
    'subscriptions: duplicate org-plan-start combination',
    COUNT(*)
FROM (
    SELECT organization_id, plan_id, started_on
    FROM subscriptions
    GROUP BY organization_id, plan_id, started_on
    HAVING COUNT(*) > 1
) x
UNION all
SELECT
    'invoices: duplicate subscription-period combination',
    COUNT(*)
FROM (
    SELECT subscription_id, period_start, period_end
    FROM invoices
    GROUP BY subscription_id, period_start, period_end
    HAVING COUNT(*) > 1
) x;

-- RESULT:
-- 0 duplicate user email groups.
-- 0 duplicate organization name groups.
-- 0 duplicate subscription-plan-start groups.
-- 20,959 subscription-period combinations contain multiple invoices.
--
-- The invoice duplicates require further investigation before being classified
-- as data-quality issues because multiple invoices may represent billing retries,
-- payment status changes, or other legitimate billing activity.


-- ============================================
-- 11. REPEATED INVOICE PERIOD INSPECTION
-- ============================================

SELECT
    subscription_id,
    period_start,
    period_end,
    COUNT(*) AS invoice_count,
    COUNT(DISTINCT status) AS distinct_statuses,
    COUNT(DISTINCT amount) AS distinct_amounts
FROM invoices
GROUP BY
    subscription_id,
    period_start,
    period_end
HAVING COUNT(*) > 1
ORDER BY invoice_count DESC
LIMIT 20;

-- RESULT:
-- Repeated subscription-period combinations contain up to 3 invoices
-- for the same billing period.
-- The invoice amount remains the same within the sampled groups.
-- Some groups contain multiple invoice statuses, suggesting possible
-- billing retries or payment-status changes.
--
-- These records should not be removed as duplicates without further inspection.


-- ============================================
-- 12. REPEATED INVOICE RECORD DETAIL CHECK
-- ============================================

WITH repeated_periods AS (
    SELECT
        subscription_id,
        period_start,
        period_end,
        COUNT(*) AS invoice_count
    FROM invoices
    GROUP BY
        subscription_id,
        period_start,
        period_end
    HAVING COUNT(*) > 1
)
SELECT
    i.invoice_id,
    i.subscription_id,
    i.issued_on,
    i.period_start,
    i.period_end,
    i.amount,
    i.status,
    i.paid_on
FROM invoices i
JOIN repeated_periods r
    ON i.subscription_id = r.subscription_id
   AND i.period_start = r.period_start
   AND i.period_end = r.period_end
ORDER BY
    r.invoice_count DESC,
    i.subscription_id,
    i.period_start,
    i.issued_on
LIMIT 40;

-- RESULT:
-- Repeated billing periods contain multiple invoice records for the same
-- subscription, billing period, amount, and issue date.
--
-- Some repeated periods contain a mix of paid, failed, and open statuses,
-- while others contain multiple paid invoices for the same billing period.
--
-- Because summing all invoice rows could overstate revenue, invoice records
-- must be deduplicated or otherwise handled using business rules before
-- calculating revenue-related KPIs.


-- ============================================
-- 13. MULTIPLE PAID INVOICES PER BILLING PERIOD
-- ============================================

WITH period_summary AS (
    SELECT
        subscription_id,
        period_start,
        period_end,
        COUNT(*) AS total_invoices,
        COUNT(*) FILTER (
            WHERE status = 'paid'
        ) AS paid_invoices
    FROM invoices
    GROUP BY
        subscription_id,
        period_start,
        period_end
)
SELECT
    COUNT(*) FILTER (
        WHERE total_invoices > 1
    ) AS repeated_periods,
COUNT(*) FILTER (
        WHERE total_invoices > 1
          AND paid_invoices > 1
    ) AS repeated_periods_with_multiple_paid_invoices,
    COUNT(*) FILTER (
        WHERE total_invoices > 1
          AND paid_invoices = 1
    ) AS repeated_periods_with_one_paid_invoice,
  COUNT(*) FILTER (
        WHERE total_invoices > 1
          AND paid_invoices = 0
    ) AS repeated_periods_with_no_paid_invoice
FROM period_summary;

-- RESULT:
-- 20,959 billing periods contain more than one invoice record.
-- 16,978 repeated billing periods contain multiple paid invoices.
-- 3,724 repeated billing periods contain exactly one paid invoice.
-- 257 repeated billing periods contain no paid invoice.
--
-- Multiple paid invoices for the same billing period create a significant
-- risk of overstating revenue if invoice rows are summed directly.
-- Revenue calculations will require a deduplication/business-rule strategy.


-- ============================================
-- 14. EXACT DUPLICATE INVOICE RECORD CHECK
-- ============================================

SELECT
    COUNT(*) AS exact_duplicate_groups
FROM (
    SELECT
        subscription_id,
        issued_on,
        period_start,
        period_end,
        amount,
        status,
        paid_on
    FROM invoices
    GROUP BY
        subscription_id,
        issued_on,
        period_start,
        period_end,
        amount,
        status,
        paid_on
    HAVING COUNT(*) > 1
) x;

-- RESULT:
-- 1,213 groups of exact duplicate invoice records were found.
--
-- These groups match on subscription_id, issued_on, period_start,
-- period_end, amount, status, and paid_on.
--
-- Exact duplicate invoice rows should be excluded from revenue analysis
-- to avoid double-counting the same billing event.


-- ============================================
-- 15. INVOICE ROW COUNT AFTER EXACT DEDUPLICATION
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
    (SELECT COUNT(*) FROM invoices) AS original_invoice_rows,
    COUNT(*) AS rows_after_exact_deduplication,
    (SELECT COUNT(*) FROM invoices) - COUNT(*) AS duplicate_rows_removed
FROM deduplicated_invoices;

-- RESULT:
-- Original invoice rows: 46,000.
-- Rows after exact deduplication: 44,777.
-- Exact duplicate rows removed: 1,223.
--
-- This confirms that exact duplicate invoice records materially affect
-- the dataset and should be excluded from revenue calculations.


-- ============================================
-- 16. INVOICE STATUS VS PAYMENT DATE CONSISTENCY
-- ============================================

SELECT
    'paid invoice without paid_on date' AS issue,
    COUNT(*) AS issue_count
FROM invoices
WHERE status = 'paid'
  AND paid_on IS NULL
UNION ALL
SELECT
    'non-paid invoice with paid_on date',
    COUNT(*)
FROM invoices
WHERE status <> 'paid'
  AND paid_on IS NOT NULL;

  -- RESULT:
-- 0 paid invoices are missing a paid_on date.
-- 0 non-paid invoices contain a paid_on date.
--
-- Invoice payment dates are consistent with invoice status.



-- ============================================
-- 17. CROSS-TABLE TIMELINE CONSISTENCY CHECK
-- ============================================

SELECT
    'subscriptions started before organization signup' AS issue,
    COUNT(*) AS issue_count
FROM subscriptions s
JOIN organizations o
    ON s.organization_id = o.organization_id
WHERE s.started_on < o.signed_up_on
UNION ALL
SELECT
    'users joined before organization signup',
    COUNT(*)
FROM users u
JOIN organizations o
    ON u.organization_id = o.organization_id
WHERE u.joined_on < o.signed_up_on
UNION ALL
SELECT
    'usage events before organization signup',
    COUNT(*)
FROM usage_events ue
JOIN organizations o
    ON ue.organization_id = o.organization_id
WHERE ue.occurred_at::date < o.signed_up_on
UNION ALL
SELECT
    'usage events before user joined',
    COUNT(*)
FROM usage_events ue
JOIN users u
    ON ue.user_id = u.user_id
WHERE ue.user_id IS NOT NULL
  AND ue.occurred_at::date < u.joined_on;

-- RESULT:
-- 0 subscriptions started before the organization signup date.
-- 0 users joined before the organization signup date.
-- 88,610 usage events occurred before the organization's signup date.
-- 115,958 usage events occurred before the associated user's joined_on date.
--
-- The large number of pre-signup and pre-join usage events indicates a major
-- timeline inconsistency in the usage_events table.
-- These records should not automatically be removed until their date patterns
-- are inspected and an analysis rule is established.


-- ============================================
-- 18. USAGE TIMELINE ANOMALY PROFILE
-- ============================================

SELECT
    'before organization signup' AS anomaly_type,
    COUNT(*) AS anomaly_count,
    MIN(o.signed_up_on - ue.occurred_at::date) AS minimum_days_early,
    MAX(o.signed_up_on - ue.occurred_at::date) AS maximum_days_early,
    ROUND(
        AVG((o.signed_up_on - ue.occurred_at::date)::NUMERIC),
        2
    ) AS average_days_early
FROM usage_events ue
JOIN organizations o
    ON ue.organization_id = o.organization_id
WHERE ue.occurred_at::date < o.signed_up_on
UNION ALL
SELECT
    'before user joined',
    COUNT(*),
    MIN(u.joined_on - ue.occurred_at::date),
    MAX(u.joined_on - ue.occurred_at::date),
    ROUND(
        AVG((u.joined_on - ue.occurred_at::date)::NUMERIC),
        2
    )
FROM usage_events ue
JOIN users u
    ON ue.user_id = u.user_id
WHERE ue.user_id IS NOT NULL
  AND ue.occurred_at::date < u.joined_on;

-- RESULT:
-- 115,958 usage events occurred before the associated user's joined_on date.
-- These events occurred between 1 and 1,095 days early,
-- with an average of 447.73 days before the user joined.
--
-- 88,610 usage events occurred before the organization's signed_up_on date.
-- These events occurred between 1 and 1,094 days early,
-- with an average of 366.93 days before organization signup.
--
-- The scale and magnitude of these inconsistencies indicate that the
-- usage_events timeline cannot be assumed to be fully reliable.


-- ============================================
-- FINAL DATA QUALITY HANDLING RULES
-- ============================================

-- 1. Primary keys are unique across all six tables.
-- 2. Required fields contain no NULL values.
-- 3. Blank cancel_reason values represent active subscriptions.
-- 4. No orphan foreign-key relationships were found.
-- 5. 2 user records and 23 subscription records contain invalid date sequences.
--    These records will be excluded only from analyses where date validity matters.
-- 6. Numeric business fields contain no invalid negative or zero values
--    in the checks performed.
-- 7. Invoice data contains repeated billing periods and exact duplicate rows.
--    Revenue calculations must not blindly sum all invoice records.
-- 8. Exact duplicate invoice rows will be excluded from revenue-related analysis.
-- 9. Billing-period duplicates will be handled using explicit business rules
--    before calculating MRR, ARR, collected revenue, or payment KPIs.
-- 10. usage_events contains major timeline inconsistencies.
--     Usage-based analysis will exclude events occurring before the associated
--     organization signup date or user join date when those dates are required.
-- 11. Raw records will remain unchanged. Data-quality issues will be documented
--     and handled within analysis queries rather than permanently deleted.
