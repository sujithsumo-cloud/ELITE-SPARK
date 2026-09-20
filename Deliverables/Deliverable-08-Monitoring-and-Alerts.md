# Deliverable 08 — Monitoring and Alert Rules

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**Monitoring:** Amazon CloudWatch  
**Notification:** Amazon SNS  
**Dashboard:** `HYD-DR-DASHBOARD`  
**SNS Topic:** `HYD-ALERTS`

---

## 1. Objective

The monitoring design must quickly identify:

- application/service failure,
- unhealthy EC2 targets,
- high application latency,
- high CPU usage,
- DynamoDB errors,
- S3 storage/replication problems,
- and backup or recovery failures.

The monitoring flow is:

```text
AWS Resources
      ↓
CloudWatch Metrics
      ↓
CloudWatch Alarms
      ↓
SNS
      ↓
Operator / Email Alert
```

---

## 2. Monitoring Architecture

```text
                ELITE SPARK RESOURCES
                         │
         ┌───────────────┼────────────────┐
         │               │                │
         ▼               ▼                ▼
       EC2/ASG           ALB           DynamoDB
         │               │                │
         └───────────────┼────────────────┘
                         │
                         ▼
                    CloudWatch
                         │
                  Dashboard + Alarms
                         │
                         ▼
                       SNS
                         │
                         ▼
                  Operator / Email

                         +
                         │
                         ▼
                    S3 / CRR
                         │
                         ▼
              Replication Monitoring
```

---

## 3. Main Alert Rules

| Monitoring Area | Alarm / Rule | Example Condition | Action |
|---|---|---|---|
| Service failure | `HYD-APP-UNHEALTHY-TARGET` | Unhealthy target detected | SNS alert |
| High CPU | `HYD-APP-HIGH-CPU` | CPU above configured threshold | SNS alert / Auto Scaling assists |
| High latency | `HYD-ALB-HIGH-LATENCY` | ALB response time above acceptable limit | SNS alert |
| DynamoDB error | `HYD-DYNAMODB-SYSTEM-ERROR` | DynamoDB system errors detected | SNS alert |
| S3 replication problem | `HYD-S3-REPLICATION-FAILURE` | Replication failure detected | SNS alert |
| Backup protection | PITR status / restore verification | PITR disabled or restore test fails | Operator escalation |

---

## 4. Service Failure Monitoring

The ALB Target Group continuously checks application health through:

```text
/health
```

Flow:

```text
Application Instance
        ↓
Target Group Health Check
        ↓
Healthy / Unhealthy
        ↓
CloudWatch Alarm
        ↓
SNS Alert
```

Alarm:

```text
HYD-APP-UNHEALTHY-TARGET
```

Recommended rule:

```text
UnHealthyHostCount >= 1
for 2 consecutive 1-minute periods
```

This helps detect:

- failed EC2 instances,
- stopped Docker containers,
- application crashes,
- failed health endpoints.

---

## 5. High CPU Monitoring

Alarm:

```text
HYD-APP-HIGH-CPU
```

Metric:

```text
AWS/EC2
CPUUtilization
AutoScalingGroupName = HYD-APP-ASG
```

Recommended warning rule:

```text
Average CPUUtilization >= 70%
for 2 consecutive 5-minute periods
```

Purpose:

- identify sustained high load,
- detect possible performance problems,
- support Auto Scaling decisions,
- notify the operator if high load continues.

Auto Scaling can increase capacity while CloudWatch provides operational visibility.

---

## 6. High Latency Monitoring

Alarm:

```text
HYD-ALB-HIGH-LATENCY
```

Metric:

```text
AWS/ApplicationELB
TargetResponseTime
```

Recommended rule:

```text
Average TargetResponseTime >= 2 seconds
for 3 consecutive 1-minute periods
```

Flow:

```text
Slow Application Response
        ↓
ALB TargetResponseTime increases
        ↓
CloudWatch Alarm
        ↓
SNS Alert
        ↓
Operator investigates
```

Possible causes include:

- overloaded application instances,
- application code delay,
- downstream database delay,
- insufficient capacity.

---

## 7. DynamoDB Error Monitoring

Alarm:

```text
HYD-DYNAMODB-SYSTEM-ERROR
```

Table:

```text
FIN-TRANSACTIONS
```

Metric:

```text
AWS/DynamoDB
SystemErrors
```

Recommended rule:

```text
SystemErrors >= 1
within 1 minute
```

The CloudWatch dashboard can also monitor:

```text
ThrottledRequests
```

This helps detect:

- service-side errors,
- throttling,
- database request problems.

---

## 8. S3 Storage and Replication Monitoring

The project uses S3 Cross-Region Replication:

```text
HYD S3
   ↓
CRR
   ↓
MUM S3
```

Alarm:

```text
HYD-S3-REPLICATION-FAILURE
```

The rule should detect failed or delayed replication when S3 replication metrics are enabled.

Example condition:

```text
Replication failures > 0
```

Flow:

```text
Object uploaded in HYD
        ↓
Replication attempt
        ↓
Replication problem
        ↓
CloudWatch Alarm
        ↓
SNS Alert
```

This is important because the DR bucket is part of the regional storage-protection strategy.

---

## 9. Backup Failure Monitoring

The project uses:

```text
DynamoDB PITR
+
S3 Versioning
+
S3 Cross-Region Replication
```

Backup monitoring should verify two things:

```text
Backup feature is enabled
        +
Recovery actually works
```

### DynamoDB PITR

The project should verify that PITR remains enabled for:

```text
FIN-TRANSACTIONS
```

If PITR is found disabled:

