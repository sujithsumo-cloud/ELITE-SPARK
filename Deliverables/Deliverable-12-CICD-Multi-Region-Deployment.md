# Deliverable 12 — CI/CD Process for Consistent Multi-Region Deployment

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**Application Packaging:** Docker  
**Container Registry:** Amazon ECR  
**CI/CD Platform:** GitHub Actions  
**AWS Authentication:** GitHub OIDC

---

## 1. Objective

The CI/CD process must deploy the **same application version** consistently to both Hyderabad and Mumbai.

The main goal is:

```text
One Source Code Version
        ↓
One Docker Build
        ↓
Same Image Version
        ↓
HYD ECR + MUM ECR
        ↓
Controlled Deployment
```

This avoids version differences between the primary and DR environments.

---

## 2. CI/CD Architecture

```text
Developer
    ↓
GitHub Repository
    ↓
GitHub Actions
    ↓
OIDC Authentication
    ↓
Docker Build
    ↓
Image Tagging
    ↓
 ┌─────────────────────┐
 ↓                     ↓
HYD ECR              MUM ECR
ap-south-2           ap-south-1
    ↓                     ↓
HYD Application       MUM DR Application
```

---

## 3. Source-Control Workflow

The application source code is stored in GitHub.

Typical flow:

```text
Code Change
    ↓
Git Commit
    ↓
Push to Repository
    ↓
GitHub Actions Workflow Starts
```

This provides:

- version control,
- change history,
- repeatable builds,
- rollback reference,
- CI/CD automation.

---

## 4. AWS Authentication with OIDC

GitHub Actions uses:

```text
ELITE-SPARK-GITHUB-ACTIONS-ROLE
```

Authentication flow:

```text
GitHub Actions
      ↓
OIDC Token
      ↓
AWS IAM Role
      ↓
Temporary AWS Credentials
```

This avoids storing long-lived AWS access keys inside GitHub.

Benefits:

- temporary credentials,
- reduced secret exposure,
- IAM-controlled permissions,
- safer CI/CD authentication.

---

## 5. Build the Application Once

The application is packaged using Docker.

```text
Source Code
    ↓
Docker Build
    ↓
finance-app Image
```

The image should be created from the same source commit so that both regions receive the same application build.

---

## 6. Image Tagging Strategy

The workflow can use:

```text
Git Commit SHA
```

as an immutable application version.

Example:

```text
finance-app:<commit-sha>
```

This makes it easy to identify exactly which code version is deployed.

The project also used release-style tags such as:

```text
v2
```

The Git SHA remains the strongest reference for exact version tracking.

---

## 7. Push the Same Image to Both Regions

After the image is built:

```text
Docker Image
     ↓
Tag for HYD ECR
     ↓
Push to ap-south-2

Docker Image
     ↓
Tag for MUM ECR
     ↓
Push to ap-south-1
```

Regional repositories:

```text
HYD ECR → finance-app
MUM ECR → finance-app
```

This ensures that both environments have the same deployable artifact.

---

## 8. Verified Multi-Region Image Consistency

The project verified that the same SHA-tagged image existed in both regions.

Verified digest:

```text
sha256:2186a43c1b90c89375f7348fa0468f0a1771cb8b5c6ac68aeb4ef01b8e6f38f0
```

The `v2` image was also verified with the same digest in both regions:

```text
sha256:d4df1ec7cb95020e1b33603395a206b314bfefe9dab5c3eb908f1e7e9dcdee57
```

This proved that the same container artifact was available in Hyderabad and Mumbai.

---

## 9. Deployment Flow

The deployment process is:

```text
Git Push
   ↓
GitHub Actions
   ↓
OIDC Authentication
   ↓
Docker Build
   ↓
Tag Image
   ↓
Push to HYD ECR
   ↓
Push to MUM ECR
   ↓
Verify Image Digests
   ↓
Controlled Runtime Promotion
```

The build-and-push process is automated.

Runtime promotion remains controlled so that a new build is not blindly activated in both production paths without verification.

---

## 10. Primary Deployment

For Hyderabad:

```text
HYD ECR
   ↓
Launch Template / Application Configuration
   ↓
HYD-APP-ASG
   ↓
EC2
   ↓
Docker Pull
   ↓
finance-app Container
```

The application instances pull the required image and start the Docker container.

---

## 11. DR Deployment

For Mumbai:

```text
MUM ECR
   ↓
DR Launch Template / Application Configuration
   ↓
MUM-APP-ASG
   ↓
EC2
   ↓
Docker Pull
   ↓
finance-app Container
```

