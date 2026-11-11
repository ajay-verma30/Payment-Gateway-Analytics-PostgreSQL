-- =====================================================================
-- Payments platform schema (PostgreSQL), 31 tables
-- Modeled on the PUBLIC data models of Stripe (API objects, webhooks,
-- balance transactions) and Adyen (payment events, settlement detail
-- reports, notifications). Internal/proprietary tables are not public.
-- Conventions: amounts are BIGINT in minor units (cents/paise);
-- timestamps are TIMESTAMPTZ (UTC); IDs are text with Stripe-style prefixes.
-- Card data: only BIN, last4, expiry, fingerprint (never PAN/CVC: PCI-DSS).
-- =====================================================================

-- ---------- 1. REFERENCE ----------
CREATE TABLE currencies (
  code            char(3) PRIMARY KEY,
  name            text NOT NULL,
  minor_unit      smallint NOT NULL              -- 2 for USD/EUR/INR, 0 for JPY
);

CREATE TABLE fx_rates (
  rate_date       date NOT NULL,
  from_currency   char(3) NOT NULL REFERENCES currencies(code),
  to_currency     char(3) NOT NULL REFERENCES currencies(code),
  rate            numeric(18,8) NOT NULL,
  PRIMARY KEY (rate_date, from_currency, to_currency)
);

CREATE TABLE decline_codes (
  decline_code          text PRIMARY KEY,        -- insufficient_funds, do_not_honor, ...
  category              text NOT NULL CHECK (category IN ('soft','hard','fraud','issuer','technical')),
  description           text NOT NULL,
  network_response_code text,                    -- ISO 8583 style, e.g. 51, 05
  retryable             boolean NOT NULL
);

CREATE TABLE card_bins (
  bin             char(6) PRIMARY KEY,
  brand           text NOT NULL,                 -- visa, mastercard, amex, rupay, ...
  funding         text NOT NULL CHECK (funding IN ('credit','debit','prepaid')),
  card_category   text NOT NULL CHECK (card_category IN ('consumer','commercial')),
  issuer_name     text NOT NULL,
  issuer_country  char(2) NOT NULL
);

-- ---------- 2. MERCHANT / ACCOUNT ----------
CREATE TABLE merchants (
  merchant_id          text PRIMARY KEY,         -- acct_...
  legal_name           text NOT NULL,
  display_name         text NOT NULL,
  business_type        text NOT NULL CHECK (business_type IN ('individual','company','non_profit')),
  mcc                  char(4) NOT NULL,
  country              char(2) NOT NULL,
  default_currency     char(3) NOT NULL REFERENCES currencies(code),
  website_url          text,
  support_email        text,
  status               text NOT NULL CHECK (status IN ('pending','active','restricted','closed')),
  risk_tier            text NOT NULL CHECK (risk_tier IN ('low','medium','high')),
  pricing_model        text NOT NULL CHECK (pricing_model IN ('blended','interchange_plus')),
  blended_rate_bps     integer,                  -- e.g. 290 = 2.90%
  fixed_fee_minor      integer,                  -- e.g. 30 = 0.30
  payout_schedule      text NOT NULL CHECK (payout_schedule IN ('daily','weekly','monthly','manual')),
  settlement_delay_days smallint NOT NULL,
  created_at           timestamptz NOT NULL,
  kyc_verified_at      timestamptz,
  closed_at            timestamptz
);

CREATE TABLE stores (
  store_id        text PRIMARY KEY,
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  name            text NOT NULL,
  channel         text NOT NULL CHECK (channel IN ('ecommerce','pos','moto','subscription')),
  country         char(2) NOT NULL,
  status          text NOT NULL CHECK (status IN ('active','inactive','closed')),
  created_at      timestamptz NOT NULL
);

