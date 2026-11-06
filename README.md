# Advanced Database Systems Portfolio: PaySphere Financial Technologies Ltd.

**Course Code:** MIT 8103 – Advanced Database Systems  
**Programme:** Master of Information Technology (Postgraduate)  
**Institution:** School of Postgraduate Studies, MIVA Open University  
**Academic Session:** 2026/2027  
**Candidate Name:** Ugochukwu Ndubuisi  
**Student ID:** 301828772  
**Institutional Email:** u.ndubuisi8772@miva.edu.ng  
**Repository URL:** https://github.com/undubuisi8772-prog/advanced-database-portfolio  
**Total Assessment Marks:** 40 Marks  

---

## 1. Executive Summary & Case Study Specification

### 1.1 Organisation Profile
**PaySphere Financial Technologies Ltd.** is a licensed Tier-1 digital payment service provider and neo-banking institution delivering real-time peer-to-peer (P2P) transfers, multi-currency customer wallets, automated merchant settlement, and institutional utility bill processing. 

To maintain regulatory compliance with Central Bank operational directives and AML/CFT guidelines, PaySphere enforces an **immutable double-entry general ledger architecture**. Every monetary transaction requires at least two balanced ledger postings ($\sum \text{Debits} = \sum \text{Credits}$), guaranteeing zero balance drift across accounts.

### 1.2 System Actors & Supported Operations
* **Retail & Merchant Users:** Initiate peer-to-peer transfers, query real-time multi-currency balances, and generate chronological ledger statements.
* **Payment Gateway Engine:** Executes atomic, idempotent fund transfers with pessimistic concurrency locking (`SELECT ... FOR UPDATE`) to eliminate double-spending.
* **Compliance & AML Officers:** Monitor real-time transaction velocity, investigate flagged transactions, and audit Know-Your-Customer (KYC) documentation.
* **Operations & DBA Teams:** Execute end-of-day (EOD) financial reconciliations, oversee replication topologies, and manage horizontal data partitioning.

---

## 2. Repository Directory Structure

```text
advanced-database-portfolio/
│
├── portfolio-1-database-design/
│   ├── 01_schema_definition.sql                 # Production PostgreSQL DDL with constraints & UUIDs
│   ├── 02_sample_seed.sql                       # Deterministic double-entry financial seed data
│   ├── evidence_schema.png                      # Terminal verification & table creation evidence
│   └── README.md                                # ER diagram & full UNF to BCNF normalization proof
│
├── portfolio-2-query-optimisation/
│   ├── 01_bulk_data_generator.sql               # Synthetic data generator (100,000+ balanced records)
│   ├── 02_optimization_benchmarks.sql           # EXPLAIN (ANALYZE, BUFFERS) before/after benchmarks
│   ├── evidence_query_optimization.png          # Execution plan evidence showing 98% latency reduction
│   └── README.md                                # Query optimizer cost model and indexing analysis
│
├── portfolio-3-transactions-concurrency/
│   ├── 01_transfer_procedure.sql                # ACID-compliant stored procedure with deadlock prevention
│   ├── 02_acid_rollback_savepoint.sql           # Overdraft rollback and SAVEPOINT validation tests
│   ├── 03_concurrency_lock_demo.sql             # Live terminal row-level locking demonstration script
│   ├── evidence_concurrency_rollback.png        # Evidence of automatic atomic rollback on overdraft
│   └── README.md                                # Concurrency anomaly analysis & locking mechanics
│
├── portfolio-4-nosql/
│   ├── 01_fraud_audit_model.js                  # Reference MongoDB schema with $jsonSchema validation
│   ├── 02_nosql_analytics_pipeline.js           # Reference MongoDB aggregation pipelines
│   ├── 03_postgresql_jsonb_document_model.sql   # Native PostgreSQL JSONB document engine with GIN indexing
│   ├── evidence_document_model.png              # Working JSON path containment query & aggregation output
│   └── README.md                                # Polyglot persistence & document data model suitability
│
├── portfolio-5-distributed-cloud/
│   ├── 01_horizontal_sharding_partitioning.sql  # Range-based declarative partitioning by fiscal year
│   ├── 02_replication_and_failover_spec.sql     # Streaming replication & zero-loss failover spec
│   ├── evidence_distributed_partitioning.png    # Terminal output verifying shard routing & pruning
│   └── README.md                                # CAP/PACELC theorem evaluation & cloud HA architecture
│
└── README.md                                    # Master portfolio summary and documentation
```

---

## 3. Portfolio Summary & Key Technical Results

| Activity | Domain Scope | Mark Weight | Key Practical Evidence / Measured Outcome |
| :--- | :--- | :---: | :--- |
| **Portfolio 1** | **Database Design & Modelling** | **7 Marks** | 6-entity relational model in full **BCNF**; immutable double-entry ledger balancing; check constraints on financial invariants. |
| **Portfolio 2** | **Query Processing & Optimisation** | **7 Marks** | Generated 100,000+ ledger records; statement query execution time reduced from **`8.383 ms` $\rightarrow$ `0.174 ms`** (**97.9% speedup**) via composite indexing; partial index reduced scan time by **92.5%**. |
| **Portfolio 3** | **Transactions & Concurrency** | **7 Marks** | PL/pgSQL stored procedure with deterministic lock ordering (deadlock prevention); pessimistic row locking (`FOR UPDATE`); verified zero orphaned ledger records upon rollback. |
| **Portfolio 4** | **NoSQL & Advanced Data Models** | **7 Marks** | Polyglot document model for semi-structured fraud telemetry; GIN indexing on nested JSONB; sub-millisecond JSON path querying (`@>`) and platform aggregation. |
| **Portfolio 5** | **Distributed & Cloud Databases** | **6 Marks** | Declarative range table partitioning by fiscal year; verified automatic shard routing and optimizer **Partition Pruning**; formal **CP / PC/EC** banking classification. |
| **Final Docs** | **Synthesis & Technical Reflection** | **6 Marks** | Consolidated LMS submission report, academic references, and AI Use Declaration. |
| **Total** | | **40 Marks** | |

