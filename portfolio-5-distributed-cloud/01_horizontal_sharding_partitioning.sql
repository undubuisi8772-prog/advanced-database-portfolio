-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 5: Horizontal Partitioning (Declarative Table Sharding)
-- Database: paysphere_db
-- ============================================================================

-- Drop if re-running
DROP TABLE IF EXISTS distributed_ledger_partitions CASCADE;
DROP TABLE IF EXISTS distributed_ledger_master CASCADE;

-- 1. Create Master Partitioned Table (Horizontal Range Partitioning by Year)
CREATE TABLE distributed_ledger_master (
    entry_id UUID NOT NULL,
    transaction_id UUID NOT NULL,
    account_id UUID NOT NULL,
    entry_type VARCHAR(6) NOT NULL CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    amount NUMERIC(15, 2) NOT NULL,
    balance_after NUMERIC(15, 2) NOT NULL,
    posted_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (entry_id, posted_at)
) PARTITION BY RANGE (posted_at);

-- 2. Create Physical Shards / Partitions for Accounting Fiscal Years
CREATE TABLE ledger_shard_2025 PARTITION OF distributed_ledger_master
    FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');

CREATE TABLE ledger_shard_2026 PARTITION OF distributed_ledger_master
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

CREATE TABLE ledger_shard_2027 PARTITION OF distributed_ledger_master
    FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2028-01-01 00:00:00+00');

-- 3. Populate Shards with Historical & Current Year Records
INSERT INTO distributed_ledger_master (entry_id, transaction_id, account_id, entry_type, amount, balance_after, posted_at)
VALUES
-- Historic 2025 Ledger Entry
(uuid_generate_v4(), uuid_generate_v4(), (SELECT account_id FROM accounts LIMIT 1), 'DEBIT', 15000.00, 485000.00, '2025-08-14 10:30:00+00'),
-- Current 2026 Ledger Entry
(uuid_generate_v4(), uuid_generate_v4(), (SELECT account_id FROM accounts LIMIT 1), 'CREDIT', 75000.00, 560000.00, '2026-04-10 14:15:00+00');

-- 4. Verify Automatic Shard Routing
SELECT tableoid::regclass AS physical_shard_name, entry_id, amount, posted_at
FROM distributed_ledger_master;

-- 5. Demonstrate PARTITION PRUNING with EXPLAIN ANALYZE
-- Notice how the query engine completely ignores the 2025 and 2027 shards!
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM distributed_ledger_master
WHERE posted_at >= '2026-01-01' AND posted_at < '2026-12-31';
