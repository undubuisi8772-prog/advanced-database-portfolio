# Portfolio 4: NoSQL and Advanced Data Models

**Course:** MIT 8103 – Advanced Database Systems  
**Case Study:** PaySphere Financial Technologies Ltd.  
**Module Directory:** `portfolio-4-nosql/`  

---

## 1. Architectural Justification: Why Polyglot Persistence?

In modern financial systems, forcing high-velocity, semi-structured telemetry data into rigid relational tables causes schema migration bottlenecks and locking overhead. PaySphere adopts a **Polyglot Persistence Architecture**:

```
+-------------------------------------------------------------------------+
|                  PaySphere Enterprise Architecture                      |
+-------------------------------------------------------------------------+
       |                                                 |
       v                                                 v
[Relational SQL Engine]                      [Document Data Model (JSONB/BSON)]
- Core Accounting Ledger                     - Real-Time Fraud Telemetry Logs
- Double-Entry Postings                      - Device Fingerprints & IP Geolocation
- Balance Deductions / Crediting             - Behavioral Risk Scores & Threat Flags
- Strict ACID Serializability                - Polymorphic, Evolving Vendor Payloads
```

### Why a Document Model Fits Fraud Telemetry
1. **Schema Volatility:** Device telemetry (e.g., iOS biometric hashes, Android hardware IDs, browser fingerprints, proxy headers) evolves with each mobile release. A document store accommodates arbitrary nested payloads without requiring `ALTER TABLE` locks.
2. **Denormalized Subdocuments:** Network metadata, coordinates, and threat scores are co-located in a single document, eliminating multi-table joins during high-frequency fraud evaluations.
3. **High Write Throughput:** Ingestion of audit streams bypasses foreign key verification constraints while maintaining document-level integrity.

---

## 2. Document Data Model Design & Schema Validation

The fraud telemetry document model captures nested metadata associated with transactions:

```json
{
  "document_id": "25e91e28-76f4-4aae-831c-1ddab168074e",
  "transaction_id": "d0000000-0000-0000-0000-000000000001",
  "customer_id": "a0000000-0000-0000-0000-000000000001",
  "payload": {
    "client_platform": "Web_Portal",
    "ip_address": "185.220.101.5",
    "is_vpn": true,
    "location": {
      "city": "Frankfurt",
      "country": "DE",
      "coordinates": [8.6821, 50.1109]
    },
    "risk_evaluation": {
      "risk_score": 88,
      "decision": "CHALLENGE_2FA",
      "flags": ["VELOCITY_EXCEEDED", "VPN_DETECTED", "FOREIGN_IP"]
    }
  }
}
```

### Advanced Indexing Strategy:
* **Generalized Inverted Index (GIN):** Built directly on the document payload (`USING gin (payload)`), allowing instant sub-millisecond path searches on arbitrary nested keys.
* **Partial Expression Index:** Indexes documents where `((payload->'risk_evaluation'->>'risk_score')::int) >= 70` for real-time AML / fraud monitoring.

---

## 3. Implementation Files in this Directory

* **`03_postgresql_jsonb_document_model.sql`**: Production implementation of the Document Data Model using PostgreSQL's binary JSON (`JSONB`) engine, GIN indexing, JSON path operators (`@>`, `->>`), and document aggregations.
* **`01_fraud_audit_model.js`**: Reference MongoDB BSON document schema definition with `$jsonSchema` validation and TTL indexing.
* **`02_nosql_analytics_pipeline.js`**: Reference MongoDB aggregation pipeline for real-time risk metrics.

---

## 4. How to Reproduce & Verify

Execute the document model script inside `paysphere_db`:

```bash
sudo -u postgres psql -d paysphere_db -f portfolio-4-nosql/03_postgresql_jsonb_document_model.sql
```

### Verification Queries Executed:
1. **JSON Path Containment Search (`@>`):** Retrieves transactions flagged for high-risk challenge:
   ```sql
   SELECT document_id, payload->>'client_platform', payload->'location'->>'city', (payload->'risk_evaluation'->>'risk_score')::int
   FROM fraud_telemetry_documents
   WHERE payload @> '{"risk_evaluation": {"decision": "CHALLENGE_2FA"}}';
   ```
2. **Document-Level Grouping & Aggregation:** Aggregates event volume, average risk, and peak threat score by client platform.
