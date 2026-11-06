-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 4: Advanced Document Data Model (JSONB Document Store)
-- Database: paysphere_db
-- ============================================================================

DROP TABLE IF EXISTS fraud_telemetry_documents CASCADE;

-- 1. Create Document Collection Table
CREATE TABLE fraud_telemetry_documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL,
    customer_id UUID NOT NULL,
    -- Polymorphic, schemaless BSON/JSON document payload:
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- JSON Schema validation rule: Ensure risk_score exists and is within [0, 100]
    CONSTRAINT chk_risk_score_range CHECK (
        (payload->'risk_evaluation'->>'risk_score')::int BETWEEN 0 AND 100
    )
);

-- 2. Create Advanced GIN (Generalized Inverted Index) for Subdocument Search
-- This allows fast querying of ANY nested attribute inside the JSON document!
CREATE INDEX idx_gin_fraud_payload ON fraud_telemetry_documents USING gin (payload);

-- Specific B-Tree Expression Index for real-time AML high-risk alerting
CREATE INDEX idx_expr_high_risk ON fraud_telemetry_documents (
    ((payload->'risk_evaluation'->>'risk_score')::int)
) WHERE ((payload->'risk_evaluation'->>'risk_score')::int) >= 70;


-- 3. Ingest Polymorphic Telemetry Documents
INSERT INTO fraud_telemetry_documents (transaction_id, customer_id, payload)
VALUES
(
    uuid_generate_v4(),
    (SELECT customer_id FROM customers LIMIT 1),
    '{
        "client_platform": "Android",
        "app_version": "v4.2.1",
        "ip_address": "102.89.23.4",
        "location": {"city": "Lagos", "country": "NG", "coordinates": [3.3792, 6.5244]},
        "risk_evaluation": {
            "risk_score": 12,
            "decision": "ALLOW",
            "flags": []
        }
    }'::jsonb
),
(
    uuid_generate_v4(),
    (SELECT customer_id FROM customers OFFSET 1 LIMIT 1),
    '{
        "client_platform": "Web_Portal",
        "ip_address": "185.220.101.5",
        "is_vpn": true,
        "location": {"city": "Frankfurt", "country": "DE", "coordinates": [8.6821, 50.1109]},
        "risk_evaluation": {
            "risk_score": 88,
            "decision": "CHALLENGE_2FA",
            "flags": ["VELOCITY_EXCEEDED", "VPN_DETECTED", "FOREIGN_IP"]
        }
    }'::jsonb
);

-- 4. NoSQL Document Query: Retrieve high-risk events using JSON Path operators
SELECT
    document_id,
    payload->>'client_platform' AS platform,
    payload->'location'->>'city' AS city,
    (payload->'risk_evaluation'->>'risk_score')::int AS risk_score,
    payload->'risk_evaluation'->'flags' AS triggered_flags
FROM fraud_telemetry_documents
WHERE payload @> '{"risk_evaluation": {"decision": "CHALLENGE_2FA"}}';

-- 5. NoSQL Document Aggregation: Group by Client Platform & Max Risk
SELECT
    payload->>'client_platform' AS platform,
    COUNT(*) AS incident_count,
    AVG((payload->'risk_evaluation'->>'risk_score')::int) AS avg_risk,
    MAX((payload->'risk_evaluation'->>'risk_score')::int) AS peak_risk
FROM fraud_telemetry_documents
GROUP BY payload->>'client_platform';
