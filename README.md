# ELITE SPARK

## Multi-Region Disaster Recovery, High Availability, Backup and Business Continuity Platform

ELITE SPARK is an AWS-based internship project that demonstrates how a financial-services web application can be designed for **high availability, regional disaster recovery, backup protection, monitoring, automated scaling, infrastructure as code and business continuity**.

The platform uses **Hyderabad (`ap-south-2`) as the primary region** and **Mumbai (`ap-south-1`) as the warm disaster-recovery region**.

---

## Project Status

The implementation and controlled validation of ELITE SPARK have been completed.

Project proof is retained in:

```text
Screenshot/
Demo Video/
Deliverables/
```

To control AWS cost after validation, cost-bearing runtime resources may be intentionally scaled down or deprovisioned when the project is not being demonstrated. The Terraform code, evidence, IAM references and runbook remain the project source of truth for rebuild and review.

---

## Project Objectives

The project was designed to demonstrate:

- High availability across multiple Availability Zones
- Warm disaster recovery across AWS Regions
- Automated application scaling and failed-instance replacement
- Regional application traffic failover
- DynamoDB cross-region replication
- Database point-in-time recovery
- S3 versioning and cross-region replication
- Monitoring, alarms and incident notifications
- Secure private application networking
- Infrastructure provisioning with Terraform
- Docker-based application deployment
- GitHub Actions CI/CD using AWS OIDC
- Controlled disaster-recovery testing
- Measured RPO and RTO

---

# Architecture Overview

```text
                              USERS
                                │
                                ▼
                       finance.best.2bd.net
                                │
                                ▼
                             Route 53
                                │
                  ┌─────────────┴─────────────┐
                  │                           │
                  ▼                           ▼
             HYDERABAD                     MUMBAI
              PRIMARY                      WARM DR
           ap-south-2                     ap-south-1
                  │                           │
             HYD-ALB                       MUM-ALB
                  │                           │
            HYD-APP-TG                   MUM-APP-TG
                  │                           │
            HYD-APP-ASG                  MUM-APP-ASG
           Min 2 / Des 2                Min 1 / Des 1
           Max 4                        Max 2
                  │                           │
                  ▼                           ▼
            Private EC2                  Private EC2
            Docker App                   Docker App
                  │                           │
                  └─────────────┬─────────────┘
                                ▼
                     DynamoDB Global Table
                       FIN-TRANSACTIONS
                                │
                  ┌─────────────┴─────────────┐
                  │                           │
                  ▼                           ▼
             HYD S3 Source                MUM S3 DR
                  │
                  └──── Cross-Region Replication ────►
```

---

# Regional Design

## Primary Region — Hyderabad

```text
Region: ap-south-2
VPC:    10.0.0.0/16
```

Primary application capacity:

```text
HYD-APP-ASG

Minimum = 2
Desired = 2
Maximum = 4
```

The primary application is distributed across two Availability Zones behind an Application Load Balancer.

---

## Disaster-Recovery Region — Mumbai

```text
Region: ap-south-1
VPC:    10.1.0.0/16
```

Warm DR application capacity:

```text
MUM-APP-ASG

Minimum = 1
Desired = 1
Maximum = 2
```

Mumbai keeps a running application instance, load balancer, replicated database data, replicated object storage and regional container image so recovery does not require a complete infrastructure rebuild.

---

# Technology Stack

| Area | Technology |
|---|---|
| Cloud Platform | AWS |
| Infrastructure as Code | Terraform |
| Compute | Amazon EC2 |
| High Availability | Auto Scaling + Multi-AZ |
| Load Balancing | Application Load Balancer |
| DNS / Failover | Amazon Route 53 |
| Database | Amazon DynamoDB Global Tables |
| Database Recovery | DynamoDB Point-in-Time Recovery |
| Object Storage | Amazon S3 |
| Regional Object Protection | S3 Cross-Region Replication |
| Containerization | Docker |
| Container Registry | Amazon ECR |
| CI/CD | GitHub Actions |
| CI/CD Authentication | GitHub OIDC |
| Monitoring | Amazon CloudWatch |
| Notifications | Amazon SNS |
| Encryption | AWS KMS + S3/ECR server-side encryption |
| Access Control | AWS IAM |
| Private AWS Access | VPC Endpoints |

