-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 2: Corrected Synthetic Data Generator (100,000+ Records)
-- ============================================================================

-- Clean out previous test data (respect referential order)
TRUNCATE TABLE ledger_entries CASCADE;
TRUNCATE TABLE transactions CASCADE;
TRUNCATE TABLE beneficiaries CASCADE;
TRUNCATE TABLE accounts CASCADE;
TRUNCATE TABLE kyc_profiles CASCADE;
DELETE FROM customers;

-- 1. Insert 1,000 Customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, password_hash, tier_level, kyc_status)
SELECT
    uuid_generate_v4(),
    'User_' || i,
    'Client_' || i,
    'user_' || i || '@paysphere-benchmark.io',
    '+23480' || LPAD(i::text, 8, '0'),
    '$2a$12$syntheticHashValueForBenchmarkingOnly...',
    (1 + (i % 3)),
    CASE WHEN i % 5 = 0 THEN 'PENDING' ELSE 'VERIFIED' END
FROM generate_series(1, 1000) AS i;

-- 2. Insert 1,000 Accounts (available_balance strictly equals current_balance)
INSERT INTO accounts (account_id, customer_id, account_number, currency_code, current_balance, available_balance, account_status)
SELECT
    uuid_generate_v4(),
    c.customer_id,
    LPAD(ROW_NUMBER() OVER ()::text, 10, '0'),
    'NGN',
    bal,
    bal, -- Strictly satisfies chk_available_balance
    'ACTIVE'
FROM customers c
CROSS JOIN LATERAL (SELECT (10000 + (RANDOM() * 500000))::numeric(15,2) AS bal) b
LIMIT 1000;

-- 3. Insert 50,000 Realistic Transactions
WITH account_pool AS (
    SELECT account_id, ROW_NUMBER() OVER () AS rnum FROM accounts
)
INSERT INTO transactions (transaction_id, idempotency_key, source_account_id, destination_account_id, amount, fee_amount, currency_code, transaction_type, transaction_status, narration, initiated_at, completed_at)
SELECT
    uuid_generate_v4(),
    'TX-BENCH-' || i || '-' || MD5(RANDOM()::text),
    src.account_id,
    dst.account_id,
    (100 + (RANDOM() * 50000))::numeric(15,2),
    (10.00)::numeric(15,2),
    'NGN',
    'INTERNAL_TRANSFER',
    CASE
        WHEN i % 100 = 0 THEN 'INITIATED'
        WHEN i % 150 = 0 THEN 'PROCESSING'
        ELSE 'SUCCESSFUL'
    END,
    'Automated batch payment item ' || i,
    NOW() - (i || ' minutes')::interval,
    NOW() - (i || ' minutes')::interval
FROM generate_series(1, 50000) AS i
JOIN account_pool src ON src.rnum = (1 + (i % 990))
JOIN account_pool dst ON dst.rnum = (1 + ((i + 7) % 990));

-- 4. Generate 100,000 Balanced Double-Entry Ledger Postings
INSERT INTO ledger_entries (entry_id, transaction_id, account_id, entry_type, amount, balance_after, posted_at)
SELECT
    uuid_generate_v4(),
    t.transaction_id,
    t.source_account_id,
    'DEBIT',
    t.amount,
    450000.00,
    t.initiated_at
FROM transactions t;

INSERT INTO ledger_entries (entry_id, transaction_id, account_id, entry_type, amount, balance_after, posted_at)
SELECT
    uuid_generate_v4(),
    t.transaction_id,
    t.destination_account_id,
    'CREDIT',
    t.amount,
    550000.00,
    t.initiated_at
FROM transactions t;

-- Re-compute table statistics for optimizer
ANALYZE customers;
ANALYZE accounts;
ANALYZE transactions;
ANALYZE ledger_entries;
