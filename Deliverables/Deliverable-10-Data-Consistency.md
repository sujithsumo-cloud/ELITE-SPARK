# Deliverable 10 — Data Consistency Risks During Failover

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**Database:** DynamoDB Global Table — `FIN-TRANSACTIONS`  
**DR Strategy:** Warm Disaster Recovery

---

## 1. Objective

During regional failover, the application can remain available, but data may temporarily become inconsistent because the Hyderabad and Mumbai environments do not change state at exactly the same instant.

The main consistency risks are:

```text
Replication Delay
      +
Concurrent Writes
      +
Duplicate Transactions
      +
Stale Reads
      +
Unsafe Failback
      +
Replicated Bad Data
```

The goal is to prevent these issues from becoming incorrect financial transactions.

---

## 2. Main Data-Consistency Risks

| Risk | What Can Happen? | Mitigation |
|---|---|---|
| Replication lag | Latest HYD writes may not yet exist in Mumbai | Low RPO target, replication monitoring, verify data after failover |
| Split-brain writes | HYD and MUM may both receive writes during transition | Use a single-writer region and controlled failover |
| Duplicate transactions | Client retries can submit the same payment twice | Use unique transaction IDs and idempotent request handling |
| Stale reads | User may temporarily read older data in Mumbai | Retry/read verification and replication-aware application logic |
| Conflicting updates | Same item may be updated in both regions | Avoid active writes in both regions during DR |
| Unsafe failback | Returning to HYD too early can reintroduce stale state | Verify synchronization before failback |
| Bad data replication | Incorrect update/delete can also reach DR | DynamoDB PITR and restore verification |
| S3 replication delay | Latest object may not yet exist in DR bucket | S3 CRR monitoring and versioning |

---

## 3. Replication Lag

DynamoDB Global Tables replicate data asynchronously.

```text
Write in Hyderabad
        ↓
Replication
        ↓
Visible in Mumbai
```

A short delay can exist between the two regions.

During a sudden failure:

```text
Transaction written in HYD
        ↓
HYD fails immediately
        ↓
Transaction may not yet be visible in MUM
```

This is the main reason the project does not claim:

```text
RPO = 0
```

The project target is:

```text
RPO ≤ 1 minute
```

Observed replication visibility during testing:

```text
3.97 seconds
```

### Mitigation

```text
Monitor replication
      ↓
Keep RPO low
      ↓
Verify critical transactions after failover
```

The 3.97-second result is a test observation, not a guaranteed constant replication time.

---

## 4. Split-Brain Writes

A serious consistency issue can happen if both regions accept writes at the same time during failover.

Example:

```text
User A → Hyderabad → Update Transaction

User B → Mumbai → Update Same Transaction
```

This can create conflicting data.

### Project Mitigation

The project follows a **single-writer operating model**:

```text
Normal Operation:
HYD = Active Writer
MUM = DR

After Failover:
MUM = Active Writer
HYD = Removed / Unavailable
```

The goal is to avoid:

```text
HYD Writes + MUM Writes
at the same time
```

---

## 5. DNS Transition Risk

Route 53 failover changes which regional endpoint is returned, but some clients may temporarily keep an older DNS result.

This can create a short transition period:

```text
Some Users → HYD
Other Users → MUM
```

If HYD is still accepting writes, this can create consistency risk.

### Mitigation

During a planned or controlled failover:

```text
Stop / Fence Primary Writes
        ↓
Confirm Primary is Unavailable
        ↓
Allow DR Region to Become Writer
```

For an unexpected outage, the application should still avoid intentionally running both regions as active writers.

---

## 6. Duplicate Transaction Risk

During failover, a client may send a request but not receive the response before the connection is interrupted.

The user may retry:

```text
Transaction Request
      ↓
HYD processes it
      ↓
Connection fails
      ↓
User retries
      ↓
MUM receives same transaction
```

Without protection:

```text
One real payment
      ↓
Two database writes
```

### Mitigation

Use a unique transaction identifier:

```text
transaction_id
```

The application should check whether the transaction already exists before creating another record.

Concept:

```text
Receive Transaction ID
        ↓
Already Exists?
   ┌────┴────┐
  Yes       No
   ↓         ↓
Return     Create
Existing   Transaction
Result
```

This is called **idempotent processing**.

---

## 7. Stale Reads

Immediately after failover, the Mumbai replica may temporarily contain slightly older data.

Example:

```text
HYD Balance / Transaction State
           ↓
     Replication delay
           ↓
MUM temporarily shows older state
```

### Mitigation

For important transactions:

```text
Read Data
   ↓
Validate Expected Transaction / State
   ↓
Retry if required
```

The application should not assume that every cross-region read is immediately synchronized at the exact moment of failover.

---

## 8. Conflicting Updates

Two regions updating the same transaction can cause conflict.

Example:

```text
HYD:
Status = SUCCESS

MUM:
Status = FAILED
```

This is especially dangerous for financial data.

### Mitigation

The project avoids an active-active write model.

