# Deliverable 13 — Recovery Environment Cost Estimate and Cost-Saving Alternatives

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**DR Strategy:** Warm Disaster Recovery  
**Pricing Basis:** Approximate September 2026 public AWS pricing  
**Traffic Assumption:** Low-traffic internship / demonstration workload

> This is an architecture-level estimate, not an AWS invoice. Actual cost depends on traffic, storage, requests, data transfer, taxes, free-tier/credit eligibility, and future AWS price changes.

---

## 1. Objective

The goal is to estimate the major cost of keeping the Mumbai disaster-recovery environment ready and identify ways to reduce cost without unnecessarily weakening recovery.

The basic trade-off is:

```text
Higher DR Readiness
       ↓
Lower RTO
       ↓
Higher Ongoing Cost

Lower DR Readiness
       ↓
Higher RTO
       ↓
Lower Ongoing Cost
```

---

## 2. Current DR Design

The Mumbai environment uses a warm DR model.

```text
Route 53
   ↓
MUM-ALB
   ↓
MUM-APP-ASG
   ↓
1 x t3.micro normally running
   ↓
Docker Application
   ↓
DynamoDB Global Table Replica
```

Supporting services include:

```text
MUM ECR
S3 DR Bucket
DynamoDB Replica
ECR API Interface Endpoint
ECR DKR Interface Endpoint
S3 Gateway Endpoint
DynamoDB Gateway Endpoint
KMS
CloudWatch
```

The Mumbai Auto Scaling Group was configured with:

```text
Minimum = 1
Desired = 1
Maximum = 2
```

---

## 3. Major Monthly Cost Drivers

### Approximate Low-Traffic DR Estimate

| Component | Approximate Monthly Cost | Notes |
|---|---:|---|
| 1 × EC2 `t3.micro` | **~$8.18** | Mumbai Linux On-Demand, always running |
| MUM Application Load Balancer | **~$17.45 + LCU usage** | 730 hours/month; low traffic keeps LCU usage small |
| 2 ECR Interface Endpoints across 2 AZs | **~$37.96 + data processing** | Usually the largest fixed networking cost in this small DR design |
| S3 Gateway Endpoint | **$0 endpoint hourly cost** | Gateway endpoint |
| DynamoDB Gateway Endpoint | **$0 endpoint hourly cost** | Gateway endpoint |
| KMS customer-managed key | **~$1.00** | If an ELITE-specific customer-managed key is retained |
| EBS root volume | **Variable / small** | Depends on provisioned root-volume size |
| DynamoDB Global Table replica | **Variable** | Replicated writes, reads, storage and PITR depend on usage |
| S3 DR storage + CRR | **Variable** | Destination storage, replication PUTs and inter-region transfer |
| ECR image storage | **Variable / small for lab** | Depends on number and size of images |
| CloudWatch / SNS | **Usually small for this lab** | Depends on alarms, metrics, logs and notifications |
| Route 53 | **Very small / shared** | Hosted zone is shared; eligible AWS endpoint health checks can be free |

### Approximate Fixed DR Floor

Known major fixed components:

```text
EC2 t3.micro          ≈ $ 8.18
ALB hourly charge     ≈ $17.45
ECR interface EPs     ≈ $37.96
KMS key               ≈ $ 1.00
--------------------------------
Known fixed subtotal  ≈ $64.59 / month
```

After adding EBS, small monitoring/storage charges, and light usage:

```text
Practical low-traffic estimate:
≈ $65–$75 per month
```

This is an approximate **warm-DR operating floor**, not a guaranteed bill.

---

## 4. Why VPC Endpoints Are a Major Cost

The project intentionally avoids a NAT Gateway.

Private EC2 instances access ECR using:

```text
Private EC2
     ↓
ECR API Interface Endpoint
ECR DKR Interface Endpoint
     ↓
Amazon ECR
```

The interface endpoints are deployed in both DR Availability Zones.

For two ECR endpoint services:

```text
2 endpoint services
×
2 Availability Zones
×
730 hours
×
~$0.013 per AZ-hour

≈ $37.96 / month
```

S3 and DynamoDB use gateway endpoints, which do not have the same hourly endpoint charge.

### Important Trade-Off

The interface endpoints improve:

- private networking,
- security,
- independence from public Internet access.

But for a very small lab environment they can cost more than the single DR EC2 instance.

---

## 5. EC2 Cost

The DR launch template uses:

```text
t3.micro
```

Approximate Mumbai Linux On-Demand price:

```text
$0.0112 per hour
```

Monthly:

```text
$0.0112
× 730 hours
≈ $8.18/month
```