CREATE TABLE bank_accounts (
  bank_account_id    text PRIMARY KEY,           -- ba_...
  merchant_id        text NOT NULL REFERENCES merchants(merchant_id),
  account_holder_name text NOT NULL,
  bank_name          text NOT NULL,
  country            char(2) NOT NULL,
  currency           char(3) NOT NULL REFERENCES currencies(code),
  account_last4      char(4) NOT NULL,
  status             text NOT NULL CHECK (status IN ('new','verified','verification_failed','errored')),
  is_default         boolean NOT NULL,
  created_at         timestamptz NOT NULL
);

CREATE TABLE api_keys (
  api_key_id      text PRIMARY KEY,
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  key_type        text NOT NULL CHECK (key_type IN ('publishable','secret','restricted')),
  mode            text NOT NULL CHECK (mode IN ('live','test')),
  key_last4       char(4) NOT NULL,
  created_at      timestamptz NOT NULL,
  last_used_at    timestamptz,
  revoked_at      timestamptz
);

CREATE TABLE webhook_endpoints (
  endpoint_id     text PRIMARY KEY,              -- we_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  url             text NOT NULL,
  api_version     text NOT NULL,
  enabled_events  jsonb NOT NULL,                -- ["payment_intent.succeeded", ...]
  status          text NOT NULL CHECK (status IN ('enabled','disabled')),
  created_at      timestamptz NOT NULL,
  disabled_at     timestamptz
);

-- ---------- 3. CUSTOMERS ----------
CREATE TABLE customers (
  customer_id     text PRIMARY KEY,              -- cus_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  email           text,
  name            text,
  phone           text,
  country         char(2),
  currency        char(3) REFERENCES currencies(code),
  default_payment_method_id text,                -- soft ref to payment_methods
  metadata        jsonb,
  created_at      timestamptz NOT NULL,
  deleted_at      timestamptz
);

CREATE TABLE payment_methods (
  payment_method_id text PRIMARY KEY,            -- pm_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  customer_id     text REFERENCES customers(customer_id),
  type            text NOT NULL CHECK (type IN ('card','upi','sepa_debit','ach_debit','ideal','wallet','bnpl')),
  card_bin        char(6) REFERENCES card_bins(bin),
  card_brand      text,
  card_funding    text,
  card_last4      char(4),
  card_exp_month  smallint,
  card_exp_year   smallint,
  card_country    char(2),
  card_fingerprint text,                         -- same card across customers = same fingerprint
  wallet_type     text CHECK (wallet_type IN ('apple_pay','google_pay','samsung_pay')),
  bank_name       text,                          -- for bank-based methods
  created_at      timestamptz NOT NULL,
  detached_at     timestamptz
);

-- ---------- 4. PAYMENTS ----------
CREATE TABLE payment_intents (
  payment_intent_id text PRIMARY KEY,            -- pi_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  store_id        text REFERENCES stores(store_id),
  customer_id     text REFERENCES customers(customer_id),
  payment_method_id text REFERENCES payment_methods(payment_method_id),
  merchant_reference text NOT NULL,              -- Adyen merchantReference / order id
  amount          bigint NOT NULL,
  amount_received bigint NOT NULL DEFAULT 0,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  status          text NOT NULL CHECK (status IN ('requires_payment_method','requires_action',
                    'processing','requires_capture','succeeded','canceled')),
  capture_method  text NOT NULL CHECK (capture_method IN ('automatic','manual')),
  setup_future_usage text CHECK (setup_future_usage IN ('on_session','off_session')),
  description     text,
  statement_descriptor text,
  receipt_email   text,
  invoice_id      text,                          -- soft ref to invoices
  latest_charge_id text,                         -- soft ref to charges
  cancellation_reason text CHECK (cancellation_reason IN ('duplicate','fraudulent','requested_by_customer','abandoned')),
  idempotency_key text,
  created_at      timestamptz NOT NULL,
  canceled_at     timestamptz
);