```text
One Active Write Region
        ↓
Other Region Used for DR
```

For a production financial system, conditional writes and application-level transaction rules can provide additional protection.

---

## 9. Unsafe Failback

After Hyderabad recovers, traffic should not immediately return to it.

Bad approach:

```text
HYD comes online
      ↓
Immediately move users back
```

There may still be writes made in Mumbai during the disaster period that need to be fully synchronized.

### Safe Failback

```text
HYD Restored
     ↓
Verify Application Health
     ↓
Verify Database Replication
     ↓
Confirm Recent MUM Writes Exist in HYD
     ↓
Return HYD to Primary
     ↓
Move Traffic Back
```

Failback must be treated as a controlled operation.

---

## 10. Replicated Corruption

Replication protects availability, but it can also replicate bad data.

Example:

```text
Incorrect Update in HYD
        ↓
Global Table Replication
        ↓
Incorrect Data in MUM
```

Therefore:

```text
Replication ≠ Backup
```

### Mitigation

The project uses DynamoDB Point-in-Time Recovery.

```text
Bad Data
   ↓
Choose Earlier Clean Recovery Point
   ↓
PITR Restore
   ↓
Verify Recovered Transaction
```

The project successfully demonstrated a PITR restore using:

```text
FIN-TRANSACTIONS-RESTORE-DEMO
```

---

## 11. S3 Consistency During Regional Failure

The project also uses S3 Cross-Region Replication.

```text
HYD S3
   ↓
CRR
   ↓
MUM S3
```

Cross-region replication is not instantaneous.

A newly written object might not yet exist in Mumbai when a sudden failure occurs.

### Mitigation

The project uses:

```text
S3 Versioning
+
Cross-Region Replication
+
Replication Monitoring
```

Previous versions also help recover from accidental object changes.

---

## 12. Recommended Consistency Control Flow

```text
                 NORMAL OPERATION
                        │
                        ▼
                 HYD Active Writer
                        │
                        ▼
             DynamoDB Global Table
                        │
                        ▼
                  MUM Replica
                        │
                        ▼
                   HYD FAILURE
                        │
                        ▼
               Detect / Confirm Failure
                        │
                        ▼
                Stop HYD Write Path
                        │
                        ▼
                Route 53 → Mumbai
                        │
                        ▼
                 MUM Active Writer
                        │
                        ▼
          Verify Critical Transaction Data
                        │
                        ▼
                   DR Operation
```

---

## 13. Failback Consistency Flow

```text
MUM Active During DR
        ↓
HYD Infrastructure Restored
        ↓
Verify HYD Health
        ↓
Verify Global Table Synchronization
        ↓
Check Recent Transactions
        ↓
Confirm No Data Gap
        ↓
Return HYD as Primary Writer
        ↓
Route Traffic Back
```

---

## 14. Consistency Controls Summary

| Control | Purpose |
|---|---|
| Single-writer regional model | Prevents split-brain writes |
| DynamoDB Global Tables | Replicates transaction data |
| RPO monitoring | Measures possible replication gap |
| Unique transaction IDs | Reduces duplicate transactions |
| Idempotent application logic | Makes retries safer |
| Data verification after failover | Detects missing/stale records |
| Controlled failback | Prevents premature return to primary |
| DynamoDB PITR | Recovers from replicated bad data |
| S3 Versioning | Recovers older object versions |
| S3 CRR monitoring | Detects regional object replication problems |

---

## 15. Important Limitation

The project uses asynchronous cross-region replication.

Therefore it cannot guarantee:

```text
Zero Replication Delay
Zero Data Loss
Zero Conflict Risk
```

Instead, the architecture reduces these risks using:

```text
Low RPO
+
Single-Writer Operation
+
Controlled Failover
+
Verification
+
PITR
```

---

## 16. Conclusion

The main data-consistency risks during failover are replication lag, duplicate requests, stale reads, concurrent writes, unsafe failback and replication of incorrect data.

For ELITE SPARK, these risks are mitigated by keeping one active write region at a time, using DynamoDB Global Tables for replication, unique transaction IDs for duplicate protection, controlled failover/failback procedures, recovery verification, and DynamoDB PITR for historical recovery.

The most important design rule is:

> **During disaster recovery, availability should not be achieved by allowing uncontrolled writes in both regions.**

---

## Interview Answer

> The main data-consistency risks during failover are replication lag, split-brain writes, duplicate transactions, stale reads and unsafe failback. Because DynamoDB Global Tables replicate asynchronously, the latest Hyderabad write may not immediately be visible in Mumbai. I reduce this risk by using a low RPO target and verifying critical data after failover. I also use a single-writer model, where Hyderabad is the normal writer and Mumbai becomes the writer only after failover. Unique transaction IDs and idempotent request handling help prevent duplicate financial transactions. Before failback, I verify that recent Mumbai writes have synchronized back to Hyderabad. PITR is also important because replication can copy incorrect data as well as correct data.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 10:** Data Consistency Risks and Mitigation During Failover