---

# Network Architecture

## Hyderabad VPC

```text
VPC: 10.0.0.0/16

Public Subnet A  : 10.0.0.0/27
Public Subnet B  : 10.0.0.32/27

Private Subnet A : 10.0.1.0/27
Private Subnet B : 10.0.1.32/27
```

## Mumbai VPC

```text
VPC: 10.1.0.0/16

Public Subnet A  : 10.1.0.0/27
Public Subnet B  : 10.1.0.32/27

Private Subnet A : 10.1.1.0/27
Private Subnet B : 10.1.1.32/27
```

Application EC2 instances are placed in **private subnets**.

The Application Load Balancers are public.

Application traffic follows:

```text
Internet
   ↓
ALB :80
   ↓
HTTP 301 Redirect
   ↓
ALB :443 (HTTPS / ACM)
   ↓
Application SG
   ↓
Private EC2 :5000
```

The current internship implementation uses **HTTPS on port 443 with AWS Certificate Manager (ACM)**. Port 80 is retained only to redirect clients to HTTPS. TLS terminates at the Application Load Balancer, which forwards traffic privately to the application on port 5000.

---

# Private AWS Service Access

The architecture intentionally does not use a NAT Gateway.

Private EC2 instances reach required AWS services through VPC endpoints:

```text
ECR API Interface Endpoint
ECR DKR Interface Endpoint
S3 Gateway Endpoint
DynamoDB Gateway Endpoint
```

Flow:

```text
Private EC2
     ↓
VPC Endpoint
     ↓
AWS Service
```

This keeps the application servers private while still allowing Docker image pulls and AWS service access.

---

# Application Deployment

The application is packaged as a Docker container.

```text
Application Source
      ↓
Docker Build
      ↓
finance-app Image
      ↓
Amazon ECR
      ↓
Private EC2
      ↓
Docker Container
```

The application listens internally on:

```text
Port 5000
```

The ALB Target Group health check uses:

```text
/health
```

---

# CI/CD Pipeline

GitHub Actions is used to build and publish the application image.

```text
Git Push
   ↓
GitHub Actions
   ↓
OIDC Authentication
   ↓
Docker Build
   ↓
Git SHA Tag
   ↓
 ┌────────────────┐
 ↓                ↓
HYD ECR         MUM ECR
```

AWS authentication uses:

```text
ELITE-SPARK-GITHUB-ACTIONS-ROLE
```

No long-lived AWS access keys are required in GitHub.

The same image version is pushed to both regional ECR repositories.

Verified project image consistency included matching image digests across Hyderabad and Mumbai.

---

# Database Architecture

The application uses:

```text
FIN-TRANSACTIONS
```

as a DynamoDB Global Table.

```text
HYD DynamoDB
      ↓
Asynchronous Replication
      ↓
MUM DynamoDB
```

Operational model:

```text
Normal Operation:
HYD = Active Writer
MUM = DR Replica

During DR:
MUM = Active Writer
```

The project avoids uncontrolled dual-region writes during failover.

---

# Database Protection

Database protection uses two different mechanisms:

```text
DynamoDB Global Tables
→ Regional availability

DynamoDB PITR
→ Historical recovery
```

Replication is not treated as a replacement for backup.

The project successfully demonstrated a Point-in-Time Recovery restore using:

```text
Restored Table:
FIN-TRANSACTIONS-RESTORE-DEMO
```

Recovered proof record:

```text
Transaction ID : TXN-C3D4BBBA03DA
Customer       : DELETE-RESTORE-DEMO
Amount         : 500
Type           : CREDIT
Status         : SUCCESS
```

---

# S3 Backup and Regional Protection

S3 uses:

```text
Versioning
+
Encryption
+
Lifecycle Management
+
Cross-Region Replication
```

Flow:

```text
HYD S3
   ↓
CRR
   ↓
MUM S3
```

Noncurrent object versions are retained for:

```text
30 days
```

before lifecycle expiration.

The project intentionally keeps:

```text
S3 CRR = Regional Copy
S3 Versioning = Historical Recovery
```

