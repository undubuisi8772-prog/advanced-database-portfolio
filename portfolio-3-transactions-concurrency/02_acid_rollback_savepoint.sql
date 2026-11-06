-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 3: ACID Rollback and Savepoint Validation
-- ============================================================================

-- ****************************************************************************
-- TEST 1: Atomicity & Consistency Verification (Rollback on Overdraft)
-- ****************************************************************************
DO $$
DECLARE
    v_acc1 UUID;
    v_acc2 UUID;
BEGIN
    SELECT account_id INTO v_acc1 FROM accounts LIMIT 1;
    SELECT account_id INTO v_acc2 FROM accounts OFFSET 1 LIMIT 1;

    -- Set Account 1 balance to exactly 5,000
    UPDATE accounts SET current_balance = 5000.00, available_balance = 5000.00 WHERE account_id = v_acc1;

    BEGIN
        -- Attempt to transfer 80,000 (Violates balance threshold)
        CALL sp_execute_fund_transfer('TX-FAIL-TEST-999', v_acc1, v_acc2, 80000.00, 'Overdraft transfer attempt');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'TRANSACTION ABORTED (AUTOMATIC ROLLBACK): %', SQLERRM;
    END;
END $$;

-- Verification: Ensure zero money was deducted and zero orphan ledger entries exist
SELECT account_id, available_balance FROM accounts LIMIT 1;
SELECT COUNT(*) AS orphan_ledger_entries FROM ledger_entries WHERE amount = 80000.00;


-- ****************************************************************************
-- TEST 2: Partial Rollback Using SAVEPOINT
-- ****************************************************************************
BEGIN;

-- Operation 1: Apply Monthly Account Maintenance Fee of NGN 50.00
UPDATE accounts
SET available_balance = available_balance - 50.00,
    current_balance = current_balance - 50.00
WHERE account_id = (SELECT account_id FROM accounts LIMIT 1);

-- Establish Savepoint
SAVEPOINT maintenance_charge_ok;

-- Operation 2: Faulty operation that violates CHECK constraint
INSERT INTO transactions (
    transaction_id, idempotency_key, source_account_id, destination_account_id, amount, currency_code, transaction_type
) VALUES (
    uuid_generate_v4(), 'CORRUPT-TX-KEY',
    (SELECT account_id FROM accounts LIMIT 1),
    (SELECT account_id FROM accounts LIMIT 1), -- Violates chk_different_accounts
    -500.00, 'NGN', 'BAD_TYPE'                 -- Violates chk_tx_amount
);

-- Rollback to Savepoint upon error (preserves Operation 1 while discarding Operation 2)
ROLLBACK TO SAVEPOINT maintenance_charge_ok;

COMMIT;

-- Verify maintenance charge was committed while corrupt transaction was discarded
SELECT idempotency_key FROM transactions WHERE idempotency_key = 'CORRUPT-TX-KEY';
