# Deliverable 06 — Backup Strategy, Retention, Restoration and Verification

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**Database:** DynamoDB `FIN-TRANSACTIONS`  
**Object Storage:** Amazon S3

---

## 1. Objective

The backup strategy must answer four questions:

```text
What data are we protecting?
        ↓
How long do we retain recoverable copies?
        ↓
How do we restore them?
        ↓
How do we verify the restored data?
```

The project uses two main recovery layers:

```text
Database
   ↓
DynamoDB PITR

Object Storage
   ↓
S3 Versioning + Lifecycle + Cross-Region Replication
```

Important principle:

```text
Replication ≠ Backup
```

Replication improves availability, while PITR and version history provide recovery from deletion or corruption.

---

## 2. Backup Strategy Overview

| Data | Protection Method | Purpose |
|---|---|---|
| DynamoDB transactions | Point-in-Time Recovery (PITR) | Recover deleted or corrupted database state |
| DynamoDB regional availability | Global Tables | Maintain database copy in Mumbai |
| S3 objects | Versioning | Preserve previous object versions |
| Old S3 versions | Lifecycle policy | Control retention and storage cost |
| S3 regional protection | Cross-Region Replication | Maintain copy in Mumbai |
| Infrastructure | Terraform code | Rebuild infrastructure |
| Application | GitHub + Docker/ECR | Preserve source and deployable image |

---

## 3. DynamoDB Backup Strategy

Main table:

```text
FIN-TRANSACTIONS
```

DynamoDB Point-in-Time Recovery was enabled.

```text
FIN-TRANSACTIONS
       ↓
Continuous PITR
       ↓
Choose Earlier Recovery Point
       ↓
Restore New Table
```

PITR is used for recovery from:

- accidental deletion,
- incorrect updates,
- logical corruption,
- unwanted application changes.

---

## 4. DynamoDB Retention

DynamoDB PITR provides continuous recovery within its configured recovery window.

The project uses PITR as the main short-term database recovery method.

```text
Continuous Recovery → DynamoDB PITR
Regional Availability → DynamoDB Global Tables
```

For long-term archival beyond the PITR window, a production design could add on-demand DynamoDB backups or AWS Backup.

---

## 5. DynamoDB Restoration

A real restore test was performed.

Restored table:

```text
FIN-TRANSACTIONS-RESTORE-DEMO
```

Recovered transaction:

```text
Transaction ID : TXN-C3D4BBBA03DA
Customer       : DELETE-RESTORE-DEMO
Amount         : 500
Type           : CREDIT
Status         : SUCCESS
```

Restore flow:

```text
Accidental / Controlled Data Loss
        ↓
Choose Recovery Time
        ↓
DynamoDB PITR
        ↓
Restore New Table
        ↓
Query Recovered Transaction
```

---

## 6. DynamoDB Backup Verification

A backup is useful only if restoration can be verified.

Verification process:

```text
Restore Completed
      ↓
Restored Table Active
      ↓
Query Expected Transaction
      ↓
Compare Transaction Fields
      ↓
Data Verified
```

Verified fields included:

- transaction ID,
- customer,
- amount,
- transaction type,
- status.

Result:

```text
Backup configured   ✅
Restore performed   ✅
Recovered data read ✅
Data verified       ✅
```

---

## 7. S3 Backup Strategy

The project used S3 in both regions.

```text
HYD S3
   │
   │ Cross-Region Replication
   ▼
MUM S3
```

Protection layers:

```text
S3 Versioning
      +
Lifecycle Management
      +
Cross-Region Replication
      +
Encryption
```

---

## 8. S3 Retention

S3 Versioning preserves previous versions of objects.

The lifecycle policy retained noncurrent object versions for:

```text
30 days
```

Then old noncurrent versions were expired.

```text
Current Version
      ↓
Kept as active object

Old Version
      ↓
Retained for 30 days
      ↓
Lifecycle expiration
```

This balances:

```text
Recoverability + Cost Control
```

---

## 9. S3 Restoration

If an object is accidentally overwritten or deleted:

```text
Original Object
      ↓
Accidental Update/Delete
      ↓
Previous Version Still Exists
      ↓
Select Previous Version
      ↓
Restore / Copy as Current Version
```

Cross-Region Replication also maintains a regional copy:

```text
HYD Object
    ↓
CRR
    ↓
MUM Object Copy
```

So:

```text
Versioning → Logical Recovery
CRR        → Regional Protection
```

---

## 10. S3 Verification

Backup and replication should be verified.