CREATE TABLE charges (                            -- one row per payment ATTEMPT
  charge_id       text PRIMARY KEY,              -- ch_...
  payment_intent_id text NOT NULL REFERENCES payment_intents(payment_intent_id),
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  customer_id     text REFERENCES customers(customer_id),
  payment_method_id text REFERENCES payment_methods(payment_method_id),
  psp_reference   char(16) NOT NULL UNIQUE,      -- Adyen pspReference
  attempt_number  smallint NOT NULL DEFAULT 1,
  amount          bigint NOT NULL,
  amount_captured bigint NOT NULL DEFAULT 0,
  amount_refunded bigint NOT NULL DEFAULT 0,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  status          text NOT NULL CHECK (status IN ('succeeded','pending','failed')),
  paid            boolean NOT NULL,
  captured        boolean NOT NULL,
  refunded        boolean NOT NULL,
  disputed        boolean NOT NULL,
  failure_code    text REFERENCES decline_codes(decline_code),
  failure_message text,
  network_status  text CHECK (network_status IN ('approved_by_network','declined_by_network',
                    'not_sent_to_network','reversed_after_approval')),
  issuer_response_code text,
  authorization_code text,
  avs_check       text CHECK (avs_check IN ('pass','fail','unavailable','unchecked')),
  cvc_check       text CHECK (cvc_check IN ('pass','fail','unavailable','unchecked')),
  payment_method_type text NOT NULL,
  card_brand      text,
  card_funding    text,
  card_country    char(2),
  is_international boolean,
  three_ds_used   boolean NOT NULL DEFAULT false,
  risk_level      text CHECK (risk_level IN ('normal','elevated','highest','not_assessed')),
  risk_score      smallint,
  authorized_at   timestamptz,
  captured_at     timestamptz,
  created_at      timestamptz NOT NULL
);

CREATE TABLE payment_events (                     -- Adyen-style event log per PSP reference
  event_id        text PRIMARY KEY,
  charge_id       text NOT NULL REFERENCES charges(charge_id),
  payment_intent_id text NOT NULL REFERENCES payment_intents(payment_intent_id),
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  psp_reference   char(16) NOT NULL,             -- reference of THIS event
  original_reference char(16),                   -- the authorisation it modifies
  event_code      text NOT NULL CHECK (event_code IN ('AUTHORISATION','CAPTURE','CANCELLATION',
                    'REFUND','CHARGEBACK','CHARGEBACK_REVERSED','SECOND_CHARGEBACK','REFUND_FAILED')),
  success         boolean NOT NULL,
  amount          bigint NOT NULL,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  reason          text,
  event_date      timestamptz NOT NULL
);

CREATE TABLE authentications_3ds (
  authentication_id text PRIMARY KEY,
  charge_id       text NOT NULL REFERENCES charges(charge_id),
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  version         text NOT NULL CHECK (version IN ('1.0.2','2.1.0','2.2.0')),
  flow            text NOT NULL CHECK (flow IN ('frictionless','challenge')),
  result          text NOT NULL CHECK (result IN ('authenticated','attempt_acknowledged','failed','rejected','unavailable')),
  eci             char(2),
  challenge_completed boolean,
  liability_shift boolean NOT NULL,
  created_at      timestamptz NOT NULL
);

CREATE TABLE refunds (
  refund_id       text PRIMARY KEY,              -- re_...
  charge_id       text NOT NULL REFERENCES charges(charge_id),
  payment_intent_id text NOT NULL REFERENCES payment_intents(payment_intent_id),
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  amount          bigint NOT NULL,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  reason          text CHECK (reason IN ('duplicate','fraudulent','requested_by_customer','other')),
  status          text NOT NULL CHECK (status IN ('pending','succeeded','failed','canceled')),
  failure_reason  text,
  created_at      timestamptz NOT NULL,
  updated_at      timestamptz NOT NULL
);

