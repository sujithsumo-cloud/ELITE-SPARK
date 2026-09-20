# Deliverable 15 — Disaster Recovery Runbook

## Project: ELITE SPARK

**Purpose:** Operational runbook for another engineer to detect, fail over, verify, operate, and fail back the ELITE SPARK financial application without requiring assistance from the original implementer.

**Primary Region:** Hyderabad (`ap-south-2`)  
**Recovery Region:** Mumbai (`ap-south-1`)  
**Application DNS:** `finance.best.2bd.net`  
**Database:** DynamoDB Global Table `FIN-TRANSACTIONS`  
**DR Model:** Warm Disaster Recovery  
**Target RTO:** `≤ 5 minutes`  
**Target RPO:** `≤ 1 minute`

---

# 1. Runbook Scope

Use this runbook for:

- primary-region application failure,
- ALB or target failure,
- EC2/Auto Scaling failure,
- primary database-path failure,
- serious regional service degradation,
- controlled disaster-recovery testing,
- failback from Mumbai to Hyderabad.

This runbook covers the implemented project architecture:

```text
Route 53
   ↓
HYD-ALB / MUM-ALB
   ↓
Target Group
   ↓
Auto Scaling Group
   ↓
Private EC2
   ↓
Docker finance-app
   ↓
DynamoDB Global Table
```

Supporting recovery services:

```text
S3 Versioning + CRR
ECR in both regions
CloudWatch
SNS
IAM
KMS
Terraform
GitHub Actions
```

---

# 2. Important Safety Rules

Before making any change:

1. Confirm that you are working on **ELITE SPARK** resources.
2. Confirm the AWS Region before every operation.
3. Do **not** modify unrelated `OrionShift` resources in Mumbai.
4. Do not delete or modify the shared Route 53 hosted zone.
5. Do not delete the shared GitHub OIDC provider.
6. Do not make both regions active writers without a controlled plan.
7. Do not perform destructive database operations during failover.
8. Do not disable monitoring while troubleshooting.
9. Do not change Terraform state manually.
10. Record timestamps for every major recovery step.

Mumbai contains unrelated infrastructure, so resource names and tags must be checked carefully before any action.

---

# 3. Key Resource Reference

## Hyderabad — Primary

```text
Region       : ap-south-2
VPC          : PRI-VPC
CIDR         : 10.0.0.0/16

ALB          : HYD-ALB
Target Group : HYD-APP-TG
ASG          : HYD-APP-ASG
App SG       : HYD-APP-SG
ALB SG       : HYD-ALB-SG
Endpoint SG  : HYD-ENDPOINT-SG

ECR          : finance-app
DynamoDB     : FIN-TRANSACTIONS
Dashboard    : HYD-DR-DASHBOARD
SNS          : HYD-ALERTS
```

Normal ASG capacity:

```text
Minimum = 2
Desired = 2
Maximum = 4
```

---

## Mumbai — Disaster Recovery

```text
Region       : ap-south-1
VPC          : DR-VPC
CIDR         : 10.1.0.0/16

ALB          : MUM-ALB
Target Group : MUM-APP-TG
ASG          : MUM-APP-ASG
App SG       : MUM-APP-SG
ALB SG       : MUM-ALB-SG
Endpoint SG  : MUM-ENDPOINT-SG

ECR          : finance-app
DynamoDB     : FIN-TRANSACTIONS replica
```

Normal DR ASG capacity:

```text
Minimum = 1
Desired = 1
Maximum = 2
```

---

# 4. Normal Traffic Flow

```text
User
  ↓
finance.best.2bd.net
  ↓
Route 53
  ↓
HYD-ALB
  ↓
HYD-APP-TG
  ↓
HYD-APP-ASG
  ↓
Docker finance-app
  ↓
FIN-TRANSACTIONS
```

Mumbai remains available as the warm recovery environment.

---

# 5. Monitoring Reference

Important CloudWatch alarms:

```text
HYD-APP-HIGH-CPU
HYD-APP-UNHEALTHY-TARGET
HYD-DYNAMODB-SYSTEM-ERROR
HYD-ALB-HIGH-LATENCY
HYD-S3-REPLICATION-FAILURE
```

Dashboard:

```text
HYD-DR-DASHBOARD
```

Notification topic:

```text
HYD-ALERTS
```

Always check:

- target health,
- EC2/ASG capacity,
- CPU,
- ALB response time,
- DynamoDB errors,
- DynamoDB throttling,
- S3 replication health.

---

# 6. Incident Record Template

Create an incident record immediately.

