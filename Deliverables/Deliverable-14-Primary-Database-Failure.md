# Deliverable 14 — Primary Database Failure During High Traffic

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**Database:** DynamoDB Global Table — `FIN-TRANSACTIONS`  
**DR Strategy:** Warm Disaster Recovery

---

## 1. Objective

This scenario explains what should happen if the Hyderabad database path becomes unavailable during a high-traffic period.

The main goals are:

```text
Detect the database problem
        ↓
Protect data consistency
        ↓
Move application traffic to the DR region
        ↓
Scale the DR application if required
        ↓
Verify data and service health
        ↓
Continue business operations
```

---

## 2. Normal Operation

Under normal conditions:

```text
Users
  ↓
Route 53
  ↓
HYD-ALB
  ↓
HYD-APP-ASG
  ↓
Hyderabad Application
  ↓
FIN-TRANSACTIONS
DynamoDB
```

The DynamoDB Global Table also keeps a replica in Mumbai:

```text
HYD FIN-TRANSACTIONS
        ↓
Global Table Replication
        ↓
MUM FIN-TRANSACTIONS
```

Normal operational model:

```text
Hyderabad = Active application/write region
Mumbai    = Warm DR region
```

---

## 3. Failure Scenario

Assume the Hyderabad database path becomes unavailable while many users are creating transactions.

Possible effects include:

- transaction requests failing,
- increased application errors,
- slower response times,
- retry traffic increasing,
- duplicate-request risk,
- stale or incomplete data during the transition.

The failure path may look like:

```text
High User Traffic
      ↓
HYD Application
      ↓
Primary Database Path Unavailable
      ↓
Transaction Errors / Timeouts
      ↓
Monitoring Detects Problem
```

---

## 4. Step 1 — Detect the Database Failure

CloudWatch monitoring should detect database problems.

Important signals include:

```text
DynamoDB SystemErrors
DynamoDB ThrottledRequests
Application Errors
ALB Latency
Unhealthy Targets
```

Project alarm:

```text
HYD-DYNAMODB-SYSTEM-ERROR
```

Detection flow:

```text
Database Problem
      ↓
CloudWatch Metric
      ↓
Alarm State
      ↓
SNS Alert
      ↓
Operator / Recovery Process
```

---

## 5. Step 2 — Confirm It Is a Database Problem

Before failover, confirm that the issue is not only:

- one EC2 instance,
- one Docker container,
- ALB target health,
- temporary application error,
- or capacity pressure.

The sequence should be:

```text
CloudWatch Alert
      ↓
Check DynamoDB Metrics
      ↓
Check Application Logs / Errors
      ↓
Check ALB Health and Latency
      ↓
Confirm Database Path Failure
```

This avoids unnecessary regional failover.

---

## 6. Step 3 — Protect Against Split-Brain Writes

During a database failover, both regions should not independently accept uncontrolled writes.

The project uses a single-writer operational model:

```text
Before Failure:
HYD = Active Writer

During DR:
MUM = Active Writer
```

The main rule is:

```text
Do not allow uncontrolled HYD + MUM writes
at the same time
```

This reduces:

- conflicting updates,
- duplicate transactions,
- inconsistent financial records.

---

## 7. Step 4 — Use the Mumbai Database Replica

The Mumbai DynamoDB replica is already available through the Global Table.

```text
HYD Database Path
      ❌
       ↓
MUM DynamoDB Replica
      ✅
```

Because the database is replicated in advance, the DR application does not need to restore the entire database before serving users.

This is one of the main advantages of the warm DR design.

---

## 8. Step 5 — Redirect Application Traffic

If the Hyderabad application is no longer able to serve requests correctly, traffic should move to Mumbai.

```text
finance.best.2bd.net
        ↓
Route 53
        ↓
HYD Primary Endpoint Unhealthy
        ↓
MUM Secondary Endpoint
```

Recovery path:

```text
User
  ↓
Route 53
  ↓
MUM-ALB
  ↓
MUM-APP-ASG
  ↓
Mumbai Application
  ↓
Mumbai DynamoDB Replica
```

---

## 9. Step 6 — Handle High Traffic in Mumbai

The Mumbai Auto Scaling Group was designed as:

```text
Minimum = 1
Desired = 1
Maximum = 2
```

During high traffic:

```text
Traffic Moves to Mumbai
        ↓
CPU / Load Increases
        ↓
Auto Scaling Evaluates Demand
        ↓
Additional Instance Can Be Launched
        ↓
ALB Distributes Traffic
```

This allows the DR application to increase capacity instead of relying on only one instance.

Important limitation:

```text
MUM max_size = 2
```

So the DR environment has less maximum capacity than the Hyderabad primary environment.

For a larger production workload, the DR capacity limit should be increased before or during failover.

---

## 10. Step 7 — Verify Data Consistency

Because Global Table replication is asynchronous, the latest Hyderabad write may not immediately exist in Mumbai.

Project RPO target:

```text
≤ 1 minute
```

Observed replication visibility during testing:

```text
3.97 seconds
```

After failover:

```text
Check Critical Transactions
        ↓
Verify Recent Records Exist
        ↓
Check for Missing / Duplicate Transactions
        ↓
Continue DR Operations
```

