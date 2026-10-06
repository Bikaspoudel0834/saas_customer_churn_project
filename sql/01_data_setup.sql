-- ============================================
-- PROJECT 2: SAAS CUSTOMER CHURN & REVENUE ANALYSIS
-- FILE: 01_data_setup.sql
-- PURPOSE: CREATE CORE TABLES AND RELATIONSHIPS
-- ============================================


CREATE TABLE plans (
    plan_id INTEGER PRIMARY KEY,
    plan_name VARCHAR NOT NULL,
    tier VARCHAR NOT NULL,
    monthly_price NUMERIC(12,2) NOT NULL,
    seat_price NUMERIC(12,2) NOT NULL,
    billing_interval VARCHAR NOT NULL,
    is_active BOOLEAN NOT NULL
);

CREATE TABLE organizations (
    organization_id INTEGER PRIMARY KEY,
    org_name VARCHAR NOT NULL,
    industry VARCHAR NOT NULL,
    country VARCHAR NOT NULL,
    employee_band VARCHAR NOT NULL,
    signed_up_on DATE NOT NULL,
    acquisition_channel VARCHAR
);

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    email VARCHAR NOT NULL,
    role VARCHAR NOT NULL,
    joined_on DATE NOT NULL,
    deactivated_on DATE,
    FOREIGN KEY (organization_id)
        REFERENCES organizations(organization_id)
);

CREATE TABLE subscriptions (
    subscription_id INTEGER PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    plan_id INTEGER NOT NULL,
    started_on DATE NOT NULL,
    ended_on DATE,
    seats INTEGER NOT NULL,
    cancel_reason VARCHAR,
    FOREIGN KEY (organization_id)
        REFERENCES organizations(organization_id),
    FOREIGN KEY (plan_id)
        REFERENCES plans(plan_id)
);

CREATE TABLE invoices (
    invoice_id INTEGER PRIMARY KEY,
    subscription_id INTEGER NOT NULL,
    issued_on DATE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    status VARCHAR NOT NULL,
    paid_on DATE,
    FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id)
);

CREATE TABLE usage_events (
    event_id INTEGER PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    user_id INTEGER,
    occurred_at TIMESTAMP NOT NULL,
    event_type VARCHAR NOT NULL,
    quantity INTEGER NOT NULL,
    FOREIGN KEY (organization_id)
        REFERENCES organizations(organization_id),
    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);
