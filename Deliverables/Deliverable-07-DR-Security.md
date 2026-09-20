# Deliverable 07 — Securing the Disaster Recovery Environment

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**DR Strategy:** Warm Disaster Recovery

---

## 1. Objective

The disaster-recovery environment must not become a weaker security boundary than the primary environment.

Main principle:

```text
Primary Security Controls
          =
DR Security Controls
```

The Mumbai DR environment follows the same security baseline as Hyderabad.

---

## 2. Security Architecture

```text
                        USERS
                          │
                          ▼
                     Route 53
                          │
             ┌────────────┴────────────┐
             │                         │
             ▼                         ▼
       HYDERABAD                    MUMBAI
        PRIMARY                       DR
             │                         │
         Public ALB                Public ALB
             │                         │
         ALB-SG                    ALB-SG
             │                         │
             ▼                         ▼
        Private EC2               Private EC2
             │                         │
         APP-SG                    APP-SG
             │                         │
             ▼                         ▼
        AWS Services              AWS Services
     through VPC endpoints     through VPC endpoints
```

---

## 3. Separate Network Boundary

The two regions use separate VPCs:

```text
Hyderabad VPC : 10.0.0.0/16
Mumbai DR VPC : 10.1.0.0/16
```

Benefits:

- isolates the DR environment,
- prevents accidental overlap,
- reduces unintended cross-region access,
- keeps unrelated resources separate.

The project does not use VPC peering between the two ELITE SPARK VPCs.

---

## 4. Private Application Servers

Application EC2 instances run in private subnets.

```text
Internet
   ↓
Public ALB
   ↓
Private EC2
```

This means application servers are not directly exposed to the Internet.

Benefits:

- smaller attack surface,
- traffic must pass through the ALB,
- better control using security groups.

---

## 5. Security Group Protection

### ALB Security Group

```text
Internet
   ↓
Port 80
   ↓
Application Load Balancer
```

### Application Security Group

```text
ALB Security Group
        ↓
     Port 5000
        ↓
Application Security Group
        ↓
Private EC2
```

The EC2 application receives traffic only from the ALB security group.

---

## 6. No Direct Public SSH

The application instances are not designed for open Internet SSH access.

```text
Internet
   X
 SSH :22
   X
Private EC2
```

This reduces:

- brute-force attacks,
- unauthorized access,
- unnecessary public exposure.

---

## 7. Private AWS Service Access

Private EC2 instances use VPC endpoints for AWS services.

Implemented endpoints:

- ECR API
- ECR DKR
- S3
- DynamoDB

```text
Private EC2
     ↓
VPC Endpoint
     ↓
AWS Service
```

This allows AWS service access without requiring direct public Internet connectivity.

---

## 8. IAM Least Privilege

The application uses:

```text
APP-EC2-ROLE
```

The role contains only the permissions required by the application.

Example DynamoDB actions:

```text
dynamodb:GetItem
dynamodb:PutItem
dynamodb:UpdateItem
dynamodb:Query
dynamodb:Scan
```

Flow:

```text
Application
     ↓
APP-EC2-ROLE
     ↓
Allowed DynamoDB Actions
     ↓
FIN-TRANSACTIONS
```

The DR environment does not receive broader permissions simply because it is used for recovery.

---

## 9. GitHub Actions Authentication

CI/CD uses GitHub OIDC.

```text
GitHub Actions
      ↓
OIDC
      ↓
AWS IAM Role
      ↓
Temporary Credentials
```

Role used:

```text
ELITE-SPARK-GITHUB-ACTIONS-ROLE
```

This avoids storing long-lived AWS access keys in the repository.

---

## 10. Encryption

The DR environment uses encryption for important data.

### DynamoDB

```text
DynamoDB
   ↓
KMS Encryption
```

### S3

```text
S3
 ↓
Server-Side Encryption
```

### ECR

```text
Docker Image
    ↓
ECR
    ↓
Encrypted Storage
```

The Mumbai environment follows the same encryption principle as Hyderabad.

---

## 11. Cross-Region Data Protection

Replicated data remains protected in the DR region.

### DynamoDB

```text
HYD DynamoDB
      ↓
Global Table Replication
      ↓
MUM DynamoDB
      ↓
Encrypted
```

### S3

```text
HYD S3
   ↓
Cross-Region Replication
   ↓
MUM S3
   ↓
Encrypted
```

---

## 12. Container Image Security

The application image is stored in ECR in both regions.

```text
GitHub Actions
      ↓
Docker Build
      ↓
 ┌──────────────┐
 ↓              ↓
HYD ECR      MUM ECR
```