as separate concepts.

---

# Monitoring and Alerting

Primary monitoring dashboard:

```text
HYD-DR-DASHBOARD
```

Implemented alarms include:

```text
HYD-APP-HIGH-CPU
HYD-APP-UNHEALTHY-TARGET
HYD-DYNAMODB-SYSTEM-ERROR
HYD-ALB-HIGH-LATENCY
HYD-S3-REPLICATION-FAILURE
```

Notification topic:

```text
HYD-ALERTS
```

Operational flow:

```text
AWS Resource
    ↓
CloudWatch Metric
    ↓
CloudWatch Alarm
    ↓
SNS
    ↓
Operator Notification
```

---

# Auto Scaling and Self-Healing

Primary capacity:

```text
HYD-APP-ASG
2 → 4 → 2
```

was successfully tested.

Auto Scaling also provides failed-instance replacement:

```text
Instance Failure
      ↓
ASG Detects Unhealthy Instance
      ↓
Instance Replaced
      ↓
Docker Application Starts
      ↓
Target Group Health Check
      ↓
Healthy
```

---

# Disaster-Recovery Traffic Flow

Normal operation:

```text
User
  ↓
finance.best.2bd.net
  ↓
Route 53
  ↓
HYD-ALB
  ↓
HYD Application
```

Regional failure:

```text
HYD Unavailable
      ↓
Route 53 Failover
      ↓
MUM-ALB
      ↓
MUM Application
      ↓
MUM DynamoDB Replica
```

Failback is performed only after Hyderabad application health and database synchronization are verified.

---

# RPO Result

Project RPO target:

```text
≤ 1 minute
```

Controlled replication test:

```text
Transaction:
RPO-PROOF-20260913-232046

Observed Mumbai visibility:
3.97 seconds
```

Result:

```text
✅ Target achieved in the controlled test
```

The measured value is a project observation, not an AWS SLA.

---

# RTO Result

Project RTO target:

```text
≤ 5 minutes
```

Latest controlled regional recovery test:

```text
Failure initiated : 23:32:10
Service restored  : 23:33:45
Observed RTO      : 94.97 seconds
                   ≈ 1 minute 35 seconds
```

Result:

```text
✅ Target achieved
```

The failure was intentionally initiated. Recovery through the configured failover path was then observed and verified.

---

# Security Design

Security controls include:

```text
Private application EC2 instances
ALB-only application access
No public application port
IAM role separation and project-scoped permissions
GitHub OIDC
Regional KMS encryption
S3 encryption
ECR encryption
ECR image scanning
VPC endpoints
Separate Terraform states
```

Application IAM role:

```text
APP-EC2-ROLE
```

CI/CD role:

```text
ELITE-SPARK-GITHUB-ACTIONS-ROLE
```

The current application does not require a static database password because DynamoDB uses IAM-based authorization.

---

# Data Consistency During Failover

Main risks include:

```text
Replication lag
Duplicate requests
Stale reads
Conflicting writes
Unsafe failback
```

Mitigation includes:

```text
Single-writer regional model
Unique transaction IDs
Idempotent request handling
Data verification after failover
Controlled failback
DynamoDB PITR
```

---

# Cost Strategy

The project uses a **warm DR** design.

The major fixed DR cost drivers are:

```text
ECR Interface VPC Endpoints
Application Load Balancer
DR EC2 Instance
KMS / EBS / Monitoring
```

A low-traffic warm DR environment was estimated at approximately:

```text
$65–$75 / month
```

before significant request, storage, transfer or tax charges.

Possible lower-cost alternatives include:

```text
Pilot-Light DR
ASG desired capacity = 0
Provision ALB only during recovery
Pre-baked AMI strategy
Right-sized compute
Storage lifecycle policies
```

Lower cost normally increases RTO.

---

# Repository Structure

The current repository is organized as:

```text
ELITE-SPARK/
│
├── README.md
├── .gitignore
├── MULTI AVAILABILITY ELITE PROJECT.png
│
├── .github/
│   └── workflows/
│       └── ci-cd.yml
│
├── application/
│   ├── Dockerfile
│   ├── app.py
│   ├── requirements.txt
│   └── templates/
│       └── index.html
│
├── terraform/
│   ├── primary/
│   └── secondary/
│
├── Deliverables/
│   ├── Deliverable-01-Architecture.png
│   ├── Deliverable-02-SPOF-Analysis.md
│   ├── Deliverable-03-RPO-RTO.md
│   ├── Deliverable-04-Traffic-Redirection.md
│   ├── Deliverable-05-Database-Protection.md
│   ├── Deliverable-06-Backup-Strategy.md
│   ├── Deliverable-07-DR-Security.md
│   ├── Deliverable-08-Monitoring-and-Alerts.md
│   ├── Deliverable-09-Controlled-Failure-Test.md
│   ├── Deliverable-10-Data-Consistency.md
│   ├── Deliverable-11-IAM-Encryption-Secrets.md
│   ├── Deliverable-12-CICD-Multi-Region-Deployment.md
│   ├── Deliverable-13-DR-Cost-Estimate.md
│   ├── Deliverable-14-Primary-Database-Failure.md
│   └── Deliverable-15-Final-DR-Runbook.md
│
├── Demo Video/
│   └── README.MD
│
├── IAM PERMISSIONS/
│   ├── APP-EC2-ROLE/
│   │   ├── APP-EC2-DYNAMODB.json
│   │   ├── APP-EC2-ECR-PULL.json
│   │   └── APP-EC2-TRUSTPOLICY.json
│   │
│   ├── CUSTOMER-MANAGED-POLICY/
│   │   ├── ELITE-SPARK-DynamoDB-Terraform-Policy.json
│   │   ├── ELITE-SPARK-HTTPS-Terraform-Policy.json
│   │   ├── ELITE-SPARK-Mumbai-Build-Policy.json
│   │   ├── ELITE-SPARK-Mumbai-DR-Policy.json
│   │   └── ELITE-SPARK-Terraform-Policy.json
│   │
│   ├── GITHUB-ACTIONS-ROLE/
│   │   ├── ELITE-SPARK-GITHUB-ACTIONS-ROL.json
│   │   └── GITHUB-ACTION-TRUSTPOLICY.json
│   │
│   └── INLINE-USER-POLICY/
│       ├── Terraform-ECR-Project-policy.json
│       └── Terraform-Network-Read.json
│
└── Screenshot/
    └── Project implementation and validation evidence
```

---

# Deployment Order

The recommended deployment sequence is:

```text
1. IAM permission pre-check
2. Mumbai DR foundation
3. Hyderabad primary environment
4. DynamoDB Global Table
5. S3 versioning + CRR
6. IAM / KMS / VPC endpoints
7. GitHub OIDC
8. Docker build
9. Push same image to both ECR repositories
10. Start regional application environments
11. Verify ALB target health
12. Configure Route 53 failover
13. Configure CloudWatch + SNS
14. Test Auto Scaling
15. Test S3 replication
16. Test DynamoDB PITR
17. Measure RPO
18. Measure RTO
19. Verify failback
20. Save evidence
```

Operational deployment and recovery guidance is documented in:

```text
Deliverables/Deliverable-15-Final-DR-Runbook.md
```

## Rebuild / Reuse Note

The repository is reusable, but the current Terraform configuration is tailored to the original AWS account and implementation.

A fresh deployment should review or parameterize:

```text
AWS account-specific ARNs
Regional AMI IDs
Route 53 hosted zone / domain
ACM certificate references
ECR registry values
Existing IAM / OIDC prerequisites
```

The two Terraform states also contain cross-region dependencies. In particular, the Mumbai DynamoDB replica depends on the Hyderabad table, while the primary Route 53 configuration expects the Mumbai ALB to exist. Therefore, a completely fresh rebuild should be treated as a **staged deployment**, not assumed to be a single one-command apply.

---


# Disaster Recovery Runbook

The operational recovery process follows:

```text
Detect
  ↓
Classify
  ↓
Verify Primary
  ↓
Decide
  ↓
Verify DR
  ↓
Protect Data
  ↓
Fail Over
  ↓
Scale
  ↓
Verify Application
  ↓
Verify Data
  ↓
Operate in DR
  ↓
Repair Primary
  ↓
Verify Synchronization
  ↓
Fail Back
```

