# Deliverable 05 — Database Protection Strategy

## Project: ELITE SPARK

**Database:** DynamoDB  
**Table:** `FIN-TRANSACTIONS`  
**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)

---

## 1. Objective

The database must be protected against:

- accidental deletion,
- logical corruption,
- infrastructure failure,
- and regional failure.

The ELITE SPARK project uses a layered protection strategy:

```text
DynamoDB Global Tables
        +
Point-in-Time Recovery (PITR)
        +
IAM Access Control
        +
Warm Disaster Recovery
```

---

## 2. Database Protection Architecture

```text
                    HYDERABAD
                  Primary Region
                       │
                       ▼
                FIN-TRANSACTIONS
                   DynamoDB
                       │
                       │ Global Table Replication
                       ▼
                FIN-TRANSACTIONS
                   DynamoDB
                       │
                       ▼
                     MUMBAI
                    DR Region
```

Historical recovery is provided through PITR:

```text
FIN-TRANSACTIONS
       │
       ▼
DynamoDB PITR
       │
       ▼
Historical Recovery Point
       │
       ▼
Restored Table
```

---

## 3. Protection Against Accidental Deletion

If a transaction is accidentally deleted:

```text
Correct transaction
       ↓
Accidental deletion
       ↓
Data is missing from current table
```

The project uses **DynamoDB Point-in-Time Recovery (PITR)**.

Recovery flow:

```text
Accidental deletion
      ↓
Choose recovery point before deletion
      ↓
DynamoDB PITR
      ↓
Restore a new table
      ↓
Verify recovered data
```

---

## 4. PITR Recovery Test

A recovery test was completed using:

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

This proved that historical transaction data could be recovered after deletion.

---

## 5. Protection Against Data Corruption

Replication alone is not enough to protect against logical corruption.

Example:

```text
Incorrect update in Hyderabad
          ↓
Global Table replication
          ↓
Incorrect data may also reach Mumbai
```

Therefore:

```text
Global Table ≠ Backup
```

The project combines:

```text
Global Table → Availability
PITR         → Historical Recovery
```

This protects against both regional outages and logical data issues.

---

## 6. Protection Against Infrastructure Failure

DynamoDB is an AWS-managed database service.

The application does not depend on a manually managed database EC2 instance.

```text
Application
    ↓
AWS-managed DynamoDB
```

This removes risks associated with:

- database server OS failure,
- database process failure,
- single server hardware failure,
- manual patching,
- direct disk management.

---

## 7. Protection Against Regional Failure

The project uses a DynamoDB Global Table across Hyderabad and Mumbai.

```text
HYD FIN-TRANSACTIONS
        │
        │ Asynchronous Replication
        ▼
MUM FIN-TRANSACTIONS
```

If Hyderabad becomes unavailable:

```text
HYD unavailable
      ↓
Route 53 failover
      ↓
Mumbai application
      ↓
Mumbai DynamoDB replica
```

This supports business continuity during regional failure.

---

## 8. RPO Protection

Project RPO target:

```text
≤ 1 minute
```

Observed replication visibility:

```text
3.97 seconds
```

Result:

```text
Observed RPO result was within project target ✅
```

> The 3.97-second value is an observed project test result, not a guaranteed AWS replication SLA.

---

## 9. IAM Protection

The application used:

```text
APP-EC2-ROLE
```

Required DynamoDB permissions included:

```text
dynamodb:GetItem
dynamodb:PutItem
dynamodb:UpdateItem
dynamodb:Query
dynamodb:Scan
```

This follows the principle of least privilege.

```text
Application
   ↓
IAM Role
   ↓
Allowed DynamoDB actions
   ↓
FIN-TRANSACTIONS
```

The application did not require unrestricted DynamoDB administrative permissions.

---

## 10. Global Tables vs PITR

| Protection Requirement | Global Table | PITR |
|---|---|---|
| Regional failure | ✅ | ❌ |
| Database availability in DR | ✅ | ❌ |
| Cross-region replication | ✅ | ❌ |
| Accidental deletion recovery | ❌ | ✅ |
| Logical corruption recovery | ❌ | ✅ |
| Historical recovery | ❌ | ✅ |

Therefore:

```text
Global Table + PITR
=
Availability + Recoverability
```

---

## 11. Failure Scenarios

### Regional Failure

```text
HYD unavailable
      ↓
Mumbai application
      ↓
Mumbai DynamoDB replica
```

Protection:

```text
DynamoDB Global Table
```

### Accidental Deletion

```text
Transaction deleted
      ↓
PITR recovery point
      ↓
Restore historical table
```

Protection:

```text
DynamoDB PITR
```

### Incorrect Data Update

```text
Incorrect update
      ↓
Bad data replicated
      ↓
Restore earlier clean state
```

Protection:

```text
DynamoDB PITR
```

### Unauthorized Access

```text
Application
     ↓
IAM authorization
     ↓
Allowed / Denied
```

Protection:

```text
IAM role-based access control
```

---

## 12. Complete Protection Strategy

```text
                        APPLICATION
                             │
                             ▼
                       IAM ROLE
                             │
                             ▼
                 HYD FIN-TRANSACTIONS
                             │
             ┌───────────────┴───────────────┐
             │                               │
             ▼                               ▼
      DynamoDB Global Table             DynamoDB PITR
             │                               │
             ▼                               ▼
    MUM FIN-TRANSACTIONS             Historical Recovery
             │                               │
             ▼                               ▼
     Regional DR Access                Restored Table
```

---

## 13. Protection Layers

| Layer | Purpose |
|---|---|
| DynamoDB managed infrastructure | Reduces single-server database risk |
| DynamoDB Global Tables | Provides cross-region database availability |
| Mumbai replica | Supports DR database access |
| DynamoDB PITR | Recovers from deletion and corruption |
| IAM | Restricts application permissions |
| Route 53 + Warm DR | Allows application failover to Mumbai |
| CloudWatch | Helps detect database and application issues |

---

## 14. Important Limitation

DynamoDB Global Tables use asynchronous replication.

```text
Write in Hyderabad
        ↓
Replication delay
        ↓
Visible in Mumbai
```

A short delay can exist.

Also, bad logical changes can replicate to the secondary region.

Therefore:

```text
Replication ≠ Backup
```

PITR is required for historical recovery.

---

## 15. Conclusion

The ELITE SPARK database uses multiple protection layers.

```text
Global Tables → Availability
PITR          → Recovery
IAM           → Access Protection
Warm DR       → Business Continuity
```

DynamoDB Global Tables protect the application during regional failure by keeping a replica in Mumbai.

DynamoDB PITR protects against accidental deletion and logical corruption by allowing recovery to an earlier point in time.

IAM role-based permissions reduce unnecessary database access.

Together, these controls protect the database against infrastructure failure, regional failure, accidental deletion, and corruption.

---

## Interview Answer

> The database is protected using multiple layers. DynamoDB Global Tables replicate `FIN-TRANSACTIONS` between Hyderabad and Mumbai, so a regional infrastructure failure does not leave the DR application without database access. Replication alone is not a backup because accidental deletion or corruption can also be replicated, so DynamoDB Point-in-Time Recovery is enabled. I verified this by restoring historical transaction data into a temporary recovery table. IAM role-based permissions also restrict the application to only the DynamoDB operations it needs. Global Tables provide availability, PITR provides historical recovery, and IAM provides access control.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 05:** Database Protection Against Accidental Deletion, Corruption and Infrastructure Failure