ECR security includes:

- encryption,
- image scanning on push.

This prevents the DR container repository from becoming a weaker copy of the application.

---

## 13. Terraform Isolation

Primary and DR infrastructure are managed separately.

```text
terraform/
   ├── primary/
   └── secondary/
```

Separate Terraform states reduce accidental changes across regions.

Benefits:

- clearer ownership,
- safer deployments,
- easier troubleshooting,
- reduced risk of changing unrelated resources.

---

## 14. Resource Naming and Tagging

DR resources use clear names such as:

```text
DR-VPC
MUM-ALB
MUM-APP-TG
MUM-APP-ASG
MUM-ALB-SG
MUM-APP-SG
MUM-ENDPOINT-SG
```

Typical tags identify:

```text
Project
Environment
Region
ManagedBy
```

Clear naming and tagging reduce operational mistakes.

---

## 15. Monitoring and Alerts

The DR environment should remain visible even when it is not actively serving users.

```text
AWS Resources
      ↓
CloudWatch
      ↓
Alarm
      ↓
SNS
      ↓
Operator
```

Monitoring helps identify:

- unhealthy application targets,
- high latency,
- database errors,
- replication issues,
- infrastructure problems.

---

## 16. Secrets Handling

The application does not require a static database password because DynamoDB uses IAM-based authorization.

```text
No Hardcoded DB Password
        ↓
IAM Role Authentication
```

Sensitive values should not be stored in:

- GitHub source code,
- Terraform files,
- Docker images,
- EC2 user data.

If future components require secrets, a managed secret-storage solution should be used.

---

## 17. Primary vs DR Security

| Security Control | Hyderabad | Mumbai DR |
|---|---|---|
| Dedicated VPC | ✅ | ✅ |
| Private EC2 subnets | ✅ | ✅ |
| Public ALB only | ✅ | ✅ |
| Direct public EC2 access | ❌ | ❌ |
| Security groups | ✅ | ✅ |
| VPC endpoints | ✅ | ✅ |
| IAM least privilege | ✅ | ✅ |
| DynamoDB encryption | ✅ | ✅ |
| S3 encryption | ✅ | ✅ |
| ECR encryption | ✅ | ✅ |
| ECR image scanning | ✅ | ✅ |
| Separate Terraform management | ✅ | ✅ |

The goal is:

```text
Security Parity Between Primary and DR
```

---

## 18. Threat and Mitigation Summary

| Risk | Mitigation |
|---|---|
| DR EC2 exposed to Internet | Private subnets |
| Direct access to application server | ALB-only traffic |
| Excessive AWS permissions | IAM least privilege |
| Long-lived CI/CD credentials | GitHub OIDC |
| Unencrypted database | DynamoDB encryption |
| Unencrypted objects | S3 encryption |
| Unsafe container images | ECR scanning + encryption |
| Public AWS-service access | VPC endpoints |
| Accidental cross-environment changes | Separate VPCs and Terraform states |
| Unmonitored DR resources | CloudWatch + SNS |

---

## 19. Current Limitation

The implemented project uses:

```text
HTTP :80
```

HTTPS was not implemented in the final internship environment.

For a production environment, the recommended improvement would be:

```text
HTTPS :443
    ↓
ACM Certificate
    ↓
ALB TLS Termination
```

This should be documented as a current limitation rather than claiming TLS is already implemented.

---

## 20. Conclusion

The Mumbai DR environment is secured using the same core principles as the Hyderabad primary environment.

```text
Separate VPC
      +
Private Subnets
      +
Security Groups
      +
VPC Endpoints
      +
IAM Least Privilege
      +
OIDC Authentication
      +
Encryption
      +
ECR Image Scanning
      +
Monitoring
      +
Separate Terraform State
```

The key principle is:

> Disaster recovery should change where the workload runs, not reduce the security standard required to run it.

---

## Interview Answer

> I secured the Mumbai disaster-recovery environment using the same security baseline as the Hyderabad primary region. Application EC2 instances are placed in private subnets and receive traffic only from the Application Load Balancer through security-group rules. AWS service access uses VPC endpoints for ECR, S3 and DynamoDB. IAM roles follow least privilege, GitHub Actions uses OIDC instead of long-lived AWS access keys, and DynamoDB, S3 and ECR data are encrypted. ECR image scanning is also enabled. Primary and DR infrastructure are managed using separate VPCs, clear naming and separate Terraform states. The current project uses HTTP, so HTTPS with ACM would be an important production security improvement.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 07:** Disaster Recovery Environment Security
