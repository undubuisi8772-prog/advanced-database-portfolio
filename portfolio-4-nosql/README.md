# Portfolio 4: NoSQL and Advanced Data Models

**Course:** MIT 8103 – Advanced Database Systems  
**Case Study:** PaySphere Financial Technologies Ltd.  
**Module Directory:** `portfolio-4-nosql/`  

---

## 1. Relational (RDBMS) vs. Document NoSQL Trade-off Analysis

| Feature | Relational Core (PostgreSQL) | Document Store (MongoDB) | Architectural Choice for PaySphere |
| :--- | :--- | :--- | :--- |
| **Data Model** | Tables, Rows, Foreign Keys | BSON Documents, Embedded Arrays | Hybrid / Polyglot |
| **Schema Invariance** | Rigid schema enforced by DDL | Dynamic schema with `$jsonSchema` | Polyglot: Ledger is strict; Telemetry is flexible |
| **Transaction Model** | ACID, Multi-Table Serializability | Tunable (Document-level Atomicity) | Core ledger requires absolute ACID |
| **Write Throughput** | Bound by WAL & synchronous indexes | High write throughput, horizontal sharding | MongoDB handles high-velocity telemetry logs |
| **Data Lifecycle** | Manual cron purge jobs | Native Time-To-Live (TTL) indexing | MongoDB purges logs automatically after 90 days |

---

## 2. Document Model Architecture
The `fraud_telemetry_logs` collection captures unstructured and polymorphic metadata associated with each monetary transaction:
* **Embedded Subdocuments:** Telemetry details (network, device hardware, GPS location) are co-located in a single document, eliminating expensive multi-table joins.
* **Schema Governance:** MongoDB's `$jsonSchema` validates data types and ranges while allowing arbitrary device extensions.
* **Index Strategy:**
  * Compound index `{ customer_id: 1, timestamp: -1 }` for instant retrieval of customer activity feeds.
  * Partial index filtering on `risk_score >= 75` for ultra-fast AML compliance monitoring.
  * TTL index on `timestamp` with `expireAfterSeconds: 7776000` (90 days).

---

## 3. How to Execute
Install `mongosh` or MongoDB Community Server on Ubuntu:
```bash
sudo apt install mongodb -y # or run via Docker: docker run -d -p 27017:27017 --name mongo-paysphere mongo:latest
mongosh < 01_fraud_audit_model.js
mongosh < 02_nosql_analytics_pipeline.js
```
