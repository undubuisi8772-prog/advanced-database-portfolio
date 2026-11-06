-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 3: Live Concurrency & Row Locking Test
-- ============================================================================

-- SESSION A (Open in Terminal 1):
-- -------------------------------------------------------------
BEGIN;
-- Lock Account 1 for 10 seconds
SELECT account_id, available_balance
FROM accounts
WHERE account_number = '0000000001'
FOR UPDATE;

-- Simulate high-load banking workload
SELECT pg_sleep(10);
COMMIT;


-- SESSION B (Open in Terminal 2 while Terminal 1 is sleeping):
-- -------------------------------------------------------------
-- When you run this immediately after Session A starts, Session B will
-- automatically WAIT until Session A commits, proving row-level lock serialization!
BEGIN;
SELECT account_id, available_balance
FROM accounts
WHERE account_number = '0000000001'
FOR UPDATE;
COMMIT;