CREATE TABLE disputes (
  dispute_id      text PRIMARY KEY,              -- dp_...
  charge_id       text NOT NULL REFERENCES charges(charge_id),
  payment_intent_id text NOT NULL REFERENCES payment_intents(payment_intent_id),
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  amount          bigint NOT NULL,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  reason          text NOT NULL CHECK (reason IN ('fraudulent','product_not_received','product_unacceptable',
                    'duplicate','subscription_canceled','credit_not_processed','general')),
  network_reason_code text,
  card_brand      text,
  status          text NOT NULL CHECK (status IN ('warning_needs_response','needs_response',
                    'under_review','won','lost','accepted')),
  evidence_submitted boolean NOT NULL,
  evidence_due_by timestamptz,
  is_charge_refundable boolean NOT NULL,
  created_at      timestamptz NOT NULL,
  resolved_at     timestamptz
);

CREATE TABLE fraud_assessments (
  assessment_id   text PRIMARY KEY,
  charge_id       text NOT NULL REFERENCES charges(charge_id),
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  risk_score      smallint NOT NULL CHECK (risk_score BETWEEN 0 AND 100),
  risk_level      text NOT NULL CHECK (risk_level IN ('normal','elevated','highest')),
  action          text NOT NULL CHECK (action IN ('allow','review','block')),
  rules_triggered jsonb,
  model_version   text NOT NULL,
  review_outcome  text CHECK (review_outcome IN ('approved','refunded_as_fraud','dismissed')),
  reviewed_at     timestamptz,
  created_at      timestamptz NOT NULL
);

-- ---------- 5. MONEY MOVEMENT ----------
CREATE TABLE settlement_batches (                 -- Adyen settlement batch / report
  settlement_batch_id text PRIMARY KEY,
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  batch_number    integer NOT NULL,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  status          text NOT NULL CHECK (status IN ('open','closed','paid')),
  period_start    date NOT NULL,
  period_end      date NOT NULL,
  gross_credit    bigint NOT NULL,
  gross_debit     bigint NOT NULL,
  total_fees      bigint NOT NULL,
  net_amount      bigint NOT NULL,
  record_count    integer NOT NULL,
  created_at      timestamptz NOT NULL,
  closed_at       timestamptz,
  UNIQUE (merchant_id, batch_number)
);

CREATE TABLE payouts (
  payout_id       text PRIMARY KEY,              -- po_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  bank_account_id text NOT NULL REFERENCES bank_accounts(bank_account_id),
  settlement_batch_id text REFERENCES settlement_batches(settlement_batch_id),
  amount          bigint NOT NULL,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  status          text NOT NULL CHECK (status IN ('pending','in_transit','paid','failed','canceled')),
  method          text NOT NULL CHECK (method IN ('standard','instant')),
  failure_code    text CHECK (failure_code IN ('account_closed','account_frozen','invalid_account_number','bank_ownership_changed','could_not_process')),
  arrival_date    date,
  created_at      timestamptz NOT NULL,
  paid_at         timestamptz
);

CREATE TABLE balance_transactions (               -- the merchant ledger
  balance_transaction_id text PRIMARY KEY,       -- txn_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  source_type     text NOT NULL CHECK (source_type IN ('charge','refund','dispute','dispute_reversal',
                    'payout','adjustment')),
  source_id       text NOT NULL,                 -- ch_ / re_ / dp_ / po_ ...
  amount          bigint NOT NULL,               -- signed gross
  fee             bigint NOT NULL,
  net             bigint NOT NULL,               -- amount - fee
  currency        char(3) NOT NULL REFERENCES currencies(code),
  status          text NOT NULL CHECK (status IN ('pending','available')),
  settlement_batch_id text REFERENCES settlement_batches(settlement_batch_id),
  payout_id       text REFERENCES payouts(payout_id),
  description     text,
  available_on    timestamptz NOT NULL,
  created_at      timestamptz NOT NULL
);

CREATE TABLE fee_details (                        -- interchange++ style breakdown
  fee_id          text PRIMARY KEY,
  balance_transaction_id text NOT NULL REFERENCES balance_transactions(balance_transaction_id),
  charge_id       text REFERENCES charges(charge_id),
  fee_type        text NOT NULL CHECK (fee_type IN ('interchange','scheme','processing','markup',
                    'fx','dispute','payout','chargeback_handling')),
  amount          bigint NOT NULL,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  description     text
);