Full operational procedure:

```text
Deliverables/Deliverable-15-Final-DR-Runbook.md
```

---

# Project Evidence

The `Screenshot/` directory contains project implementation and validation evidence for:

```text
Architecture
Auto Scaling
Self-Healing
DynamoDB Global Table
DynamoDB PITR
S3 Versioning
S3 CRR
CloudWatch Dashboard
CloudWatch Alarms
SNS Notification
GitHub Actions
ECR Image Consistency
Route 53 Failover
RPO Test
RTO Test
Failback
```

Use clear evidence filenames instead of generic screenshot names.

Example:

```text
01-HYD-ASG-Healthy.png
02-MUM-ASG-Healthy.png
03-DynamoDB-Global-Table.png
04-PITR-Restore-Proof.png
05-S3-CRR-Proof.png
06-CloudWatch-Dashboard.png
07-GitHub-Actions-Success.png
08-RPO-3.97-Seconds.png
09-RTO-94.97-Seconds.png
10-Failback-Success.png
```

---

# Project Demo Videos

The complete project demonstration is split into focused validation videos hosted on **Google Drive**.

A dedicated video index is also available at:

[`Demo Video/README.MD`](Demo%20Video/README.MD)

| No. | Demo | Video |
|---:|---|---|
| 01 | Availability Zone Failure and Auto Scaling | [▶ Watch](https://drive.google.com/file/d/1ClLwATjsXi_y_BDgHpp3AgO3NqTCRBP8/view?usp=drive_link) |
| 02 | Active Region Check | [▶ Watch](https://drive.google.com/file/d/1-OfyEreYlinqHEO5MifkdF4nAKzXDE95/view?usp=drive_link) |
| 03 | Complete Transaction Recovery | [▶ Watch](https://drive.google.com/file/d/1bjIPfEAOFo1m3PxTvULeJ8v_nHvXCLUk/view?usp=drive_link) |
| 04 | CI/CD Test | [▶ Watch](https://drive.google.com/file/d/18tbpd5lxeT-WMkI7tstESVbmHuY1oI-E/view?usp=drive_link) |
| 05 | Monitoring Test | [▶ Watch](https://drive.google.com/file/d/1THwAnX4JPX8k0YI-qGbaSI014VwJDE71/view?usp=drive_link) |
| 06 | Network and Security Check | [▶ Watch](https://drive.google.com/file/d/1vYNH7PrsL4191c9poBR6Bjq29WBdLWz6/view?usp=drive_link) |
| 07 | IAM, Encryption and KMS Keys Verification | [▶ Watch](https://drive.google.com/file/d/1-CJulPL5Jt2RiaX0K0fSPe7xu2CfKrlL/view?usp=drive_link) |
| 08 | HTTP and HTTPS Verification | [▶ Watch](https://drive.google.com/file/d/1Me74nMLWYZUi1E5f5L8MoSZrmPMZMzly/view?usp=drive_link) |
| 09 | Complete Region Availability Check | [▶ Watch](https://drive.google.com/file/d/1dM2O1UBoqMKZbrZ4Eu6f62YZTbDIXXfR/view?usp=drive_link) |

The videos provide reviewable evidence for availability, recovery, CI/CD, monitoring, security, HTTPS and multi-region validation without storing large `.mp4` files directly in Git.

---

# Security Before GitHub Push

Do not commit:

```text
AWS access keys
Passwords
Private keys
PEM / PPK files
Terraform state
Terraform plan files
Environment secrets
```

Recommended `.gitignore` entries:

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfplan

# Environment and credentials
.env
.env.*
*.pem
*.ppk
*.key

# Python
.venv/
venv/
__pycache__/
*.pyc

# IDE / OS
.vscode/
.idea/
.DS_Store
Thumbs.db
```

---

# Current Limitations

This internship implementation currently has:

- TLS terminates at the ALB; backend ALB-to-application traffic remains HTTP on port 5000 inside the VPC
- Warm DR instead of active-active multi-region serving
- Smaller Mumbai compute capacity than Hyderabad
- Asynchronous DynamoDB regional replication
- DNS failover timing that can be influenced by caching
- GitHub Actions builds and pushes commit-SHA-tagged images, while the current EC2 launch templates pull `finance-app:v2`; runtime rollout is therefore not fully automated from the CI/CD workflow
- The GitHub Actions role and trust policy are documented in `IAM PERMISSIONS/`, but the role is not currently defined as a Terraform resource in the repository
- Some Terraform values are account/environment specific, so another AWS account must parameterize them before deployment
- A clean rebuild requires staged handling of cross-region dependencies rather than assuming a single one-pass Terraform apply
- No Kubernetes
- No Ansible
- No Prometheus or Grafana
- No NAT Gateway
- No AWS Backup service as the primary database-backup mechanism

These are documented limitations and implementation boundaries, not hidden gaps.

---

# Production Improvements

Possible future improvements include:

```text
AWS WAF
End-to-end TLS to the application tier where required
Higher Mumbai DR capacity
Application-aware synthetic monitoring
Automated failover orchestration
Stronger idempotency controls
Multi-account DR separation
CloudTrail / GuardDuty / AWS Config
Automated backup restore testing
Blue/Green deployments
Automated rollback
Centralized security logging
```

---

# Key Project Results

| Test | Target | Observed Result | Status |
|---|---:|---:|---|
| DynamoDB RPO | ≤ 1 minute | 3.97 seconds | ✅ Passed |
| Regional RTO | ≤ 5 minutes | 94.97 seconds | ✅ Passed |
| Primary Auto Scaling | 2 → 4 → 2 | Successful | ✅ Passed |
| EC2 Self-Healing | Automatic replacement | Successful | ✅ Passed |
| DynamoDB PITR Restore | Recover known record | Successful | ✅ Passed |
| S3 Cross-Region Replication | HYD → MUM | Successful | ✅ Passed |
| CI/CD Regional Image Consistency | Same artifact in both regions | Verified | ✅ Passed |

---

# Documentation

The repository includes separate documentation and evidence for:

1. Architecture
2. SPOF analysis
3. RPO and RTO
4. Traffic redirection
5. Database protection
6. Backup strategy
7. DR security
8. Monitoring and alerting
9. Controlled failure testing
10. Data consistency
11. IAM, encryption and secrets
12. CI/CD multi-region image publishing
13. Cost estimation
14. Primary database failure
15. Final DR runbook
16. Demo video index
17. IAM role, trust-policy, customer-managed-policy and inline-policy JSON references
18. Implementation screenshots and validation evidence

Primary operational guidance:

```text
Deliverables/Deliverable-15-Final-DR-Runbook.md
```

Demo index:

```text
Demo Video/README.MD
```

IAM reference material:

```text
IAM PERMISSIONS/
```

---

# Final Project Flow

```text
USER REQUEST
     ↓
ROUTE 53
     ↓
PRIMARY HYDERABAD
     ↓
ALB
     ↓
AUTO SCALING
     ↓
PRIVATE DOCKER EC2
     ↓
DYNAMODB
     ↓
MONITORING / BACKUP / REPLICATION
     ↓
PRIMARY FAILURE
     ↓
ROUTE 53 FAILOVER
     ↓
MUMBAI WARM DR
     ↓
APPLICATION CONTINUES
     ↓
VERIFY DATA
     ↓
REPAIR PRIMARY
     ↓
CONTROLLED FAILBACK
```

---

# Conclusion

ELITE SPARK demonstrates an end-to-end AWS disaster-recovery and business-continuity architecture using a combination of **multi-AZ high availability, warm multi-region DR, DynamoDB Global Tables, S3 replication, Terraform, Docker, GitHub Actions, Route 53 failover, CloudWatch monitoring and controlled recovery testing**.

The project does not only show an architecture diagram. It demonstrates:

```text
Build
  ↓
Deploy
  ↓
Monitor
  ↓
Protect
  ↓
Fail
  ↓
Recover
  ↓
Verify
  ↓
Fail Back
```

The controlled tests achieved the project's defined recovery targets while also documenting current limitations and production hardening opportunities.

---

## Author

**Sujith**

Cloud / DevOps Internship Project — ELITE SPARK
