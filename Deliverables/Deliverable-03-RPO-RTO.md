# Deliverable 03 — RPO and RTO

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**DR Strategy:** Warm Disaster Recovery

---

## 1. Recovery Objectives

| Objective | Target | Observed Result |
|---|---:|---:|
| **RPO** | **≤ 1 minute** | **3.97 seconds** |
| **RTO** | **≤ 5 minutes** | **94.97 seconds (~1 min 35 sec)** |

> The observed values are project test results, not guaranteed AWS SLAs.

---

## 2. What is RPO?

**Recovery Point Objective (RPO)** defines how much recent data loss the business can tolerate after a disaster.

Simple meaning:

> **RPO = How much data can we afford to lose?**

For ELITE SPARK:

```text
Target RPO = ≤ 1 minute
```

The project uses **DynamoDB Global Tables** to replicate transaction data from Hyderabad to Mumbai.

### RPO Flow

```text
HYD Application
      ↓
DynamoDB
FIN-TRANSACTIONS
      ↓
Cross-Region Replication
      ↓
MUM DynamoDB Replica
```

### RPO Test Result

Test transaction:

```text
RPO-PROOF-20260913-232046
```

Observed:

```text
HYD write time  ≈ 23:21:04
MUM visibility ≈ 23:21:08
```

Observed replication visibility:

```text
3.97 seconds
```

### Result

```text
RPO Target  = ≤ 60 seconds
Observed    = 3.97 seconds

Status      = ✅ Target met
```

---

## 3. Why RPO Target is 1 Minute

The application represents a financial transaction workload, so recent transaction data is important.

A low RPO is suitable because:

- DynamoDB Global Tables continuously replicate data.
- The DR region already has a replica.
- A one-minute target limits possible recent data loss.
- It is realistic for an asynchronous replication design.

Important:

> **3.97 seconds is an observed test result, not a guaranteed RPO.**

---

## 4. What is RTO?

**Recovery Time Objective (RTO)** defines how long the application can remain unavailable after a disaster.

Simple meaning:

> **RTO = How long can the service be down?**

For ELITE SPARK:

```text
Target RTO = ≤ 5 minutes
```

---

## 5. RTO Recovery Flow

```text
HYD Failure
    ↓
Primary endpoint becomes unhealthy
    ↓
Route 53 failover
    ↓
MUM ALB
    ↓
MUM Application
    ↓
Application available again
```

Mumbai is a **warm DR region**, so the required infrastructure already exists.

This reduces recovery time compared with rebuilding everything after a disaster.

---

## 6. RTO Test Result

Latest controlled test:

```text
Failure initiated:
23:32:10

Service restored through Mumbai:
23:33:45
```

Observed recovery time:

```text
94.97 seconds
≈ 1 minute 35 seconds
```

### Result

```text
RTO Target  = ≤ 300 seconds
Observed    = 94.97 seconds

Status      = ✅ Target met
```

---

## 7. Why RTO Target is 5 Minutes

A five-minute target is suitable because the project uses a warm DR architecture.

The Mumbai region already contains:

- DR VPC
- MUM ALB
- Auto Scaling Group
- EC2 application instances
- Docker application
- DynamoDB Global Table replica
- Regional ECR repository

Therefore recovery mainly depends on:

- failure detection
- Route 53 failover
- DNS/client behavior
- connection to the DR application

---

## 8. Why RPO and RTO Are Not Zero

### RPO is not zero

DynamoDB Global Tables use asynchronous replication.

```text
Write in HYD
    ↓
Replication delay
    ↓
Visible in MUM
```

A short replication delay can exist.

Therefore:

```text
RPO = 0
```

should not be claimed.

### RTO is not zero

Warm DR still requires:

```text
Failure detection
      ↓
Health checks
      ↓
DNS failover
      ↓
User reconnects to DR
```

Therefore:

```text
RTO = 0
```

is also not realistic for this design.

---

## 9. RPO vs RTO

| RPO | RTO |
|---|---|
| Focuses on **data loss** | Focuses on **downtime** |
| "How much data can we lose?" | "How long can service be unavailable?" |
| Target: **≤ 1 minute** | Target: **≤ 5 minutes** |
| Observed: **3.97 sec** | Observed: **94.97 sec** |

Simple memory:

```text
RPO → DATA
RTO → TIME
```

---

## 10. AWS Services Supporting the Targets

| AWS Service / Component | Contribution |
|---|---|
| DynamoDB Global Tables | Reduces RPO using cross-region replication |
| DynamoDB PITR | Provides historical recovery |
| S3 Cross-Region Replication | Protects object data in another region |
| S3 Versioning | Protects previous object versions |
| Route 53 Failover | Redirects users to the DR region |
| MUM Warm DR | Reduces recovery time |
| Application Load Balancer | Sends traffic to healthy targets |
| Auto Scaling Group | Maintains application capacity |
| CloudWatch | Detects failures and health issues |
| SNS | Sends incident alerts |
| ECR in both regions | Keeps container images regionally available |

---

## 11. Final Recovery Objective

```text
┌────────────────────────────────────────────┐
│        ELITE SPARK DR OBJECTIVES           │
├────────────────────────────────────────────┤
│ RPO Target     : ≤ 1 minute                │
│ RPO Observed   : 3.97 seconds              │
│                                            │
│ RTO Target     : ≤ 5 minutes               │
│ RTO Observed   : 94.97 seconds             │
│                  (~1 min 35 sec)            │
│                                            │
│ DR Strategy    : Warm DR                   │
│ Primary        : Hyderabad (ap-south-2)    │
│ DR Region      : Mumbai (ap-south-1)       │
└────────────────────────────────────────────┘
```

---

## 12. Conclusion

The ELITE SPARK project defines:

```text
RPO Target = ≤ 1 minute
RTO Target = ≤ 5 minutes
```

During testing:

```text
Observed RPO = 3.97 seconds
Observed RTO = 94.97 seconds
```

Both observed results were within the project targets.

The low RPO is supported by **DynamoDB Global Tables**, while the low RTO is supported by **warm DR infrastructure, Route 53 failover, ALB, and Auto Scaling**.

---

## Interview Answer

> RPO defines the maximum acceptable data loss, while RTO defines the maximum acceptable downtime after a disaster. For the ELITE SPARK project, I defined an RPO target of one minute or less and an RTO target of five minutes or less. During testing, DynamoDB cross-region replication was observed at approximately 3.97 seconds, and regional service recovery through Mumbai was observed at approximately 94.97 seconds. These are project test results, not guaranteed AWS SLAs.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 03:** RPO and RTO Definition, Targets and Justification