The DR environment therefore does not depend on the Hyderabad ECR repository.

This is important during a regional outage.

---

## 12. Consistency Control

The main consistency rule is:

```text
Same Source Commit
      ↓
Same Docker Build
      ↓
Same Version Tag
      ↓
Same Image Digest
      ↓
Both Regional ECR Repositories
```

This prevents:

- different application versions,
- manual packaging differences,
- configuration drift in the application artifact.

---

## 13. Deployment Verification

After CI/CD completes, verify:

```text
GitHub Workflow Success
        ↓
HYD ECR Image Exists
        ↓
MUM ECR Image Exists
        ↓
Image Digests Match
        ↓
Application Health Check
        ↓
Deployment Approved
```

Application verification includes:

```text
/health
```

The ALB Target Group should show healthy application targets after deployment.

---

## 14. Rollback Strategy

If a new application version fails:

```text
Bad New Version
      ↓
Select Previous Known-Good Tag / SHA
      ↓
Update Runtime Configuration
      ↓
Restart / Replace Application Instances
      ↓
Verify /health
```

Because previous application versions are identifiable by image tags and Git commit history, rollback is controlled and repeatable.

---

## 15. CI/CD Security

The CI/CD pipeline is protected using:

| Security Control | Purpose |
|---|---|
| GitHub OIDC | Avoid long-lived AWS keys |
| IAM role | Limit deployment permissions |
| ECR encryption | Protect images at rest |
| ECR scan-on-push | Scan images for known vulnerabilities |
| Git version control | Track application changes |
| Immutable SHA tags | Identify exact build version |

---

## 16. Deployment Failure Handling

If one regional push fails:

```text
HYD Push ✅
MUM Push ❌
```

the deployment should not be considered fully successful.

The workflow should report failure and prevent uncontrolled promotion.

Correct response:

```text
Detect Failed Regional Push
        ↓
Stop Promotion
        ↓
Fix Error
        ↓
Re-run Pipeline
        ↓
Verify Both Regions
```

This prevents primary and DR environments from drifting to different application versions.

---

## 17. CI/CD Process Summary

```text
Developer
    ↓
GitHub
    ↓
GitHub Actions
    ↓
OIDC
    ↓
Docker Build
    ↓
SHA Tag
    ↓
 ┌───────────────┐
 ↓               ↓
HYD ECR        MUM ECR
 ↓               ↓
Verify Digest Match
        ↓
Controlled Deployment
        ↓
Health Verification
```

---

## 18. Current Project Implementation

The project implemented:

```text
GitHub Actions
+
OIDC Authentication
+
Docker Build
+
Push to Hyderabad ECR
+
Push to Mumbai ECR
+
Same SHA-Tagged Image
+
Digest Verification
+
Controlled Runtime Promotion
```

This provides a repeatable multi-region application delivery process.

---

## 19. Production Improvements

For a larger production environment, additional controls could include:

- automated unit tests,
- integration tests,
- vulnerability gates,
- blue/green deployment,
- canary deployment,
- manual approval before production promotion,
- automatic rollback on failed health checks,
- deployment notifications,
- signed container images.

These are future improvements and should not all be claimed as implemented in the current internship project.

---

## 20. Conclusion

The ELITE SPARK CI/CD design ensures deployment consistency by building the application once from GitHub source, packaging it as a Docker image, authenticating to AWS through OIDC, and pushing the same application version to ECR repositories in both Hyderabad and Mumbai.

The key consistency rule is:

```text
Same Commit
   ↓
Same Image
   ↓
Same Tag
   ↓
Same Digest
   ↓
Both Regions
```

This reduces manual deployment errors and ensures that the DR region is ready with the same application artifact as the primary environment.

---

## Interview Answer

> I designed the CI/CD process using GitHub Actions, Docker, Amazon ECR and GitHub OIDC. When code is pushed to GitHub, the workflow authenticates to AWS using the `ELITE-SPARK-GITHUB-ACTIONS-ROLE`, builds one Docker image, tags it using the Git commit SHA, and pushes the same application version to the `finance-app` ECR repository in both Hyderabad and Mumbai. I verify that the image digests match in both regions before promotion. This ensures the primary and DR environments use the same application artifact and prevents configuration drift. Runtime deployment is controlled so that a failed regional push or failed health check does not automatically promote an inconsistent version.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 12:** CI/CD Process for Consistent Primary and Disaster-Recovery Deployment
