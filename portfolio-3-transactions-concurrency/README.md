# Portfolio 3: Transactions and Concurrency Control

**Course:** MIT 8103 – Advanced Database Systems  
**Case Study:** PaySphere Financial Technologies Ltd.  
**Module Directory:** `portfolio-3-transactions-concurrency/`  

---

## 1. Concurrency Anomalies & The Double-Spending Problem
In high-throughput digital banking, multiple transactions concurrently read and write to the same account ledger. Unsynchronized execution introduces classic anomalies:
* **Lost Update (Double-Spending):** Two concurrent debit operations read balance = ₦50,000. Both approve a ₦40,000 debit. The account balance becomes negative or one debit is overwritten.
* **Dirty Read ($G_1$):** A transaction reads uncommitted balance mutations that are subsequently rolled back.
* **Non-Repeatable Read ($G_{2a}$):** An account balance query changes mid-transaction due to another committed transaction.

---

## 2. Concurrency Control Mechanisms Implemented

### 2.1 Pessimistic Row-Level Locking (`SELECT ... FOR UPDATE`)
To guarantee serializability on account balances, PaySphere uses pessimistic row locking:
```sql
PERFORM account_id FROM accounts WHERE account_id = v_first_lock FOR UPDATE;
PERFORM account_id FROM accounts WHERE account_id = v_second_lock FOR UPDATE;
```
Any concurrent transaction attempting to read or debit the same account is placed in an OS-level lock wait state until the holding transaction issues `COMMIT` or `ROLLBACK`.

### 2.2 Global Deterministic Deadlock Prevention
A classic deadlock occurs when Session 1 transfers from Account A to B (locks A, waits for B), while Session 2 transfers from Account B to A (locks B, waits for A). 

PaySphere prevents deadlocks by sorting the account UUIDs deterministically:
```sql
IF p_source_acc < p_dest_acc THEN
    v_first_lock := p_source_acc;
    v_second_lock := p_dest_acc;
ELSE
    v_first_lock := p_dest_acc;
    v_second_lock := p_source_acc;
END IF;
```
Because all transactions acquire locks in identical global lexicographical order, circular lock dependencies are mathematically impossible.

---

## 3. ACID Guarantees Verification
1. **Atomicity:** When an overdraft occurs, PostgreSQL's PL/pgSQL block intercepts the error and executes an atomic rollback, ensuring neither accounts nor ledger records are partially updated.
2. **Consistency:** Check constraints (`available_balance <= current_balance`, `amount > 0`) enforce banking invariants at all times.
3. **Isolation:** Row-level locks and `READ COMMITTED` / `SERIALIZABLE` isolation eliminate race conditions.
4. **Durability:** Write-Ahead Logging (WAL) guarantees committed transactions survive server crashes.