Because the DR ASG maintains one running instance, this is an always-on warm-standby cost.

---

## 6. Load Balancer Cost

The Mumbai ALB remains available so Route 53 can fail traffic over without rebuilding the application entry point.

Approximate hourly ALB charge used for this estimate:

```text
~$0.0239/hour
```

Monthly base:

```text
$0.0239
× 730
≈ $17.45/month
```

Additional LCU charges depend on:

- new connections,
- active connections,
- processed bytes,
- listener rule evaluations.

For the internship's light traffic, the hourly charge is the main ALB cost.

---

## 7. DynamoDB DR Cost

The project uses:

```text
DynamoDB Global Table
HYD ↔ MUM
```

Global-table costs are usage based.

Main cost areas:

- replicated write request units,
- reads in the DR region,
- storage in the replica,
- PITR backup storage,
- initial replica creation/restore where applicable.

For the small internship workload, this is expected to be much lower than the fixed ALB and interface-endpoint costs.

For production transaction volume, DynamoDB replicated writes could become an important cost driver.

---

## 8. S3 DR Cost

S3 protection uses:

```text
HYD S3
   ↓
Cross-Region Replication
   ↓
MUM S3
```

Main cost areas:

- Mumbai destination storage,
- replication PUT requests,
- inter-region data transfer,
- versioned object storage.

The project also uses a lifecycle rule for old noncurrent versions, helping limit long-term storage growth.

---

## 9. Monitoring and DNS Cost

CloudWatch and SNS costs are relatively small for this internship workload.

Many basic AWS metrics are available without custom-metric charges, and CloudWatch includes free-tier allowances for a limited number of alarms and dashboards.

Route 53 cost is also small compared with EC2, ALB and interface endpoints.

The hosted zone is shared and is not purely a DR-only cost.

Eligible health checks for AWS endpoints can also fall within Route 53's health-check offer.

---

# 10. Cost-Saving Alternatives

| Option | Savings Potential | Effect on Recovery |
|---|---|---|
| Reduce MUM ASG from 1 instance to 0 | Saves EC2 + EBS runtime | Changes warm DR toward pilot-light; RTO increases |
| Create MUM ALB only during disaster | Saves ~$17+/month plus LCU | Higher RTO because ALB must be provisioned |
| Remove always-on ECR interface endpoints and use pre-baked image/AMI | Can save roughly ~$38/month | More deployment/AMI-management complexity |
| Use one endpoint AZ instead of two | Reduces endpoint hourly cost | Creates weaker endpoint-level HA |
| Use `t3a.micro` if compatible | Roughly lower compute cost | Same general architecture |
| Use ARM/Graviton instance if image supports ARM | Can reduce compute cost | Requires multi-architecture Docker compatibility |
| Savings Plan / Reserved pricing for steady capacity | Reduces long-running EC2 cost | Requires commitment |
| Use Spot for testing only | Large compute savings | Interruption risk; not ideal as only production DR capacity |
| Keep DynamoDB on-demand for low traffic | Avoids paying unused provisioned capacity | Cost rises with real request volume |
| Apply S3 lifecycle policies | Reduces old-version storage cost | Archived/expired data may be slower or unavailable |
| Remove unused ECR image tags | Reduces registry storage | Must retain known-good rollback versions |
| Minimize CloudWatch custom metrics/log retention | Reduces observability cost | Do not remove critical failure monitoring |

---

## 11. Alternative 1 — Pilot-Light DR

A cheaper architecture could keep the data layer ready while reducing application capacity.

```text
Mumbai
  │
  ├── VPC
  ├── Terraform configuration
  ├── DynamoDB replica
  ├── S3 replica
  ├── ECR image
  │
  └── ASG Desired = 0
```

During disaster:

```text
Failure
  ↓
Scale MUM ASG to 1 or more
  ↓
Launch EC2
  ↓
Start Docker
  ↓
Attach to ALB
  ↓
Serve traffic
```

### Benefit

Lower normal-month compute cost.

### Risk

RTO becomes longer because compute must start during the disaster.

This would no longer be the same warm DR readiness demonstrated in the current project.

---

## 12. Alternative 2 — Infrastructure-on-Demand DR

For maximum cost savings:

```text
Keep:
Terraform
S3 replicated data
DynamoDB protection
ECR image

Do not keep always running:
EC2
ALB
Interface endpoints
```

During recovery:

```text
Terraform Apply
      ↓
Create DR Application Infrastructure
      ↓
Launch EC2
      ↓
Deploy Application
      ↓
Update / Activate Failover
```