```text
Incident ID:
Date:
Engineer:
Failure observed:
Failure start time:
Detection time:
Primary region status:
DR region status:
Failover start time:
Recovery time:
Observed RTO:
Data verification:
Failback time:
Final status:
Notes:
```

Do not rely on memory after the incident.

---

# 7. Step 1 — Confirm the Incident

When an alarm or user report arrives:

```text
Alert / User Report
        ↓
Open CloudWatch
        ↓
Check Dashboard
        ↓
Check ALB Target Health
        ↓
Check ASG / EC2
        ↓
Check DynamoDB
        ↓
Classify Failure
```

Classify the incident as one of:

```text
A. Single EC2 failure
B. Application/container failure
C. Primary ALB/target failure
D. Database-path failure
E. Regional / major infrastructure failure
```

Do not start regional failover for a simple single-instance problem if the primary region is still healthy.

---

# 8. Step 2 — Check Primary Application Health

Verify:

```text
https/http://finance.best.2bd.net
```

The implemented internship environment uses:

```text
HTTP :80
```

Check the Hyderabad target group.

Expected healthy state:

```text
HYD-APP-TG
      ↓
Healthy targets
```

If only one EC2 instance is unhealthy but other Hyderabad targets remain healthy:

```text
Allow ASG self-healing
        ↓
Verify replacement instance
        ↓
Confirm target becomes healthy
        ↓
No regional failover required
```

---

# 9. Step 3 — Check Hyderabad Auto Scaling

Open:

```text
EC2
→ Auto Scaling Groups
→ HYD-APP-ASG
```

Verify:

```text
Desired capacity
InService instances
Health status
Scaling activity
```

Normal state:

```text
2 healthy instances
```

If the ASG can replace the failed instance and the application remains available, keep traffic in Hyderabad.

---

# 10. Step 4 — Check Database Health

Open:

```text
DynamoDB
→ Tables
→ FIN-TRANSACTIONS
```

Check:

- table status,
- Global Table / replica status,
- `SystemErrors`,
- throttling,
- application transaction failures.

Database incident flow:

```text
Application Errors
      ↓
Check DynamoDB Metrics
      ↓
Confirm DB-path problem
```

Do not assume every application error is a DynamoDB failure.

---

# 11. Step 5 — Decide Whether Regional Failover Is Required

## Stay in Hyderabad when:

```text
At least one healthy application path exists
AND
Database access is working
AND
ASG can recover failed capacity
```

## Fail over to Mumbai when:

```text
Primary application path is unavailable
OR
Primary database path prevents correct operation
OR
Regional infrastructure is seriously degraded
OR
Recovery in Hyderabad cannot meet the RTO
```

Decision:

```text
Can HYD recover safely within RTO?
        │
   ┌────┴────┐
  Yes       No
   │         │
Recover      Fail over
in HYD       to MUM
```

---

# 12. Step 6 — Verify Mumbai Before Failover

Before depending on Mumbai, verify:

```text
MUM-ALB exists
MUM-APP-TG has healthy target(s)
MUM-APP-ASG has InService capacity
finance-app container is running
Mumbai DynamoDB replica is available
MUM ECR contains the expected image
```

Minimum acceptable DR application state:

```text
MUM-APP-ASG
Desired >= 1

MUM-APP-TG
Healthy target >= 1
```

If Mumbai is not healthy, fix the DR environment before redirecting production traffic.

---

# 13. Step 7 — Protect Data Consistency

Before a controlled failover, prevent uncontrolled writes in both regions.

Normal model:

```text
HYD = Active Writer
MUM = Standby
```

During DR:

```text
HYD = Removed / unavailable
MUM = Active Writer
```

Avoid:

```text
HYD Writes
   +
MUM Writes
at the same time
```

This reduces split-brain and conflicting financial transactions.

---

# 14. Step 8 — Fail Traffic to Mumbai

The project uses Route 53 failover routing.

Expected automated path:

```text
HYD endpoint becomes unhealthy
        ↓
Route 53 health/failover evaluation
        ↓
Mumbai secondary selected
        ↓
Users reach MUM-ALB
```

Verify DNS/application behavior from a client:

```text
finance.best.2bd.net
        ↓
MUM application response
```

Record:

```text
Failover start time:
First successful Mumbai response:
```

Do not claim recovery until the application response is verified.

---

# 15. Step 9 — Scale Mumbai if Required

Mumbai normal capacity:

```text
Min     = 1
Desired = 1
Max     = 2
```

During high traffic, monitor:

```text
CPU
TargetResponseTime
HealthyHostCount
Request rate
DynamoDB errors / throttling
```

If required and allowed by the current configuration:

```text
MUM-APP-ASG
      ↓
Scale toward max capacity
      ↓
New EC2 starts
      ↓
Docker finance-app starts
      ↓
Target Group health check
      ↓
ALB distributes traffic
```

Current limitation:

```text
Mumbai maximum = 2 instances
```

If demand exceeds this, production DR capacity would need to be increased.

---

# 16. Step 10 — Verify Database Data in Mumbai

Because DynamoDB Global Tables replicate asynchronously, verify important transactions.

Check:

```text
Recent transaction IDs
Customer IDs
Amounts
Transaction type
Status
Timestamp
```

Project RPO target:

```text
≤ 1 minute
```

Observed project replication visibility test:

```text
3.97 seconds
```

The 3.97-second value is a test observation, not a guaranteed AWS replication time.

---

# 17. Step 11 — Check for Duplicate Transactions

Network interruption during failover can cause retries.

Example:

```text
Transaction sent to HYD
        ↓
Response lost
        ↓
User retries
        ↓
Request reaches MUM
```

Use:

```text
transaction_id
```

to identify duplicates.

Preferred application behavior:

```text
Receive transaction_id
        ↓
Already exists?
   ┌────┴────┐
  Yes       No
   ↓         ↓
Return      Create
existing    transaction
result
```

Do not manually create a duplicate transaction to compensate for an uncertain request.

---

# 18. Step 12 — Verify S3 Recovery Data

If the incident involves S3 data:

```text
HYD S3
   ↓
Cross-Region Replication
   ↓
MUM S3
```

Verify:

- required object exists in Mumbai,
- correct object version exists,
- object is readable,
- replication status is healthy.

S3 versioning provides historical recovery.

CRR provides a regional copy.

```text
CRR ≠ Backup
Versioning = Historical Recovery
```

---

# 19. Step 13 — Declare DR Service Restored

Service can be declared recovered only when all required checks pass.

Checklist:

```text
[ ] finance.best.2bd.net responds
[ ] Response is served through Mumbai
[ ] MUM target group is healthy
[ ] MUM ASG has sufficient capacity
[ ] Docker application is healthy
[ ] DynamoDB reads/writes succeed
[ ] Critical transactions verified
[ ] No uncontrolled dual-region writes
[ ] Monitoring remains active
```

Record the recovery timestamp.

---

# 20. RTO Calculation

Calculate:

```text
RTO = Service recovery time - Failure start time
```

Project target:

```text
≤ 5 minutes
```

Latest controlled test:

```text
Failure initiated : 23:32:10
Service restored  : 23:33:45
Observed RTO      : 94.97 seconds
                   ≈ 1 minute 35 seconds
```

This is evidence from the project test, not a guaranteed future recovery time.

---

# 21. RPO Verification

RPO represents potential data loss.

Project target:

```text
≤ 1 minute
```

Project replication test:

```text
Transaction:
RPO-PROOF-20260913-232046

Observed visibility in Mumbai:
3.97 seconds
```

Again:

```text
Observed result ≠ guaranteed SLA
```

---

# 22. Database Corruption / Accidental Deletion Procedure

Regional replication alone does not protect against logical corruption.

Bad change:

```text
Bad Data in HYD
      ↓
Replication
      ↓
Bad Data in MUM
```

Use DynamoDB Point-in-Time Recovery.

Recovery sequence:

```text
Identify clean point in time
        ↓
Start PITR restore
        ↓
Restore to NEW table
        ↓
Wait for ACTIVE
        ↓
Verify expected transactions
        ↓
Plan controlled application cutover
```

Project restore proof:

```text
Restored table:
FIN-TRANSACTIONS-RESTORE-DEMO

Recovered transaction:
TXN-C3D4BBBA03DA

Customer:
DELETE-RESTORE-DEMO

Amount:
500

Type:
CREDIT

Status:
SUCCESS
```

Never overwrite the production table blindly during a recovery investigation.

---

# 23. CI/CD During a DR Incident

The application image exists in both regions.

```text
GitHub Actions
      ↓
OIDC
      ↓
Docker Build
      ↓
HYD ECR + MUM ECR
```

During an active DR event:

1. Avoid unnecessary releases.
2. Confirm Mumbai is running a known-good image.
3. Do not deploy a new untested version while recovering from infrastructure failure.
4. If rollback is needed, use a previously verified image tag/SHA.
5. Verify the ECR image digest before runtime promotion.

Recovery and software release should be treated as separate operations whenever possible.

---

# 24. IAM Check Before Any New AWS Action

Before creating or modifying AWS resources during recovery:

```text
Identify required AWS action
        ↓
Check current IAM permission
        ↓
Permission available?
   ┌────┴────┐
  Yes       No
   │         │
Proceed     Stop
             ↓
      Record AccessDenied
             ↓
      Update correct policy
             ↓
      Retry only after approval
```

Do not keep creating new policies to bypass missing permissions.

For an `AccessDenied` error, record:

```text
AWS action:
Resource:
Current identity:
Missing permission:
Existing policy to update:
Terraform change required: Yes / No
```

---

# 25. Failback Preconditions

Do not fail back to Hyderabad immediately after it comes online.

Failback only when all of the following are true:

```text
[ ] HYD infrastructure healthy
[ ] HYD-ALB healthy
[ ] HYD target group healthy
[ ] HYD ASG stable
[ ] Application verified
[ ] DynamoDB replication healthy
[ ] Recent Mumbai writes visible in Hyderabad
[ ] No unresolved transaction discrepancy
[ ] Monitoring normal
[ ] Incident owner approves failback
```

---

# 26. Failback Procedure

Use this sequence:

```text
Mumbai Active
      ↓
Repair Hyderabad
      ↓
Verify HYD infrastructure
      ↓
Verify HYD application
      ↓
Verify database synchronization
      ↓
Confirm recent MUM writes in HYD
      ↓
Prepare HYD as active writer
      ↓
Route traffic back
      ↓
Verify user traffic
      ↓
Return MUM to warm standby
```

Record:

```text
Failback start:
HYD first healthy response:
Failback complete:
```

---

# 27. Post-Failback Validation

After traffic returns to Hyderabad:

```text
[ ] finance.best.2bd.net responds correctly
[ ] HYD targets are healthy
[ ] HYD ASG is stable
[ ] MUM remains available as DR
[ ] Database writes succeed
[ ] Recent DR transactions are visible in HYD
[ ] No duplicate transactions found
[ ] CloudWatch alarms are normal
[ ] SNS notifications work
```

Do not close the incident until these checks are complete.

---

# 28. Return Mumbai to Normal Warm-DR Capacity

After successful failback:

```text
MUM-APP-ASG
Minimum = 1
Desired = 1
Maximum = 2
```

Do not destroy the DR environment as part of normal failback.

The Mumbai environment should remain ready for the next incident.

---

# 29. Recovery Decision Tree

```text
                         INCIDENT
                            │
                            ▼
                    Is HYD still usable?
                      /             \
                    Yes              No
                    │                │
                    ▼                ▼
          Can ASG/ALB recover?    Verify MUM
              /      \              │
            Yes      No              ▼
             │        │          MUM healthy?
             ▼        ▼          /         \
       Recover HYD   Failover   Yes         No
                       │         │           │
                       │         ▼           ▼
                       │      Failover    Repair DR
                       │         │
                       └─────────┘
                             ↓
                       Verify Data
                             ↓
                       Operate in MUM
                             ↓
                       Repair Hyderabad
                             ↓
                       Verify Sync
                             ↓
                          Failback
```

---

# 30. Recovery Verification Checklist

## Application

```text
[ ] DNS responds
[ ] ALB responds
[ ] Target group healthy
[ ] Docker application healthy
[ ] /health succeeds
```

## Compute

```text
[ ] ASG desired capacity correct
[ ] Required instances InService
[ ] CPU acceptable
[ ] Scaling activity normal
```

## Database

```text
[ ] FIN-TRANSACTIONS available
[ ] Reads succeed
[ ] Writes succeed
[ ] Recent transactions verified
[ ] No obvious duplicates
```

## Storage

```text
[ ] S3 DR object available if required
[ ] Correct version available
[ ] Replication failure alarm normal
```

## Monitoring

```text
[ ] CloudWatch dashboard reviewed
[ ] Critical alarms reviewed
[ ] SNS notification received
```

---

# 31. Controlled DR Test Procedure

Use this procedure for scheduled testing.

### Before Test

```text
[ ] Inform participants
[ ] Confirm both regions healthy
[ ] Record baseline
[ ] Verify MUM target health
[ ] Verify DynamoDB replica
[ ] Record start time
```

### Test

```text
1. Introduce the approved controlled primary failure.
2. Record failure time.
3. Observe monitoring and Route 53 behavior.
4. Verify traffic moves to Mumbai.
5. Record first successful Mumbai response.
6. Verify transactions.
7. Calculate RTO.
8. Verify RPO evidence.
```

### After Test

```text
1. Restore Hyderabad.
2. Verify data synchronization.
3. Fail traffic back.
4. Verify both environments.
5. Save evidence.
6. Update runbook if required.
```

Do not perform destructive failure injection against production without approval.

---

