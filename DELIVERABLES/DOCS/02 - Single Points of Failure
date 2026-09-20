# Deliverable 02 — Single Points of Failure (SPOF) Analysis

## Project: ELITE SPARK

**Topic:** Multi-Region Disaster Recovery, High Availability, Backup and Business Continuity  
**Primary Region:** Asia Pacific (Hyderabad) — `ap-south-2`  
**Disaster Recovery Region:** Asia Pacific (Mumbai) — `ap-south-1`

---

## 1. Objective

A **Single Point of Failure (SPOF)** is a component whose failure can make the application or an important business function unavailable.

The initial design had several possible SPOFs, such as a single EC2 instance, a single Availability Zone, a single AWS Region, a single database location, and a single copy of application data.

The final ELITE SPARK design reduces these risks using:

- Multi-AZ deployment
- Application Load Balancers
- Auto Scaling Groups
- Multi-Region disaster recovery
- Route 53 failover routing
- DynamoDB Global Tables
- DynamoDB Point-in-Time Recovery
- S3 Cross-Region Replication
- S3 Versioning
- Regional ECR repositories
- CloudWatch monitoring
- SNS alerting
- GitHub Actions CI/CD

---

## 2. SPOF Summary

| Initial SPOF | Risk | Mitigation / Reduction | ELITE SPARK Implementation |
|---|---|---|---|
| Single EC2 instance | Application outage if the server fails | Multiple EC2 instances with Auto Scaling | `HYD-APP-ASG` with min 2, desired 2, max 4 |
| Single Availability Zone | AZ failure can affect the full workload | Multi-AZ deployment | Public and private subnets across two AZs |
| Single application entry point | Users depend directly on one server | Use an Application Load Balancer | `HYD-ALB` distributes traffic to healthy instances |
| Single AWS Region | Regional outage can stop the application | Secondary DR region | Hyderabad primary + Mumbai warm DR |
| Single regional DNS destination | Users may still reach failed primary infrastructure | Route 53 failover | `finance.best.2bd.net` routes from HYD to MUM during failure |
| Single-region database | Database unavailable during regional failure | Cross-region database replication | DynamoDB Global Table `FIN-TRANSACTIONS` |
| Database accidental deletion/corruption | Replication alone does not provide historical recovery | Point-in-Time Recovery | DynamoDB PITR enabled |
| Single S3 copy | Object/log data unavailable or lost | Cross-region replication | HYD S3 → MUM S3 using CRR |
| Object overwrite/deletion | Previous object versions may be lost | Versioning | S3 Versioning enabled |
| Failed EC2 not automatically replaced | Capacity loss or outage | Auto Scaling self-healing | ASG replaces failed instances |
| Traffic reaches unhealthy server | Failed user requests | Health checks and target groups | ALB `/health` checks |
| Manual incident detection | Slow response to failures | Automated monitoring and alerts | CloudWatch + SNS |
| Single regional container repository | DR instances may not obtain the image | Store image in both regions | ECR `finance-app` in HYD and MUM |
| Manual build process | Human error and deployment delay | CI/CD automation | GitHub Actions + OIDC |
| NAT Gateway dependency | Cost and dependency for AWS service access | Private VPC endpoints | ECR API/DKR, S3 and DynamoDB endpoints |

---

## 3. Single EC2 Instance

### Initial Risk

```text
User
  ↓
Single EC2
  ↓
Application
```

If that EC2 instance fails, the application becomes unavailable.

### Mitigation

```text
              HYD-ALB
                 │
        ┌────────┴────────┐
        ↓                 ↓
    EC2 - AZ-A        EC2 - AZ-B
        └────────┬────────┘
                 ↓
           HYD-APP-ASG
```

The primary Auto Scaling Group uses:

```text
Minimum  = 2
Desired  = 2
Maximum  = 4
```

If one instance fails:

```text
Instance failure
      ↓
ASG detects capacity loss
      ↓
Replacement instance launched
      ↓
ALB routes traffic to healthy targets
```

This self-healing behavior was tested successfully.

---

## 4. Single Availability Zone

### Initial Risk

```text
Region
  ↓
AZ-A
 ├─ EC2-1
 └─ EC2-2
```

Even with multiple EC2 instances, placing them all in one AZ creates an AZ-level SPOF.

### Mitigation

```text
Hyderabad Region
       │
 ┌─────┴─────┐
 │           │
AZ-A         AZ-B
 │           │
EC2          EC2
```

