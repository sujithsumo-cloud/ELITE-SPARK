# 🎥 ELITE SPARK — Demo Videos

This document contains the demonstration video links for the **ELITE SPARK — Multi-Region Disaster Recovery, High Availability, Backup and Business Continuity** project.

The videos are hosted on **Google Drive** so the GitHub repository remains lightweight and easy to clone.

---

## 📌 Project Demo Video Index

### 01 — Availability Zone Failure and Auto Scaling

**Purpose:** Demonstrates how the application responds to an Availability Zone / instance failure and how Auto Scaling helps maintain availability.

▶️ **Watch Video:**  
[01 — Availability Zone Failure and Auto Scaling](https://drive.google.com/file/d/1ClLwATjsXi_y_BDgHpp3AgO3NqTCRBP8/view?usp=drive_link)

---

### 02 — Active Region Check

**Purpose:** Verifies which AWS Region is currently serving the application and confirms the active-region response.

▶️ **Watch Video:**  
[02 — Active Region Check](https://drive.google.com/file/d/1-OfyEreYlinqHEO5MifkdF4nAKzXDE95/view?usp=drive_link)

---

### 03 — Complete Transaction Recovery

**Purpose:** Demonstrates transaction/data recovery and verifies that the finance application data can be recovered as part of the disaster-recovery workflow.

▶️ **Watch Video:**  
[03 — Complete Transaction Recovery](https://drive.google.com/file/d/1bjIPfEAOFo1m3PxTvULeJ8v_nHvXCLUk/view?usp=drive_link)

---

### 04 — CI/CD Test

**Purpose:** Demonstrates the GitHub Actions CI/CD workflow used to validate, build, and push the Dockerized finance application to Amazon ECR.

▶️ **Watch Video:**  
[04 — CI/CD Test](https://drive.google.com/file/d/18tbpd5lxeT-WMkI7tstESVbmHuY1oI-E/view?usp=drive_link)

---

### 05 — Monitoring Test

**Purpose:** Demonstrates the monitoring layer used in the project, including operational visibility and AWS monitoring verification.

▶️ **Watch Video:**  
[05 — Monitoring Test](https://drive.google.com/file/d/1THwAnX4JPX8k0YI-qGbaSI014VwJDE71/view?usp=drive_link)

---

### 06 — Network and Security Check

**Purpose:** Demonstrates the network and security configuration used by the project, including VPC, subnet, routing, and security controls.

▶️ **Watch Video:**  
[06 — Network and Security Check](https://drive.google.com/file/d/1vYNH7PrsL4191c9poBR6Bjq29WBdLWz6/view?usp=drive_link)

---

### 07 — IAM, Encryption and KMS Keys Verification

**Purpose:** Demonstrates IAM access control and verifies the project's encryption/security configuration.

▶️ **Watch Video:**  
[07 — IAM, Encryption and KMS Keys Verification](https://drive.google.com/file/d/1-CJulPL5Jt2RiaX0K0fSPe7xu2CfKrlL/view?usp=drive_link)

---

### 08 — HTTP and HTTPS Verification

**Purpose:** Verifies the application's HTTP-to-HTTPS behavior and confirms secure HTTPS access through the Application Load Balancer and ACM certificate.

▶️ **Watch Video:**  
[08 — HTTP and HTTPS Verification](https://drive.google.com/file/d/1Me74nMLWYZUi1E5f5L8MoSZrmPMZMzly/view?usp=drive_link)

---

### 09 — Complete Region Availability Check

**Purpose:** Demonstrates final regional availability verification across the Hyderabad primary Region and Mumbai disaster-recovery Region.

▶️ **Watch Video:**  
[09 — Complete Region Availability Check](https://drive.google.com/file/d/1dM2O1UBoqMKZbrZ4Eu6f62YZTbDIXXfR/view?usp=drive_link)

---

# 🏗️ Architecture Covered by the Demo

```text
User
  ↓
Route 53 Failover Routing
  ↓
Primary Region — Hyderabad (ap-south-2)
  ↓
Application Load Balancer
  ↓
Auto Scaling Group
  ↓
Private EC2 Instances
  ↓
Docker → Gunicorn → Flask
  ↓
DynamoDB Global Table
  ↕
Disaster Recovery Region — Mumbai (ap-south-1)
```

The videos collectively demonstrate:

- Multi-Region Disaster Recovery
- Multi-AZ High Availability
- Auto Scaling
- Application Load Balancer
- Dockerized Flask application
- Amazon ECR
- DynamoDB Global Table
- Point-in-Time Recovery
- Route 53 failover routing
- HTTPS with AWS Certificate Manager
- IAM roles and policies
- VPC networking and security
- CloudWatch monitoring
- Terraform Infrastructure as Code
- GitHub Actions CI/CD
- Backup and recovery validation
- Business continuity testing

---

# 🔗 Video Hosting

All demo videos are hosted externally on **Google Drive**.

Recommended sharing configuration:

```text
General access: Anyone with the link
Permission: Viewer
```

This keeps large `.mp4` files out of the Git repository while still making the demonstrations available to reviewers.

---

# ✅ Demo Coverage Summary

| No. | Demo | Status |
|---:|---|:---:|
| 01 | Availability Zone Failure and Auto Scaling | ✅ |
| 02 | Active Region Check | ✅ |
| 03 | Complete Transaction Recovery | ✅ |
| 04 | CI/CD Test | ✅ |
| 05 | Monitoring Test | ✅ |
| 06 | Network and Security Check | ✅ |
| 07 | IAM, Encryption and KMS Keys Verification | ✅ |
| 08 | HTTP and HTTPS Verification | ✅ |
| 09 | Complete Region Availability Check | ✅ |

---

## Project

**ELITE SPARK**  
**Multi-Region Disaster Recovery, High Availability, Backup and Business Continuity**