CREATE TABLE settlement_details (                 -- Adyen "Settlement details report" rows
  settlement_detail_id text PRIMARY KEY,
  settlement_batch_id text NOT NULL REFERENCES settlement_batches(settlement_batch_id),
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  charge_id       text REFERENCES charges(charge_id),
  refund_id       text REFERENCES refunds(refund_id),
  dispute_id      text REFERENCES disputes(dispute_id),
  psp_reference   char(16) NOT NULL,
  record_type     text NOT NULL CHECK (record_type IN ('Settled','Refunded','Chargeback','ChargebackReversed','Fee','Payout')),
  payment_method  text,
  card_brand      text,
  booking_date    date NOT NULL,
  value_date      date NOT NULL,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  gross_credit    bigint NOT NULL DEFAULT 0,
  gross_debit     bigint NOT NULL DEFAULT 0,
  commission      bigint NOT NULL DEFAULT 0,
  markup          bigint NOT NULL DEFAULT 0,
  scheme_fees     bigint NOT NULL DEFAULT 0,
  interchange     bigint NOT NULL DEFAULT 0,
  net_credit      bigint NOT NULL DEFAULT 0,
  net_debit       bigint NOT NULL DEFAULT 0
);

-- ---------- 6. BILLING (Stripe Billing style) ----------
CREATE TABLE products (
  product_id      text PRIMARY KEY,              -- prod_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  name            text NOT NULL,
  description     text,
  active          boolean NOT NULL,
  created_at      timestamptz NOT NULL
);

CREATE TABLE prices (
  price_id        text PRIMARY KEY,              -- price_...
  product_id      text NOT NULL REFERENCES products(product_id),
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  currency        char(3) NOT NULL REFERENCES currencies(code),
  unit_amount     bigint NOT NULL,
  billing_type    text NOT NULL CHECK (billing_type IN ('one_time','recurring')),
  recurring_interval text CHECK (recurring_interval IN ('week','month','year')),
  interval_count  smallint,
  active          boolean NOT NULL,
  created_at      timestamptz NOT NULL
);

CREATE TABLE subscriptions (
  subscription_id text PRIMARY KEY,              -- sub_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  customer_id     text NOT NULL REFERENCES customers(customer_id),
  price_id        text NOT NULL REFERENCES prices(price_id),
  default_payment_method_id text REFERENCES payment_methods(payment_method_id),
  status          text NOT NULL CHECK (status IN ('trialing','active','past_due','unpaid','canceled')),
  quantity        integer NOT NULL DEFAULT 1,
  collection_method text NOT NULL CHECK (collection_method IN ('charge_automatically','send_invoice')),
  trial_end       timestamptz,
  current_period_start timestamptz NOT NULL,
  current_period_end   timestamptz NOT NULL,
  cancel_at_period_end boolean NOT NULL,
  cancel_reason   text CHECK (cancel_reason IN ('payment_failed','customer_request','too_expensive','switched_service','other')),
  canceled_at     timestamptz,
  created_at      timestamptz NOT NULL
);

CREATE TABLE invoices (
  invoice_id      text PRIMARY KEY,              -- in_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  customer_id     text NOT NULL REFERENCES customers(customer_id),
  subscription_id text REFERENCES subscriptions(subscription_id),
  payment_intent_id text REFERENCES payment_intents(payment_intent_id),
  status          text NOT NULL CHECK (status IN ('draft','open','paid','uncollectible','void')),
  billing_reason  text NOT NULL CHECK (billing_reason IN ('subscription_create','subscription_cycle','subscription_update','manual')),
  currency        char(3) NOT NULL REFERENCES currencies(code),
  subtotal        bigint NOT NULL,
  tax             bigint NOT NULL,
  total           bigint NOT NULL,
  amount_paid     bigint NOT NULL,
  amount_remaining bigint NOT NULL,
  attempt_count   smallint NOT NULL,
  next_payment_attempt timestamptz,
  due_date        timestamptz,
  created_at      timestamptz NOT NULL,
  finalized_at    timestamptz,
  paid_at         timestamptz
);