# 32. Evidence to Save After Every DR Test

Save:

```text
CloudWatch alarm screenshots
Route 53 failover evidence
HYD target health
MUM target health
ASG capacity evidence
Successful application response
DynamoDB transaction verification
RTO timestamps
RPO test transaction
S3 replication evidence if tested
GitHub/ECR image evidence
```

Use clear filenames with date and test name.

Example:

```text
2026-09-13_DR-Test_RTO.png
2026-09-13_DynamoDB_RPO.txt
2026-09-13_MUM-Target-Health.png
```

---

# 33. Known Limitations

Current internship implementation has these limitations:

- HTTP is used instead of production HTTPS/TLS.
- Mumbai warm DR normally runs fewer application instances than Hyderabad.
- Cross-region DynamoDB replication is asynchronous.
- DNS caching can affect failover time.
- The exact health-detection timestamp was not separately preserved in the latest controlled test.
- The observed RTO/RPO values are test measurements, not guaranteed SLAs.
- The environment is warm DR, not active-active.
- Production-scale traffic may require higher Mumbai ASG limits.
- Route 53 failover protects the application endpoint; database-only failures still require correct application health detection and operational decision-making.

---

# 34. Production Hardening Recommendations

For production, consider:

```text
HTTPS :443 with ACM
AWS WAF
Higher DR ASG capacity
Multi-region centralized monitoring
Automated application-level synthetic health checks
Stronger database-aware health checks
Automated idempotency controls
Automated restore testing
CloudTrail / security monitoring
Formal incident approval workflow
Multi-account DR isolation
```

These are future hardening improvements, not claims about the current internship implementation.

---

# 35. Emergency Quick Reference

If the primary region is unavailable:

```text
1. Record failure time.
2. Open HYD-DR-DASHBOARD.
3. Check HYD ALB / targets / ASG / DynamoDB.
4. Confirm regional failover is required.
5. Verify MUM-APP-TG has healthy target(s).
6. Verify MUM DynamoDB replica.
7. Protect against dual-region writes.
8. Verify Route 53 sends traffic to MUM.
9. Test finance.best.2bd.net.
10. Scale MUM if required.
11. Verify critical transactions.
12. Record recovery time and RTO.
13. Operate from Mumbai.
14. Repair Hyderabad.
15. Verify database synchronization.
16. Perform controlled failback.
17. Validate both regions.
18. Close incident and save evidence.
```

---

# 36. Final Operational Flow

```text
DETECT
  ↓
CLASSIFY
  ↓
VERIFY PRIMARY
  ↓
DECIDE
  ↓
VERIFY DR
  ↓
PROTECT DATA
  ↓
FAIL OVER
  ↓
SCALE
  ↓
VERIFY APPLICATION
  ↓
VERIFY DATA
  ↓
OPERATE IN DR
  ↓
REPAIR PRIMARY
  ↓
VERIFY SYNCHRONIZATION
  ↓
FAIL BACK
  ↓
POST-INCIDENT REVIEW
```

---

# 37. Final Conclusion

This runbook gives another engineer a complete recovery sequence for the ELITE SPARK multi-region platform.

The most important operational principles are:

```text
Detect before acting
        +
Fail over only when necessary
        +
Keep one active write region
        +
Verify application and data
        +
Record RTO and RPO
        +
Fail back only after synchronization
```

The DR environment is designed to keep the application available through Mumbai when Hyderabad cannot safely serve users.

The latest controlled recovery test achieved:

```text
Observed RTO:
94.97 seconds
≈ 1 minute 35 seconds

Target:
≤ 5 minutes
```

The project also observed DynamoDB cross-region transaction visibility in:

```text
3.97 seconds
```

against the project RPO target of:

```text
≤ 1 minute
```

These values demonstrate the tested project behavior but should not be treated as guaranteed AWS service-level commitments.

---

## Interview Answer

> My final DR runbook follows a clear Detect → Verify → Decide → Fail Over → Validate → Fail Back process. An engineer first checks CloudWatch, ALB target health, Auto Scaling and DynamoDB to confirm whether the incident can be recovered inside Hyderabad. If regional failover is necessary, they verify the Mumbai ALB, target group, Auto Scaling capacity and DynamoDB replica before allowing traffic to move to Mumbai through Route 53. During recovery, only one region should operate as the active writer, and critical transactions must be checked for replication lag or duplicates. After Hyderabad is restored, the engineer verifies application health and confirms that recent Mumbai writes have synchronized before failing traffic back. Every incident records failure time, recovery time, RTO, data verification and final status so the process is repeatable and auditable.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 15:** Final Disaster Recovery Runbook