The VPC uses public and private subnets across two Availability Zones.

If one AZ becomes unavailable, workloads in the other AZ can continue serving traffic.

---

## 5. Single AWS Region

### Initial Risk

```text
Hyderabad only
      ↓
Regional outage
      ↓
Application unavailable
```

Multi-AZ protects against many infrastructure failures, but it does not protect against a full regional outage.

### Mitigation

```text
                 Route 53
                    │
          ┌─────────┴─────────┐
          │                   │
    Hyderabad             Mumbai
     Primary               DR
```

The implemented regional design is:

- **Primary:** Hyderabad — `ap-south-2`
- **DR:** Mumbai — `ap-south-1`

The Mumbai environment acts as the warm disaster-recovery region.

---

## 6. Application Entry Point and Load Balancer

Direct access to EC2 instances would make individual server addresses part of the application architecture.

Instead:

```text
User
 ↓
Application Load Balancer
 ↓
Target Group
 ↓
Healthy EC2 Instances
```

The Application Load Balancer distributes traffic only to healthy targets.

The health endpoint used by the target group is:

```text
/health
```

If an application instance becomes unhealthy:

```text
EC2 becomes unhealthy
        ↓
Target health check fails
        ↓
ALB stops routing traffic to that target
        ↓
Traffic continues to healthy instances
```

---

## 7. Database SPOF

### Initial Risk

```text
Application
    ↓
Single-Region Database
```

If the primary region becomes unavailable, the application may still fail because its database is unavailable.

### Mitigation

```text
HYD DynamoDB
FIN-TRANSACTIONS
       │
       │ Asynchronous replication
       ▼
MUM DynamoDB
FIN-TRANSACTIONS
```

The project uses a **DynamoDB Global Table** for cross-region replication.

### Observed RPO Test

During the project test:

```text
Observed replication visibility ≈ 3.97 seconds
```

This is a **measured project result**, not a guaranteed DynamoDB RPO SLA.

---

## 8. Database Recovery SPOF

Cross-region replication improves availability, but replication alone is not a backup.

For example:

```text
Incorrect deletion in HYD
          ↓
Replication
          ↓
Incorrect state may also reach MUM
```

### Mitigation

DynamoDB **Point-in-Time Recovery (PITR)** was enabled.

A restore test successfully recovered data into:

```text
FIN-TRANSACTIONS-RESTORE-DEMO
```

Recovered transaction:

```text
Transaction ID: TXN-C3D4BBBA03DA
Customer: DELETE-RESTORE-DEMO
Amount: 500
Type: CREDIT
Status: SUCCESS
```

Therefore:

```text
Global Table = Cross-region availability
PITR         = Historical recovery capability
```

---

## 9. S3 Storage SPOF

### Initial Risk

A single S3 bucket in one region creates a regional dependency for stored objects and logs.

### Mitigation

```text
HYD S3 Bucket
      │
      │ Cross-Region Replication
      ▼
MUM S3 Bucket
```

Implemented protection includes:

- S3 Versioning
- Encryption
- Lifecycle policies
- Cross-Region Replication

This provides:

```text
Primary copy
    +
Secondary regional copy
    +
Historical object versions
```

---

## 10. DNS / Regional Entry-Point SPOF

### Initial Risk

```text
finance.best.2bd.net
        ↓
HYD only
```

If Hyderabad becomes unavailable, users could continue being directed to a failed regional endpoint.

### Mitigation

Route 53 failover routing was implemented:

```text
               Route 53
                  │
          Failover decision
          ┌───────┴───────┐
          ↓               ↓
       HYD ALB          MUM ALB
       Primary         Secondary
```

Normal flow:

```text
User → Route 53 → HYD
```

Failure flow:

```text
HYD unavailable
      ↓
Route 53 failover condition
      ↓
MUM
```

### Observed RTO Test

Latest measured regional recovery time:

```text
94.97 seconds
≈ 1 minute 35 seconds
```

The failure was manually initiated, while DNS/service recovery behavior after the failure condition was automatic.

---

## 11. Container Image SPOF

If the application image existed only in Hyderabad ECR, Mumbai recovery could depend on a regional service that might also be affected.

### Mitigation

The `finance-app` repository was used in both regions:

```text
HYD ECR → finance-app
MUM ECR → finance-app
```

GitHub Actions automated the image build and push process:

```text
GitHub
   ↓
GitHub Actions
   ↓
Docker Build
   ↓
 ┌───────────────┐
 ↓               ↓
HYD ECR       MUM ECR
```

This reduces dependency on a single regional container repository.

---

## 12. Manual Monitoring SPOF

Human-only monitoring is slow and unreliable.

### Mitigation

```text
AWS Resources
     ↓
CloudWatch
     ↓
Alarms
     ↓
SNS
     ↓
Operator
```

Examples of monitoring used in the project:

- `HYD-APP-HIGH-CPU`
- `HYD-APP-UNHEALTHY-TARGET`
- `HYD-DYNAMODB-SYSTEM-ERROR`
- `HYD-ALB-HIGH-LATENCY`
- `HYD-S3-REPLICATION-FAILURE`

CloudWatch does not eliminate failures, but it reduces detection and response risk.

---

## 13. NAT Gateway Dependency

A NAT Gateway could introduce:

- Additional cost
- Another managed dependency
- Unnecessary Internet routing for private AWS service access

### Mitigation

The project intentionally used VPC endpoints instead of a NAT Gateway.

Implemented endpoints:

- ECR API
- ECR DKR
- S3
- DynamoDB

This allowed private EC2 instances to access required AWS services without public IP addresses or a NAT Gateway.

---

## 14. Initial vs Final Architecture

### Initial Vulnerable Design

```text
Internet
   ↓
Single Region
   ↓
Single EC2
   ↓
Single Database
   ↓
Single Storage Copy
```

This design contains multiple SPOFs.

### Final ELITE SPARK Design

```text
                         USERS
                           │
                           ▼
                       ROUTE 53
                           │
              ┌────────────┴────────────┐
              │                         │
       HYDERABAD PRIMARY            MUMBAI DR
              │                         │
            ALB                       ALB
              │                         │
         Multi-AZ ASG              Warm DR ASG
          /       \                  /       \
       EC2         EC2            EC2        EC2
          \         /                \        /
           Docker App                 Docker App
                │                          │
                └──────────┬───────────────┘
                           │
                    DynamoDB Global
                         Table
                   HYD ↔ MUM Replica

                HYD S3 ───────→ MUM S3
                       CRR

                       CloudWatch
                           │
                           ▼
                          SNS
```

---

## 15. Residual Risks

The project reduces major SPOFs, but it is important not to claim that every possible failure has been eliminated.

Remaining limitations include:

- DNS failover and propagation delay
- Asynchronous cross-region replication
- Warm DR instead of fully active-active deployment
- Manual initiation of the demonstrated regional-failure test
- CI/CD and control-plane dependencies
- HTTP was used instead of HTTPS in the current implementation
- Test RPO/RTO values are observations, not contractual guarantees

---

## 16. Final Conclusion

The initial architecture contained several potential single points of failure, including a single EC2 instance, a single Availability Zone, a single AWS Region, a single-region database, a single storage copy, and dependency on one application endpoint.

The final ELITE SPARK architecture reduced these risks by using:

- Multi-AZ EC2 deployment
- Application Load Balancers
- Auto Scaling self-healing
- Multi-Region warm disaster recovery
- Route 53 failover routing
- DynamoDB Global Tables
- DynamoDB PITR
- S3 Cross-Region Replication
- S3 Versioning
- ECR repositories in both regions
- CloudWatch and SNS
- GitHub Actions CI/CD
- Private VPC endpoints

This changed the design from a single-server, single-region architecture into a **multi-AZ, multi-region resilient platform with self-healing, data replication, recovery capability, monitoring, and regional failover**.

---

## 17. Interview Summary

> The major single points of failure in the initial design were the single EC2 instance, single Availability Zone, single AWS Region, single-region database, single object-storage copy, and dependency on a single regional application endpoint. I reduced these risks by deploying the application across multiple Availability Zones using an Application Load Balancer and Auto Scaling Group, creating a warm disaster-recovery environment in Mumbai, implementing Route 53 failover routing, using DynamoDB Global Tables with PITR, replicating S3 data across regions with versioning, maintaining ECR repositories in both regions, and using CloudWatch and SNS for monitoring and alerting. The result is a multi-AZ, multi-region architecture with self-healing, replicated data, and regional failover capability.

---

**Deliverable Status:** ✅ Complete  
**Deliverable:** Single Points of Failure Analysis and Mitigation
