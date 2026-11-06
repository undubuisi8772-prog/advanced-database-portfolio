# Portfolio 5: Distributed and Cloud Database Exercise

**Course:** MIT 8103 – Advanced Database Systems  
**Case Study:** PaySphere Financial Technologies Ltd.  
**Module Directory:** `portfolio-5-distributed-cloud/`  

---

## 1. Cloud Architecture & High-Availability Design

PaySphere's distributed cloud deployment addresses three non-functional requirements:
1. **High Availability (99.999% SLA):** Automated failover using **Patroni** and distributed consensus via **etcd**. If the primary database fails, a synchronous read-replica is promoted within $<15$ seconds.
2. **Recovery Point Objective ($\text{RPO} = 0$):** Using `synchronous_commit = on`, a transaction is not confirmed to the client until write-ahead logs (WAL) are flushed to at least one synchronous standby replica, guaranteeing zero data loss.
3. **Recovery Time Objective ($\text{RTO} < 30\text{ seconds}$):** Health check heartbeats trigger automated DNS failover to hot standby nodes without human intervention.

---

## 2. CAP and PACELC Theoretical Evaluation

* **CAP Classification:** **CP (Consistency & Partition Tolerance)**.
  * In a financial ledger, consistency is non-negotiable. If a network split occurs between Availability Zones, the system refuses partitioned writes rather than allowing duplicate debits or divergent balances.
* **PACELC Classification:** **PC/EC**.
  * **P/C (During Partition):** Choose Consistency over Availability.
  * **E/C (Else / Normal Operations):** Choose Consistency over Latency by enforcing synchronous WAL commits.

---

## 3. Horizontal Table Partitioning & Query Pruning
To scale the accounting ledger beyond tens of millions of records without performance degradation, `distributed_ledger_master` is horizontally partitioned by fiscal year.

### Performance Impact of Partition Pruning:
* When querying a specific year (e.g., fiscal year 2026), the query optimizer executes **Partition Pruning**.
* The query plan demonstrates that shards for 2025 and 2027 are completely excluded from the scan tree, reducing disk I/O and memory cache usage by over 66%.
