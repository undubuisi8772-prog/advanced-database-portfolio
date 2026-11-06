-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 3: Production ACID Fund Transfer Stored Procedure
-- Database: paysphere_db
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_execute_fund_transfer(
    p_idempotency_key VARCHAR,
    p_source_acc UUID,
    p_dest_acc UUID,
    p_amount NUMERIC,
    p_narration VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_source_bal NUMERIC;
    v_dest_bal NUMERIC;
    v_tx_id UUID;
    v_first_lock UUID;
    v_second_lock UUID;
BEGIN
    -- 1. Validation Checks
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be strictly positive.';
    END IF;

    IF p_source_acc = p_dest_acc THEN
        RAISE EXCEPTION 'Source and destination accounts must be distinct.';
    END IF;

    -- 2. DEADLOCK PREVENTION STRATEGY:
    -- Order lock acquisition deterministically by UUID value.
    -- This guarantees concurrent transactions never acquire locks in opposite order.
    IF p_source_acc < p_dest_acc THEN
        v_first_lock := p_source_acc;
        v_second_lock := p_dest_acc;
    ELSE
        v_first_lock := p_dest_acc;
        v_second_lock := p_source_acc;
    END IF;

    -- 3. PESSIMISTIC CONCURRENCY CONTROL:
    -- Acquire exclusive row-level locks on both participating accounts.
    PERFORM account_id FROM accounts WHERE account_id = v_first_lock FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = v_second_lock FOR UPDATE;

    -- 4. Check Available Balance
    SELECT available_balance INTO v_source_bal FROM accounts WHERE account_id = p_source_acc;

    IF v_source_bal < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds. Available: %, Requested: %', v_source_bal, p_amount;
    END IF;

    -- 5. Insert High-level Transaction Record
    v_tx_id := uuid_generate_v4();
    INSERT INTO transactions (
        transaction_id, idempotency_key, source_account_id, destination_account_id,
        amount, fee_amount, currency_code, transaction_type, transaction_status, narration, completed_at
    ) VALUES (
        v_tx_id, p_idempotency_key, p_source_acc, p_dest_acc,
        p_amount, 0.00, 'NGN', 'INTERNAL_TRANSFER', 'SUCCESSFUL', p_narration, NOW()
    );

    -- 6. Debit Source Account
    UPDATE accounts
    SET current_balance = current_balance - p_amount,
        available_balance = available_balance - p_amount,
        updated_at = NOW()
    WHERE account_id = p_source_acc
    RETURNING available_balance INTO v_source_bal;

    -- 7. Credit Destination Account
    UPDATE accounts
    SET current_balance = current_balance + p_amount,
        available_balance = available_balance + p_amount,
        updated_at = NOW()
    WHERE account_id = p_dest_acc
    RETURNING available_balance INTO v_dest_bal;

    -- 8. Post Balanced Immutable Double-Entry Ledger Postings
    INSERT INTO ledger_entries (entry_id, transaction_id, account_id, entry_type, amount, balance_after, posted_at)
    VALUES
    (uuid_generate_v4(), v_tx_id, p_source_acc, 'DEBIT', p_amount, v_source_bal, NOW()),
    (uuid_generate_v4(), v_tx_id, p_dest_acc, 'CREDIT', p_amount, v_dest_bal, NOW());

    RAISE NOTICE 'SUCCESS: Transfer of NGN % completed. TxID: %', p_amount, v_tx_id;
END;
$$;