The 3.97-second value is a project observation, not a guaranteed replication time.

---

## 11. Step 8 — Prevent Duplicate Transactions

High traffic increases retry behavior.

Example:

```text
User Sends Transaction
      ↓
HYD Processes Request
      ↓
Connection Fails
      ↓
User Retries
      ↓
MUM Receives Same Request
```

To reduce duplicate financial records:

```text
Use Unique transaction_id
        ↓
Check if Transaction Already Exists
        ↓
If Yes → Return Existing Result
If No  → Create Transaction
```

This is called idempotent request handling.

---

## 12. Step 9 — Monitor the DR Region

After failover, monitoring should continue.

Important checks:

```text
MUM Application Health
MUM Target Health
CPU Utilization
Application Latency
DynamoDB Errors
DynamoDB Throttling
Recent Transaction Verification
```

The DR environment should be treated as the active production path during the incident.

---

## 13. Step 10 — Continue Business Operations

Once Mumbai is stable:

```text
Users
  ↓
MUM-ALB
  ↓
MUM Application
  ↓
MUM DynamoDB
```

The application continues operating while Hyderabad is investigated and repaired.

At this point:

```text
Mumbai = Active DR Region
Hyderabad = Recovery / Investigation
```

---

## 14. Failback Sequence

Traffic should not immediately return to Hyderabad after the database becomes available again.

Safe failback:

```text
HYD Database Restored
        ↓
Verify DynamoDB Health
        ↓
Verify Global Table Replication
        ↓
Confirm Recent MUM Writes Exist in HYD
        ↓
Verify HYD Application Health
        ↓
Move HYD Back to Active Writer
        ↓
Route Traffic Back to Hyderabad
```

This prevents data loss during failback.

---

## 15. Complete Incident Sequence

```text
HIGH TRAFFIC
     ↓
HYD Application
     ↓
Database Failure
     ↓
CloudWatch Detects Errors
     ↓
SNS Alert
     ↓
Confirm Database Issue
     ↓
Prevent Dual-Region Writes
     ↓
Use MUM DynamoDB Replica
     ↓
Route 53 Redirects Traffic
     ↓
MUM-ALB
     ↓
MUM-APP-ASG
     ↓
Scale if Required
     ↓
Verify Transactions
     ↓
Monitor DR Environment
     ↓
Continue Service
```

---

## 16. Main Risks During High Traffic

| Risk | Mitigation |
|---|---|
| Large request backlog | Auto Scaling + ALB |
| DR capacity too small | Scale MUM ASG within configured limits |
| Replication lag | Low RPO + transaction verification |
| Duplicate retries | Unique transaction IDs / idempotency |
| Split-brain writes | Single-writer operational model |
| High latency | CloudWatch latency monitoring |
| DynamoDB throttling | Monitor throttling and capacity behavior |
| Unsafe failback | Verify synchronization before returning to HYD |

---

## 17. Important Current Limitation

The Mumbai DR ASG is smaller than the Hyderabad production ASG.

```text
HYD:
min = 2
desired = 2
max = 4

MUM:
min = 1
desired = 1
max = 2
```

Therefore, during a very large traffic spike, Mumbai may have less capacity than Hyderabad.

For production:

```text
Increase DR max capacity
        or
Pre-scale Mumbai during a known high-risk period
```

This is an important DR capacity-planning requirement.

---

## 18. Monitoring Relationship

The database-failure sequence depends on monitoring.

```text
Database Failure
      ↓
CloudWatch
      ↓
Alarm
      ↓
SNS
      ↓
Recovery Decision
      ↓
Failover
```

Monitoring reduces the time between failure and recovery.

---

## 19. Conclusion

If the Hyderabad database becomes unavailable during a high-traffic period, the application may initially experience transaction errors or timeouts.

The recovery process is to:

```text
Detect
  ↓
Confirm
  ↓
Protect Writes
  ↓
Fail Over
  ↓
Scale
  ↓
Verify Data
  ↓
Continue Service
```

The Mumbai DynamoDB replica already exists through DynamoDB Global Tables, so the DR application can continue using replicated transaction data without waiting for a full database restore.

Route 53 redirects application traffic to Mumbai, while the Mumbai Auto Scaling Group can add capacity up to its configured maximum.

Data verification, idempotent transaction handling and a controlled failback process are essential to avoid duplicate or inconsistent financial records.

---

## Interview Answer

> If the primary Hyderabad database became unavailable during high traffic, I would first detect the problem using CloudWatch metrics such as DynamoDB SystemErrors, throttling, ALB latency and application errors. After confirming that the issue is database-related, I would avoid uncontrolled writes in both regions and move the active application path to Mumbai. Route 53 would redirect users to the Mumbai ALB, where the DR Auto Scaling Group serves the application using the Mumbai DynamoDB Global Table replica. Because traffic is high, I would closely monitor CPU, latency, target health and DynamoDB throttling and allow the DR Auto Scaling Group to scale within its configured capacity. I would then verify recent critical transactions and use unique transaction IDs or idempotent logic to prevent duplicates caused by retries. After Hyderabad is restored, I would verify replication and data consistency before failing traffic back.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 14:** Primary Database Failure During High-Traffic Period — Recovery Sequence
