INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, password_hash, tier_level, kyc_status)
VALUES
('a0000000-0000-0000-0000-000000000001', 'Babajide', 'Adeleke', 'b.adeleke@example.com', '+2348011112233', '$2a$12$e80b...hash1', 3, 'VERIFIED'),
('a0000000-0000-0000-0000-000000000002', 'Chidinma', 'Okonkwo', 'c.okonkwo@example.com', '+2348022223344', '$2a$12$e80b...hash2', 2, 'VERIFIED'),
('a0000000-0000-0000-0000-000000000003', 'Ibrahim', 'Musa', 'i.musa@example.com', '+2348033334455', '$2a$12$e80b...hash3', 1, 'PENDING');

INSERT INTO kyc_profiles (kyc_id, customer_id, id_type, id_number, document_url, verification_status, verified_at)
VALUES
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'NATIONAL_ID', 'NIN-98765432101', 'https://s3.paysphere.internal/docs/nin1.pdf', 'APPROVED', CURRENT_TIMESTAMP),
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'PASSPORT', 'A01234567', 'https://s3.paysphere.internal/docs/pass2.pdf', 'APPROVED', CURRENT_TIMESTAMP);

INSERT INTO accounts (account_id, customer_id, account_number, currency_code, current_balance, available_balance, account_status)
VALUES
('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', '0123456789', 'NGN', 500000.00, 500000.00, 'ACTIVE'),
('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', '0987654321', 'NGN', 125000.00, 125000.00, 'ACTIVE'),
('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000003', '0555666777', 'NGN', 15000.00, 15000.00, 'ACTIVE');

INSERT INTO transactions (transaction_id, idempotency_key, source_account_id, destination_account_id, amount, fee_amount, currency_code, transaction_type, transaction_status, narration, completed_at)
VALUES
('d0000000-0000-0000-0000-000000000001', 'TX-IDEMP-2026-0001-A9Z', 'c0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 25000.00, 0.00, 'NGN', 'INTERNAL_TRANSFER', 'SUCCESSFUL', 'Contract design advance payment', CURRENT_TIMESTAMP);

INSERT INTO ledger_entries (entry_id, transaction_id, account_id, entry_type, amount, balance_after)
VALUES
('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'DEBIT', 25000.00, 475000.00),
('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'CREDIT', 25000.00, 150000.00);