Verification flow:

```text
Upload Object in HYD
      ↓
Confirm Version Exists
      ↓
Confirm Replicated Object in MUM
      ↓
Restore Previous Version if Required
      ↓
Verify Object is Readable
```

Verification checks:

- object exists,
- previous version exists,
- replicated object exists in Mumbai,
- restored object is readable,
- expected content is correct.

---

## 11. Complete Backup Architecture

```text
                         APPLICATION DATA
                                │
              ┌─────────────────┴─────────────────┐
              │                                   │
              ▼                                   ▼
         DYNAMODB                               S3
    FIN-TRANSACTIONS                       Critical Objects
              │                                   │
      ┌───────┴────────┐                 ┌────────┴─────────┐
      │                │                 │                  │
      ▼                ▼                 ▼                  ▼
     PITR        Global Table        Versioning             CRR
      │                │                 │                  │
      ▼                ▼                 ▼                  ▼
Historical          Mumbai          Previous            Mumbai
Recovery            Replica         Versions             Copy
      │                                  │
      ▼                                  ▼
Restore New Table                   Restore Object
```

---

## 12. Retention Summary

| Backup Layer | Retention |
|---|---|
| DynamoDB PITR | Continuous recovery within configured PITR window |
| S3 current versions | Kept as active objects |
| S3 noncurrent versions | **30 days** |
| S3 Mumbai replica | Maintained through CRR |
| Terraform code | Retained in repository |
| Application source | Retained in GitHub |

---

## 13. Restoration Summary

### Database

```text
PITR
 ↓
Select Recovery Time
 ↓
Restore New Table
 ↓
Verify Transaction Data
```

### S3

```text
Select Previous Version
 ↓
Retrieve Old Version
 ↓
Restore as Current Object
 ↓
Verify Contents
```

### Regional Failure

```text
HYD Unavailable
 ↓
MUM Replicated Data
 ↓
DR Application Continues
```

---

## 14. Failure Protection Mapping

| Failure | Protection |
|---|---|
| Accidental database deletion | DynamoDB PITR |
| Database corruption | DynamoDB PITR |
| Hyderabad database outage | DynamoDB Global Table |
| S3 accidental overwrite | S3 Versioning |
| S3 accidental deletion | Previous version recovery |
| Old S3 versions consuming storage | 30-day lifecycle |
| Regional S3 failure | S3 CRR |
| Infrastructure loss | Terraform |
| Application source loss | GitHub |

---

## 15. Important Design Principle

```text
HIGH AVAILABILITY ≠ BACKUP
```

Example:

```text
Bad Database Update
        ↓
Replicates to DR Region
```

The DR replica may also receive incorrect data.

Therefore:

```text
Global Table = Availability
PITR         = Recovery
```

Similarly:

```text
S3 CRR      = Regional Copy
S3 Versioning = Historical Recovery
```

---

## 16. Backup Verification Checklist

| Check | Result |
|---|---|
| DynamoDB PITR enabled | ✅ |
| DynamoDB restore performed | ✅ |
| Restored transaction verified | ✅ |
| S3 Versioning enabled | ✅ |
| S3 lifecycle retention configured | ✅ |
| S3 CRR implemented | ✅ |
| Mumbai S3 copy used for regional protection | ✅ |

---

## 17. Conclusion

The ELITE SPARK backup strategy uses multiple recovery mechanisms.

For database data:

```text
DynamoDB PITR
→ accidental deletion and corruption recovery

DynamoDB Global Tables
→ regional availability
```

For object data:

```text
S3 Versioning
→ previous-version recovery

30-day Lifecycle
→ retention and cost control

S3 CRR
→ regional protection
```

The most important part of the strategy was not only enabling backup features, but also performing a real restoration and verifying the recovered data.

The DynamoDB PITR test restored `FIN-TRANSACTIONS-RESTORE-DEMO` and successfully recovered the expected transaction.

---

## Interview Answer

> Our backup strategy separates availability from recovery. DynamoDB Global Tables provide a replicated database in Mumbai for regional availability, while Point-in-Time Recovery protects against accidental deletion and logical corruption. I demonstrated PITR by restoring the database into a new table and verifying a known transaction. For S3, versioning preserves earlier object versions, Cross-Region Replication creates a copy in Mumbai, and a lifecycle policy retains noncurrent versions for 30 days before expiration. During recovery, we restore the required DynamoDB point in time or previous S3 object version and then verify that the restored data is readable and correct.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 06:** Backup Strategy, Retention, Restoration and Verification
