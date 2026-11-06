-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 1: Production Relational DDL Schema
-- Organisation: PaySphere Financial Technologies Ltd.
-- Target RDBMS: PostgreSQL 14+
-- ============================================================================

-- Enable UUID extension for cryptographically secure, non-sequential identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tables if re-running (respect referential order)
DROP TABLE IF EXISTS ledger_entries CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS beneficiaries CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS kyc_profiles CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- ----------------------------------------------------------------------------
-- 1. Table: CUSTOMERS
-- ----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    tier_level INT NOT NULL DEFAULT 1 CHECK (tier_level BETWEEN 1 AND 3),
    kyc_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' 
        CHECK (kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 2. Table: KYC_PROFILES (1:1 with Customers)
-- ----------------------------------------------------------------------------
CREATE TABLE kyc_profiles (
    kyc_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL UNIQUE REFERENCES customers(customer_id) ON DELETE RESTRICT,
    id_type VARCHAR(30) NOT NULL CHECK (id_type IN ('NATIONAL_ID', 'PASSPORT', 'DRIVERS_LICENSE', 'BVN')),
    id_number VARCHAR(50) NOT NULL UNIQUE,
    document_url VARCHAR(255) NOT NULL,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED' 
        CHECK (verification_status IN ('SUBMITTED', 'IN_REVIEW', 'APPROVED', 'REJECTED')),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 3. Table: ACCOUNTS (Multi-currency customer wallets)
-- ----------------------------------------------------------------------------
CREATE TABLE accounts (
    account_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    account_number VARCHAR(10) NOT NULL UNIQUE,
    currency_code VARCHAR(3) NOT NULL DEFAULT 'NGN' CHECK (currency_code IN ('NGN', 'USD', 'GBP', 'EUR')),
    current_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00 CHECK (current_balance >= 0.00),
    available_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00 CHECK (available_balance <= current_balance),
    account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' 
        CHECK (account_status IN ('ACTIVE', 'FROZEN', 'DORMANT', 'CLOSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_positive_available CHECK (available_balance >= 0.00)
);

-- ----------------------------------------------------------------------------
-- 4. Table: TRANSACTIONS (High-level business payment orders)
-- ----------------------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    idempotency_key VARCHAR(100) NOT NULL UNIQUE,
    source_account_id UUID NOT NULL REFERENCES accounts(account_id) ON DELETE RESTRICT,
    destination_account_id UUID NOT NULL REFERENCES accounts(account_id) ON DELETE RESTRICT,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0.00),
    fee_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.00 CHECK (fee_amount >= 0.00),
    currency_code VARCHAR(3) NOT NULL,
    transaction_type VARCHAR(30) NOT NULL 
        CHECK (transaction_type IN ('INTERNAL_TRANSFER', 'EXTERNAL_PAYMENT', 'MERCHANT_PAY', 'BILL_PAYMENT')),
    transaction_status VARCHAR(20) NOT NULL DEFAULT 'INITIATED' 
        CHECK (transaction_status IN ('INITIATED', 'PROCESSING', 'SUCCESSFUL', 'FAILED', 'REVERSED')),
    narration VARCHAR(150),
    initiated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    CONSTRAINT chk_different_accounts CHECK (source_account_id <> destination_account_id)
);

-- ----------------------------------------------------------------------------
-- 5. Table: LEDGER_ENTRIES (Double-entry balanced accounting ledger)
-- ----------------------------------------------------------------------------
CREATE TABLE ledger_entries (
    entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES transactions(transaction_id) ON DELETE RESTRICT,
    account_id UUID NOT NULL REFERENCES accounts(account_id) ON DELETE RESTRICT,
    entry_type VARCHAR(6) NOT NULL CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0.00),
    balance_after NUMERIC(15, 2) NOT NULL,
    posted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 6. Table: BENEFICIARIES (Saved counterparties)
-- ----------------------------------------------------------------------------
CREATE TABLE beneficiaries (
    beneficiary_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    beneficiary_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(10) NOT NULL,
    bank_code VARCHAR(10) NOT NULL DEFAULT 'PAYSPHERE',
    bank_name VARCHAR(50) NOT NULL DEFAULT 'PaySphere Bank',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_beneficiary UNIQUE (customer_id, account_number, bank_code)
);
