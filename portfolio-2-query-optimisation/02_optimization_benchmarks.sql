-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 2: Query Processing & Index Optimisation Benchmarks
-- Database: paysphere_db
-- ============================================================================

-- ****************************************************************************
-- EXPERIMENT 1: Composite Index for Financial Statement Generation
-- Business Case: A user requests their account statement for a date range,
-- ordered chronologically.
-- ****************************************************************************

-- Pick a valid test account_id
DO $$
DECLARE
    v_acc_id UUID;
BEGIN
    SELECT account_id INTO v_acc_id FROM accounts LIMIT 1;
    RAISE NOTICE 'Testing with Account ID: %', v_acc_id;
END $$;

-- 1A: BEFORE OPTIMIZATION (No Index)
-- Running EXPLAIN ANALYZE on cold query
EXPLAIN (ANALYZE, BUFFERS)
SELECT entry_id, entry_type, amount, balance_after, posted_at
FROM ledger_entries
WHERE account_id = (SELECT account_id FROM accounts LIMIT 1)
  AND posted_at >= NOW() - INTERVAL '30 days'
ORDER BY posted_at DESC;

-- 1B: CREATE COMPOSITE B-TREE INDEX
CREATE INDEX idx_ledger_account_posted
ON ledger_entries (account_id, posted_at DESC);

-- 1C: AFTER OPTIMIZATION (With Composite Index)
EXPLAIN (ANALYZE, BUFFERS)
SELECT entry_id, entry_type, amount, balance_after, posted_at
FROM ledger_entries
WHERE account_id = (SELECT account_id FROM accounts LIMIT 1)
  AND posted_at >= NOW() - INTERVAL '30 days'
ORDER BY posted_at DESC;


-- ****************************************************************************
-- EXPERIMENT 2: Partial Indexing for Real-Time Unprocessed Queue
-- Business Case: Monitoring engine queries incomplete transactions
-- ('INITIATED', 'PROCESSING') across 50,000+ completed records.
-- ****************************************************************************

-- 2A: BEFORE OPTIMIZATION
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_id, idempotency_key, amount, transaction_status, initiated_at
FROM transactions
WHERE transaction_status IN ('INITIATED', 'PROCESSING');

-- 2B: CREATE PARTIAL INDEX (Advanced concept: indexing only unfinalized transactions)
CREATE INDEX idx_partial_unprocessed_tx
ON transactions (initiated_at)
WHERE transaction_status IN ('INITIATED', 'PROCESSING');

-- 2C: AFTER OPTIMIZATION
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_id, idempotency_key, amount, transaction_status, initiated_at
FROM transactions
WHERE transaction_status IN ('INITIATED', 'PROCESSING');


-- ****************************************************************************
-- EXPERIMENT 3: Multi-Table Aggregation & Covering Index
-- Business Case: Compliance summary of transaction volumes by customer tier.
-- ****************************************************************************

-- 3A: BEFORE OPTIMIZATION
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.tier_level,
    c.kyc_status,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_volume,
    AVG(t.amount) AS avg_ticket_size
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.source_account_id
WHERE t.initiated_at >= NOW() - INTERVAL '60 days'
GROUP BY c.tier_level, c.kyc_status
ORDER BY total_volume DESC;

-- 3B: CREATE TARGETED INDEXES ON FOREIGN KEYS & JOIN CRITERIA
CREATE INDEX idx_accounts_customer_id ON accounts (customer_id);
CREATE INDEX idx_tx_source_initiated ON transactions (source_account_id, initiated_at) INCLUDE (amount);

-- 3C: AFTER OPTIMIZATION
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.tier_level,
    c.kyc_status,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_volume,
    AVG(t.amount) AS avg_ticket_size
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_id = t.source_account_id
WHERE t.initiated_at >= NOW() - INTERVAL '60 days'
GROUP BY c.tier_level, c.kyc_status
ORDER BY total_volume DESC;
