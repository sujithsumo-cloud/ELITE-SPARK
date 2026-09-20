# Deliverable 11 — IAM Roles, Encryption Keys and Secrets Across Primary and DR Environments

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**DR Strategy:** Warm Disaster Recovery

---

## 1. Objective

The primary and disaster-recovery environments must use the same security principles.

The main rule is:

```text
Primary Security
      =
DR Security
```

IAM permissions, encryption and secrets handling should remain consistent across both regions so that the recovery environment does not become a weaker security boundary.

---

## 2. IAM Role Strategy

The application uses IAM roles instead of static AWS access keys.

Main application role:

```text
APP-EC2-ROLE
```

Flow:

```text
EC2 Application
      ↓
APP-EC2-ROLE
      ↓
Temporary AWS Credentials
      ↓
DynamoDB / ECR / Required AWS Services
```

The role follows least privilege.

Example DynamoDB permissions include:

```text
dynamodb:GetItem
dynamodb:PutItem
dynamodb:UpdateItem
dynamodb:Query
dynamodb:Scan
```

The application does not require full administrative access.

---

## 3. IAM Across Primary and DR

The same permission model should be used in both environments.

```text
Hyderabad Application
        ↓
Least-Privilege IAM Role

Mumbai DR Application
        ↓
Least-Privilege IAM Role
```

The DR region should **not** receive broader permissions just because it is used during emergencies.

Bad design:

```text
Primary → Least Privilege
DR      → AdministratorAccess
```

Correct design:

```text
Primary → Required Permissions Only
DR      → Required Permissions Only
```

This keeps both environments at the same security level.

---

## 4. CI/CD IAM Role

GitHub Actions uses:

```text
ELITE-SPARK-GITHUB-ACTIONS-ROLE
```

Authentication flow:

```text
GitHub Actions
      ↓
OIDC
      ↓
AWS IAM Role
      ↓
Temporary Credentials
      ↓
ECR / Deployment Actions
```

This avoids storing long-lived AWS access keys in GitHub.

The same CI/CD workflow can authenticate securely and push application images to both Hyderabad and Mumbai ECR repositories.

---

## 5. No Static AWS Credentials

The project avoids:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

inside:

- application source code,
- Docker images,
- GitHub repository,
- Terraform files,
- EC2 user data.

Instead:

```text
IAM Role
   ↓
Temporary Credentials
```

This reduces credential leakage risk.

---

## 6. Encryption Strategy

Encryption is applied to important stored data.

### DynamoDB

DynamoDB uses KMS encryption.

```text
HYD FIN-TRANSACTIONS
        ↓
KMS Encryption
```

and:

```text
MUM FIN-TRANSACTIONS
        ↓
KMS Encryption
```

Because KMS keys are regional, Hyderabad and Mumbai use separate region-specific encryption keys.

Concept:

```text
HYD Data
   ↓
HYD KMS Key

MUM Data
   ↓
MUM KMS Key
```

The security policy should remain equivalent across both keys.

---

## 7. Why Separate Regional KMS Keys?

AWS KMS keys are regional resources.

Therefore:

```text
Hyderabad KMS Key
        ≠
Mumbai KMS Key
```

The DR environment should not depend on only one regional key.

If the primary region is unavailable:

```text
HYD Region unavailable
        ↓
MUM Application
        ↓
MUM DynamoDB
        ↓
MUM Regional KMS Key
```

This keeps encryption available in the recovery region.

---

## 8. KMS Key Access Control

Only required IAM principals should be allowed to use encryption keys.

Concept:

```text
Application / AWS Service
        ↓
IAM Permission
        ↓
KMS Key Policy
        ↓
Encrypt / Decrypt
```

Key administration and application usage should be separated where possible.

Example principle:

```text
Application Role
→ Use key as required

Administrator
→ Manage key configuration
```

The application should not receive unnecessary KMS administrative permissions.

---

## 9. S3 Encryption

The project uses server-side encryption for S3.

```text
HYD S3
   ↓
AES-256 Encryption
```

and:

```text
MUM S3
   ↓
AES-256 Encryption
```

Cross-region replicated objects remain protected in the DR region.

```text
HYD S3
   ↓
CRR
   ↓
MUM S3
   ↓
Encrypted
```

---

## 10. ECR Encryption

The Docker application image is stored in ECR in both regions.

```text
HYD ECR
finance-app
   ↓
Encrypted

MUM ECR
finance-app
   ↓
Encrypted
```

This ensures that the recovery image repository is protected using the same security principle as the primary repository.

---

## 11. Secrets Strategy

The current application does **not** require a static database password.

DynamoDB access uses IAM authorization.

```text
Application
    ↓
IAM Role
    ↓
DynamoDB
```