### Benefit

Very low idle infrastructure cost.

### Risk

Much higher RTO.

This is closer to **backup-and-restore / cold DR** than warm DR.

---

## 13. Alternative 3 — Pre-Baked DR Image

The current private EC2 design requires ECR interface endpoints to pull the Docker image.

A cost-saving design could build a reusable AMI containing the application/container image.

```text
CI/CD
  ↓
Build Tested AMI
  ↓
Copy AMI to Mumbai
  ↓
DR EC2 launches from pre-built image
```

This can reduce dependence on always-on ECR interface endpoints.

### Benefit

Potentially removes one of the largest fixed DR networking costs.

### Trade-Off

- AMI lifecycle must be automated,
- every application release must refresh the DR image,
- image freshness must be verified.

---

## 14. Alternatives We Intentionally Avoided

### Always-On NAT Gateway

For this small environment, an always-on NAT Gateway would introduce another substantial hourly and per-GB cost.

The current project therefore uses:

```text
S3 Gateway Endpoint
DynamoDB Gateway Endpoint
ECR Interface Endpoints
```

instead of a NAT Gateway.

### Large DR Fleet

The DR environment normally keeps:

```text
Desired = 1
```

rather than duplicating the full Hyderabad capacity.

This is a major advantage of the warm-standby approach.

---

## 15. Recommended Cost Balance for This Project

For the internship project, the current architecture is a good demonstration of **real warm DR**, because:

```text
Mumbai already has:
ALB
+
Running EC2
+
Application
+
Replicated Database
+
Replicated Storage
```

That design produced an observed recovery time of approximately:

```text
94.97 seconds
```

If cost became more important than the current RTO, the first alternative to evaluate would be:

```text
Warm DR
    ↓
Pilot-Light DR
```

by scaling the DR ASG to zero and/or provisioning expensive idle application components only during recovery.

However, every cost reduction must be evaluated against:

```text
RTO
Security
Operational Complexity
Recovery Reliability
```

---

## 16. Cost Priority

For this small ELITE SPARK architecture, the major fixed-cost order is approximately:

```text
1. ECR Interface VPC Endpoints
2. Application Load Balancer
3. EC2 t3.micro
4. KMS / EBS / Monitoring
5. Usage-based S3 / DynamoDB / ECR
```

This is useful because the most expensive component is not always EC2.

---

## 17. Final Conclusion

Keeping a recovery environment available has an ongoing cost because the secondary region must keep enough infrastructure ready to meet the required RTO.

For ELITE SPARK, a low-traffic warm DR environment has an approximate operating floor of:

```text
≈ $65–$75 per month
```

before significant application traffic, large storage growth, taxes, or data-transfer usage.

The largest fixed costs are the ECR interface VPC endpoints, the Mumbai Application Load Balancer, and the always-running `t3.micro` EC2 instance.

Cost can be reduced by moving from warm DR toward pilot-light or infrastructure-on-demand DR, reducing idle endpoint/ALB resources, right-sizing compute, using commitment discounts where appropriate, and applying lifecycle policies to stored data.

The key principle is:

> **DR cost should be optimized according to business RTO and RPO requirements, not minimized without considering recovery impact.**

---

## Interview Answer

> The major cost of the ELITE SPARK warm DR environment comes from the always-on Mumbai application infrastructure. The DR region normally keeps one `t3.micro` instance, an Application Load Balancer, two ECR interface endpoints across two Availability Zones, a DynamoDB Global Table replica, S3 replicated storage and encryption/monitoring resources. For a low-traffic environment, the known fixed components are roughly $65 per month before variable storage, request and data-transfer charges. The ECR interface endpoints are actually one of the largest fixed costs. To reduce cost, I could move to a pilot-light design by scaling the DR ASG to zero, provision the ALB or endpoints only during recovery, use pre-baked AMIs to reduce ECR endpoint dependency, right-size compute, and apply storage lifecycle rules. The trade-off is that lower standby cost normally increases RTO, so I would choose the DR model based on the required recovery objective.

---

## Pricing Notes

This estimate uses public AWS pricing information available around September 2026 and a 730-hour month.

Key assumptions:

```text
Mumbai t3.micro Linux On-Demand ≈ $0.0112/hour
Mumbai ALB hourly charge        ≈ $0.0239/hour
Mumbai interface endpoint       ≈ $0.013/AZ-hour
Customer-managed KMS key        ≈ $1/month
```

Always verify production estimates with the AWS Pricing Calculator before approval.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 13:** Recovery Environment Cost Estimate and Cost-Saving Alternatives
