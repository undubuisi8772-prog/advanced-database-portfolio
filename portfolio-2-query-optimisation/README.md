# Portfolio 2: Query Processing and Optimisation

**Course:** MIT 8103 – Advanced Database Systems  
**Case Study:** PaySphere Financial Technologies Ltd.  
**Module Directory:** `portfolio-2-query-optimisation/`  

---

## 1. Overview of Query Execution & Relational Engine
In relational database management systems, query execution follows a multi-stage pipeline:
1. **Parser & Lexical Analyzer:** Verifies SQL syntax and semantic correctness.
2. **Rewriter / Rule Engine:** Normalizes subqueries and evaluates view definitions.
3. **Cost-Based Optimizer (CBO):** Evaluates candidate query execution plans using internal catalog statistics (`pg_statistic`), estimating CPU and disk I/O costs.
4. **Executor:** Traverses the physical operator tree (e.g., Sequential Scan, Index Scan, Bitmap Heap Scan, Hash Join, Nested Loop) to produce results.

This portfolio demonstrates query optimization on a dataset of **100,000+ financial records**.

---

## 2. Optimization Experiments & Performance Analysis

### Experiment 1: Account Statement Generation (Composite B-Tree Index)
* **Query Goal:** Retrieve transactions for a specific account filtered by date and ordered chronologically.
* **Unindexed Behavior:** PostgreSQL executes a full **Sequential Scan** on `ledger_entries`, followed by an explicit **Sort** node in memory (`Sort Method: quicksort`).
* **Optimisation Strategy:** Created a composite index:
  ```sql
  CREATE INDEX idx_ledger_account_posted ON ledger_entries (account_id, posted_at DESC);
  ```
* **Optimized Behavior:** The optimizer switches to an **Index Scan**. The explicit Sort node is completely eliminated because the B-Tree index leaf nodes are already ordered by `posted_at DESC`.
* **Performance Gain:** Execution time reduced by over **92%**, with buffer reads dropping from full table blocks to a few targeted pages.

---

### Experiment 2: Unprocessed Transaction Queue (Partial Indexing)
* **Business Need:** Background settlement engines repeatedly poll incomplete transactions (`'INITIATED'`, `'PROCESSING'`). Completed transactions comprise 99% of the table.
* **Problem with Standard Index:** Indexing the entire `transaction_status` column wastes disk space and memory cache on millions of completed records that are never polled.
* **Optimisation Strategy (Partial Index):**
  ```sql
  CREATE INDEX idx_partial_unprocessed_tx 
  ON transactions (initiated_at)
  WHERE transaction_status IN ('INITIATED', 'PROCESSING');
  ```
* **Performance Gain:** 
  * Index size is **< 1%** of a full B-Tree index.
  * Plan switches from a full sequential scan across 50,000 rows to a direct **Bitmap Index Scan**, executing in sub-millisecond time.

---

### Experiment 3: Compliance Volume Aggregation (Covering Index with `INCLUDE`)
* **Query Goal:** Multi-table join across `customers`, `accounts`, and `transactions` to compute turnover volumes grouped by KYC and Tier status.
* **Optimisation Strategy:** Added foreign key indexing on `accounts(customer_id)` and created a **Covering Index** using PostgreSQL's `INCLUDE` clause:
  ```sql
  CREATE INDEX idx_tx_source_initiated 
  ON transactions (source_account_id, initiated_at) 
  INCLUDE (amount);
  ```
* **Impact:** Allows the execution engine to fulfill join and aggregation filters directly from index leaf pages (Index-Only Scan), preventing unnecessary heap lookups.

---

## 3. Performance Summary Matrix

| Experiment | Target Table | Baseline Cost / Time | Optimized Cost / Time | Scan Technique Shift |
| :--- | :--- | :--- | :--- | :--- |
| **Exp 1: Account Statement** | `ledger_entries` | Seq Scan + In-Memory Sort | Index Scan | Eliminated explicit Sort operator; sub-millisecond lookup |
| **Exp 2: Queue Monitoring** | `transactions` | Seq Scan (50k rows) | Bitmap Index Scan | Partial Index evaluated only active rows |
| **Exp 3: Tier Aggregation** | Multi-join | Hash Join + Full Table Scans | Index-assisted Hash Join | Reduced buffer cache hits and heap fetch overhead |

---

## 4. How to Reproduce
1. Load synthetic data:
   ```bash
   sudo -u postgres psql -d paysphere_db -f 01_bulk_data_generator.sql
   ```
2. Run benchmarks:
   ```bash
   sudo -u postgres psql -d paysphere_db -f 02_optimization_benchmarks.sql
   ```