Therefore, the project did not require a separate database credential stored in Secrets Manager.

This is better than using:

```text
DB_USERNAME
DB_PASSWORD
```

inside application code.

---

## 12. If Future Secrets Are Required

If future application components require:

- API keys,
- database passwords,
- third-party credentials,
- private tokens,

they should be stored in a managed secret service such as AWS Secrets Manager.

Recommended design:

```text
Application
    ↓
IAM Role
    ↓
Secrets Manager
    ↓
Retrieve Secret at Runtime
```

Secrets should never be hardcoded in:

- GitHub,
- Terraform source,
- Docker images,
- application code,
- EC2 user data.

---

## 13. Secrets Across Primary and DR

If secrets are introduced later, the DR region must also have access to them.

Two safe approaches are:

```text
Option 1:
Regional secret replication

Option 2:
Create equivalent regional secrets
with controlled synchronization
```

The important requirement is:

```text
DR Application
     ↓
Can securely retrieve required secret
     ↓
Without depending entirely on HYD
```

This prevents a primary-region outage from also blocking secret access in Mumbai.

---

## 14. Separation of Responsibilities

Security responsibilities should remain separated.

```text
Application Role
→ Runtime access only

GitHub Actions Role
→ CI/CD deployment permissions

Terraform Operator
→ Infrastructure provisioning

KMS Administration
→ Encryption-key management
```

One role should not be given every permission.

This reduces the impact of credential misuse or compromise.

---

## 15. Primary vs DR Security Mapping

| Security Area | Hyderabad Primary | Mumbai DR |
|---|---|---|
| EC2 IAM role | Least privilege | Least privilege |
| Static AWS keys | Not required | Not required |
| GitHub authentication | OIDC | OIDC |
| DynamoDB encryption | KMS | KMS |
| KMS key | Regional HYD key | Regional MUM key |
| S3 encryption | AES-256 | AES-256 |
| ECR encryption | Enabled | Enabled |
| DB password | Not required | Not required |
| Secrets Manager | Not required currently | Not required currently |
| Terraform management | Primary state | Secondary state |

---

## 16. Failure Scenario

If Hyderabad becomes unavailable:

```text
HYD Failure
    ↓
Route 53 Failover
    ↓
Mumbai Application
    ↓
MUM IAM Role
    ↓
MUM DynamoDB
    ↓
MUM KMS Key
```

The recovery region continues operating without depending on Hyderabad IAM runtime credentials or a Hyderabad-only encryption key.

---

## 17. Security Risks and Mitigation

| Risk | Mitigation |
|---|---|
| DR has excessive permissions | Use least-privilege IAM |
| Long-lived AWS keys leak | Use IAM roles and OIDC |
| Primary KMS key unavailable | Use regional DR key |
| Unencrypted DR data | Encrypt DynamoDB, S3 and ECR |
| Secret stored in source code | Use managed secrets if required |
| DR secret unavailable | Replicate or create regional secret |
| One role controls everything | Separate runtime, CI/CD and infrastructure roles |

---

## 18. Current Project Reality

The implemented project uses:

```text
IAM Role-Based Authentication
+
GitHub OIDC
+
DynamoDB KMS Encryption
+
S3 AES-256 Encryption
+
ECR Encryption
```

The application does **not** currently use Secrets Manager because there are no static application database credentials that require storage.

This should be documented clearly rather than claiming a secrets service was implemented when it was not.

---

## 19. Conclusion

IAM, encryption and secrets are handled consistently across both ELITE SPARK regions.

```text
IAM Roles
→ Temporary credentials and least privilege

KMS
→ Regional encryption for DynamoDB

S3 / ECR Encryption
→ Protect stored objects and images

OIDC
→ Secure CI/CD authentication

Secrets
→ No static DB password required currently
```

The main design principle is:

> The recovery environment should have the credentials and encryption capability required to operate independently, while maintaining the same least-privilege and encryption standards as the primary environment.

---

## Interview Answer

> I handle IAM, encryption and secrets using the same security baseline in both regions. The EC2 application uses `APP-EC2-ROLE` with least-privilege permissions instead of static AWS keys, while GitHub Actions uses OIDC through `ELITE-SPARK-GITHUB-ACTIONS-ROLE` so no long-lived CI/CD credentials are stored. DynamoDB is encrypted using regional KMS keys, so Hyderabad and Mumbai each have their own regional key and the DR environment does not depend on a Hyderabad-only key. S3 and ECR are also encrypted. The current application does not require a database password because DynamoDB uses IAM authentication, so Secrets Manager was not necessary. If future secrets are required, they should be stored in a managed secret service and made available securely in both regions.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 11:** IAM Roles, Encryption Keys and Secrets Across Primary and Recovery Environments
