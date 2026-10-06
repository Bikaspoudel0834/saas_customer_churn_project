-- SaaS Subscriptions
--
-- Organizations, plans, subscription intervals, invoices and product usage for a B2B SaaS business.
--
-- Run this from the directory holding the data files:
--   duckdb -c ".read saas_subscriptions.schema.sql"

CREATE TABLE plans (
  plan_id INTEGER NOT NULL,
  plan_name VARCHAR NOT NULL,
  tier VARCHAR NOT NULL,
  monthly_price DECIMAL(12,2) NOT NULL,
  seat_price DECIMAL(12,2) NOT NULL,
  billing_interval VARCHAR NOT NULL,
  is_active BOOLEAN NOT NULL,
  PRIMARY KEY (plan_id)
);

CREATE TABLE organizations (
  organization_id INTEGER NOT NULL,
  org_name VARCHAR NOT NULL,
  industry VARCHAR NOT NULL,
  country VARCHAR NOT NULL,
  employee_band VARCHAR NOT NULL,
  signed_up_on DATE NOT NULL,
  acquisition_channel VARCHAR,
  PRIMARY KEY (organization_id)
);

CREATE TABLE users (
  user_id INTEGER NOT NULL,
  organization_id INTEGER NOT NULL,
  email VARCHAR NOT NULL,
  role VARCHAR NOT NULL,
  joined_on DATE NOT NULL,
  deactivated_on DATE,
  PRIMARY KEY (user_id),
  FOREIGN KEY (organization_id) REFERENCES organizations (organization_id)
);

CREATE TABLE subscriptions (
  subscription_id INTEGER NOT NULL,
  organization_id INTEGER NOT NULL,
  plan_id INTEGER NOT NULL,
  started_on DATE NOT NULL,
  ended_on DATE,
  seats INTEGER NOT NULL,
  cancel_reason VARCHAR,
  PRIMARY KEY (subscription_id),
  FOREIGN KEY (organization_id) REFERENCES organizations (organization_id),
  FOREIGN KEY (plan_id) REFERENCES plans (plan_id)
);

CREATE TABLE invoices (
  invoice_id INTEGER NOT NULL,
  subscription_id INTEGER NOT NULL,
  issued_on DATE NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  status VARCHAR NOT NULL,
  paid_on DATE,
  PRIMARY KEY (invoice_id),
  FOREIGN KEY (subscription_id) REFERENCES subscriptions (subscription_id)
);

CREATE TABLE usage_events (
  event_id INTEGER NOT NULL,
  organization_id INTEGER NOT NULL,
  user_id INTEGER,
  occurred_at TIMESTAMP NOT NULL,
  event_type VARCHAR NOT NULL,
  quantity INTEGER NOT NULL,
  PRIMARY KEY (event_id),
  FOREIGN KEY (organization_id) REFERENCES organizations (organization_id),
  FOREIGN KEY (user_id) REFERENCES users (user_id)
);

COPY plans FROM 'plans.parquet' (FORMAT PARQUET);
COPY organizations FROM 'organizations.parquet' (FORMAT PARQUET);
COPY users FROM 'users.parquet' (FORMAT PARQUET);
COPY subscriptions FROM 'subscriptions.parquet' (FORMAT PARQUET);
COPY invoices FROM 'invoices.parquet' (FORMAT PARQUET);
COPY usage_events FROM 'usage_events.parquet' (FORMAT PARQUET);