CREATE TABLE invoice_line_items (
  line_item_id    text PRIMARY KEY,
  invoice_id      text NOT NULL REFERENCES invoices(invoice_id),
  price_id        text REFERENCES prices(price_id),
  description     text,
  quantity        integer NOT NULL,
  unit_amount     bigint NOT NULL,
  amount          bigint NOT NULL,
  currency        char(3) NOT NULL REFERENCES currencies(code),
  period_start    timestamptz,
  period_end      timestamptz,
  proration       boolean NOT NULL DEFAULT false
);

-- ---------- 7. OPERATIONS / OBSERVABILITY ----------
CREATE TABLE webhook_events (
  event_id        text PRIMARY KEY,              -- evt_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  event_type      text NOT NULL,                 -- payment_intent.succeeded, charge.dispute.created, ...
  object_type     text NOT NULL,
  object_id       text NOT NULL,
  api_version     text NOT NULL,
  payload         jsonb,
  created_at      timestamptz NOT NULL
);

CREATE TABLE webhook_deliveries (                 -- one row per delivery ATTEMPT
  delivery_id     text PRIMARY KEY,
  event_id        text NOT NULL REFERENCES webhook_events(event_id),
  endpoint_id     text NOT NULL REFERENCES webhook_endpoints(endpoint_id),
  attempt_number  smallint NOT NULL,
  http_status     smallint,                      -- NULL = timeout / connection error
  response_time_ms integer,
  success         boolean NOT NULL,
  error_message   text,
  attempted_at    timestamptz NOT NULL,
  next_retry_at   timestamptz
);

CREATE TABLE api_request_logs (
  request_id      text PRIMARY KEY,              -- req_...
  merchant_id     text NOT NULL REFERENCES merchants(merchant_id),
  api_key_id      text REFERENCES api_keys(api_key_id),
  http_method     text NOT NULL,
  path            text NOT NULL,                 -- /v1/payment_intents
  status_code     smallint NOT NULL,
  error_type      text,                          -- card_error, invalid_request_error, api_error, ...
  error_code      text,
  idempotency_key text,
  idempotent_replayed boolean NOT NULL DEFAULT false,
  request_ip      inet,
  user_agent      text,
  latency_ms      integer NOT NULL,
  created_at      timestamptz NOT NULL
);

-- ---------- INDEXES (the ones analytics queries actually need) ----------
CREATE INDEX ix_pi_merchant_created   ON payment_intents (merchant_id, created_at);
CREATE INDEX ix_pi_customer           ON payment_intents (customer_id);
CREATE INDEX ix_ch_pi                 ON charges (payment_intent_id);
CREATE INDEX ix_ch_merchant_created   ON charges (merchant_id, created_at);
CREATE INDEX ix_ch_status             ON charges (status, failure_code);
CREATE INDEX ix_pe_charge             ON payment_events (charge_id, event_date);
CREATE INDEX ix_ref_charge            ON refunds (charge_id);
CREATE INDEX ix_dp_charge             ON disputes (charge_id);
CREATE INDEX ix_bt_merchant_created   ON balance_transactions (merchant_id, created_at);
CREATE INDEX ix_bt_source             ON balance_transactions (source_type, source_id);
CREATE INDEX ix_sd_batch              ON settlement_details (settlement_batch_id);
CREATE INDEX ix_sd_psp                ON settlement_details (psp_reference);
CREATE INDEX ix_wd_event              ON webhook_deliveries (event_id, attempt_number);
CREATE INDEX ix_api_merchant_created  ON api_request_logs (merchant_id, created_at);
CREATE INDEX ix_api_idem              ON api_request_logs (idempotency_key);