```text
PITR Disabled
      ↓
Critical Backup Protection Alert
      ↓
Operator Action
```

A production implementation could automate this configuration check using AWS monitoring/compliance tools.

### Restore Verification

Backup health cannot be proven only by seeing that PITR is enabled.

Periodic restore testing should verify:

```text
Restore Table
      ↓
Read Expected Record
      ↓
Compare Values
      ↓
Pass / Fail
```

If verification fails:

```text
Restore Verification Failure
        ↓
Critical Alert
        ↓
Investigation
```

---

## 10. Important Backup Monitoring Clarification

The current project does **not** use AWS Backup as the primary database backup service.

Therefore, the project should not claim:

```text
AWS Backup Job Failed Alarm
```

as an implemented feature.

The implemented recovery strategy is:

```text
DynamoDB PITR
+
S3 Versioning
+
S3 CRR
```

So backup monitoring focuses on:

- PITR availability,
- restore testing,
- S3 versioning,
- S3 replication health.

---

## 11. CloudWatch Dashboard

Dashboard:

```text
HYD-DR-DASHBOARD
```

Important dashboard sections include:

```text
EC2 / ASG CPU Utilization
        ↓
ALB Target Health
        ↓
DynamoDB System Errors
        ↓
DynamoDB Throttled Requests
        ↓
ALB Request Count
```

The dashboard gives a single operational view of the primary environment.

---

## 12. Alert Severity Design

A simple severity model can be used:

| Severity | Example |
|---|---|
| **Critical** | No healthy targets, regional endpoint failure, database system errors, backup/replication failure |
| **Warning** | High CPU, high latency, throttling |
| **Information** | Scaling event, recovery test completed |

Example:

```text
Critical
   ↓
Immediate SNS notification

Warning
   ↓
Operator investigates trend
```

---

## 13. Detection-to-Alert Flow

```text
Resource Problem
      ↓
CloudWatch Metric Changes
      ↓
Alarm Threshold Reached
      ↓
Alarm State = ALARM
      ↓
SNS Topic
HYD-ALERTS
      ↓
Email / Operator Notification
      ↓
Investigation / Recovery Action
```

---

## 14. Failure and Monitoring Mapping

| Failure | Detection |
|---|---|
| EC2/application failure | ALB UnHealthyHostCount |
| Docker/app health failure | `/health` target check |
| High server load | EC2 CPUUtilization |
| Slow application | ALB TargetResponseTime |
| DynamoDB service error | DynamoDB SystemErrors |
| DynamoDB throttling | ThrottledRequests |
| S3 replication failure | S3 replication metrics |
| PITR disabled | Configuration verification |
| Backup restore unusable | Restore verification test |
| Regional application failure | Route 53 health/failover behavior |

---

## 15. Monitoring and DR Relationship

Monitoring is directly connected to disaster recovery.

```text
Failure
   ↓
Detection
   ↓
Alert
   ↓
Recovery / Failover
   ↓
Verification
```

Without monitoring:

```text
Failure occurs
      ↓
No detection
      ↓
Longer downtime
```

With monitoring:

```text
Failure occurs
      ↓
Detected quickly
      ↓
Alert generated
      ↓
Recovery process starts
```

---

## 16. Recommended Monitoring Improvements

For a production financial application, the design could later add:

- CloudWatch Logs application error alarms,
- Route 53 health-check alarms,
- S3 replication latency monitoring,
- DynamoDB throttling alarms,
- CloudTrail security-event monitoring,
- centralized multi-region dashboarding,
- EventBridge-based backup configuration checks,
- automated periodic restore testing.

These are production improvements and should not all be claimed as currently implemented.

---

## 17. Final Monitoring Design

```text
                     APPLICATION
                          │
          ┌───────────────┼────────────────┐
          │               │                │
          ▼               ▼                ▼
       EC2/ASG           ALB           DynamoDB
          │               │                │
          │               │                │
          └───────────────┼────────────────┘
                          │
                          ▼
                     CloudWatch
                   Metrics + Alarms
                          │
                          ▼
                         SNS
                    HYD-ALERTS
                          │
                          ▼
                       Operator

          S3 / PITR / Restore Verification
                          │
                          ▼
                 Backup Health Checks
                          │
                          ▼
                     Alert / Action
```

---

## 18. Conclusion

The ELITE SPARK monitoring strategy uses CloudWatch and SNS to identify application, infrastructure, database and storage problems.

The main implemented alarms are:

```text
HYD-APP-HIGH-CPU
HYD-APP-UNHEALTHY-TARGET
HYD-DYNAMODB-SYSTEM-ERROR
HYD-ALB-HIGH-LATENCY
HYD-S3-REPLICATION-FAILURE
```

The `HYD-DR-DASHBOARD` provides operational visibility, while `HYD-ALERTS` provides incident notification.

Backup monitoring is handled by checking DynamoDB PITR protection, verifying restores, and monitoring S3 replication rather than claiming an AWS Backup workflow that was not part of the project.

---

## Interview Answer

> I designed monitoring around CloudWatch metrics, alarms and SNS notifications. Application failure is detected using ALB target health checks, high CPU is monitored using EC2 CPUUtilization, and high latency is detected using ALB TargetResponseTime. DynamoDB SystemErrors and throttling provide database visibility, while S3 replication monitoring identifies problems with the DR object copy. For backup protection, I verify that DynamoDB PITR remains enabled and perform restore tests because a backup is only useful if the recovered data can actually be read. Critical alarms send notifications through the `HYD-ALERTS` SNS topic, and the `HYD-DR-DASHBOARD` provides a single operational view.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 08:** Monitoring and Alert Rules for Service Failure, Latency, Storage and Backup Protection