---

## 4. Empirical Query Optimization Benchmark Matrix

Captured using `EXPLAIN (ANALYZE, BUFFERS)` on the 100,000-record dataset:

```text
========================================================================================================
EXPERIMENT                     BASELINE (UNINDEXED)           OPTIMIZED                      IMPROVEMENT
========================================================================================================
Exp 1: Account Statement       Seq Scan (100k rows) + Sort    Bitmap Index Scan (3 blocks)   97.9% Latency Drop
                               Time: 8.383 ms | Buffers: 1336  Time: 0.174 ms | Buffers: 8    (48x faster)
--------------------------------------------------------------------------------------------------------
Exp 2: Unprocessed Queue       Seq Scan (50k rows)            Bitmap Index Scan              92.5% Latency Drop
                               Time: 8.963 ms | Buffers: 1389  Time: 0.676 ms | Buffers: 205   (<1% index size)
--------------------------------------------------------------------------------------------------------
Exp 3: Tier Volume Join        Hash Join (Full Scan)          Index-Assisted Hash Join       Optimizer selected
                               Time: 43.771 ms                Time: 41.843 ms                optimal join tree
========================================================================================================
```

---

## 5. Environment & Step-by-Step Reproduction Guide

All activities were developed, executed, and benchmarked on **Ubuntu Linux (x86_64)** running **PostgreSQL 16**.

### Automated Setup & Execution Script
```bash
# 1. Switch to PostgreSQL prompt and create the database
sudo -u postgres psql -c "CREATE DATABASE paysphere_db;"

# 2. Deploy Portfolio 1 (Schema & Seed)
sudo -u postgres psql -d paysphere_db -f portfolio-1-database-design/01_schema_definition.sql
sudo -u postgres psql -d paysphere_db -f portfolio-1-database-design/02_sample_seed.sql

# 3. Deploy Portfolio 2 (100k Benchmark Data Generation & Benchmarks)
sudo -u postgres psql -d paysphere_db -f portfolio-2-query-optimisation/01_bulk_data_generator.sql
sudo -u postgres psql -d paysphere_db -f portfolio-2-query-optimisation/02_optimization_benchmarks.sql

# 4. Deploy Portfolio 3 (Stored Procedure & ACID Rollback Tests)
sudo -u postgres psql -d paysphere_db -f portfolio-3-transactions-concurrency/01_transfer_procedure.sql
sudo -u postgres psql -d paysphere_db -f portfolio-3-transactions-concurrency/02_acid_rollback_savepoint.sql

# 5. Deploy Portfolio 4 (Advanced Document Data Model & GIN Aggregation)
sudo -u postgres psql -d paysphere_db -f portfolio-4-nosql/03_postgresql_jsonb_document_model.sql

# 6. Deploy Portfolio 5 (Horizontal Partitioning & Partition Pruning)
sudo -u postgres psql -d paysphere_db -f portfolio-5-distributed-cloud/01_horizontal_sharding_partitioning.sql
```

---

## 6. Technical Reflection & Architectural Decisions

* **Double-Entry General Ledger Integrity:** Decoupling high-level transfer requests (`TRANSACTIONS`) from individual postings (`LEDGER_ENTRIES`) was a deliberate architectural choice. While requiring two ledger writes per transfer, it guarantees absolute mathematical auditability and eliminates single-column balance overwrites.
* **Pessimistic Locking vs. Optimistic Concurrency:** Financial transactions with high debit contention require pessimistic row-level locking (`SELECT ... FOR UPDATE`). While optimistic locking reduces lock contention, retry storms under high concurrency degrade throughput more severely than deterministic row locks.
* **Deadlock Elimination Algorithm:** Deadlocks commonly occur during bi-directional transfers between two accounts. Sorting account UUID keys lexicographically prior to lock acquisition guarantees that concurrent sessions lock resources in identical order, rendering circular wait deadlocks mathematically impossible.
* **Polyglot Modeling Trade-offs:** Rather than maintaining a separate NoSQL server cluster for fraud telemetry, leveraging PostgreSQL's native `JSONB` engine combined with GIN indexing demonstrated that enterprise relational engines can achieve document flexibility without operational fragmentation.

---

## 7. References
1. Elmasri, R., & Navathe, S. B. (2016). *Fundamentals of Database Systems* (7th ed.). Pearson.
2. Kleppmann, M. (2017). *Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and Maintainable Systems*. O'Reilly Media.
3. PostgreSQL Global Development Group. (2024). *PostgreSQL 16 Documentation: Concurrency Control, Indexing, and Table Partitioning*. Available at: https://www.postgresql.org/docs/
4. Central Bank of Nigeria (CBN). (2020). *Regulatory Framework for the Use of Electronic Payment Systems and Consumer Protection Guidelines*.

---

## 8. Academic Integrity & AI-Use Declaration

In accordance with MIVA Open University postgraduate assessment policies:
1. **AI Tool Disclosed:** Large Language Model assistance was consulted as an educational aid and technical sparring partner.
2. **Context of Assistance:** AI was utilized for brainstorming domain scenarios, comparing algorithmic lock orders, refining Markdown table syntax, and reviewing execution plan metrics.
3. **Verification & Independent Execution:** All SQL schemas, stored procedures, JSONB document pipelines, and partitioning scripts were manually deployed, debugged, executed, and benchmarked by the student on a local Ubuntu Linux workstation. All query timings and terminal outputs represent genuine, independently verified empirical data.
