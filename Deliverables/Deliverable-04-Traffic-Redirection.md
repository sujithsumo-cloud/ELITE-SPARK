# Deliverable 04 — Application Traffic Redirection During Failure

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**Public DNS:** `finance.best.2bd.net`  
**DR Strategy:** Warm Disaster Recovery

---

## 1. Objective

The application must continue serving users when:

- an EC2 instance fails,
- an Availability Zone becomes unavailable,
- the primary application infrastructure becomes unhealthy,
- or the Hyderabad region experiences a major outage.

The ELITE SPARK design handles failures at two levels:

```text
Infrastructure failure inside Hyderabad
        ↓
ALB + Target Group + Auto Scaling

Regional failure in Hyderabad
        ↓
Route 53 redirects traffic to Mumbai
```

---

## 2. Normal Traffic Flow

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
Healthy EC2 / Docker Application
  ↓
DynamoDB FIN-TRANSACTIONS
```

Hyderabad is the primary region.

Mumbai remains available as the warm DR region.

---

## 3. EC2 Instance Failure

If one EC2 instance becomes unhealthy:

```text
User
  ↓
HYD-ALB
  ↓
Target Group Health Check
  ↓
One EC2 becomes unhealthy
```

The Target Group uses the application health endpoint:

```text
/health
```

The ALB stops sending traffic to the unhealthy instance.

```text
              HYD-ALB
                 │
        ┌────────┴────────┐
        ↓                 ↓
   Healthy EC2        Failed EC2
      ✅                 ❌
        │
        ▼
Traffic continues
```

At the same time:

```text
EC2 failure
   ↓
Auto Scaling detects capacity loss
   ↓
Replacement EC2 is launched
   ↓
Health check passes
   ↓
Instance returns to service
```

A single EC2 failure therefore does not require regional failover.

---

## 4. Availability Zone Failure

The primary environment is distributed across multiple Availability Zones.

```text
            HYD-ALB
               │
       ┌───────┴───────┐
       ↓               ↓
     AZ-A             AZ-B
      │                 │
     EC2               EC2
```

If one Availability Zone becomes unavailable:

```text
AZ failure
   ↓
Targets in that AZ become unhealthy
   ↓
ALB sends traffic to healthy targets
   ↓
Auto Scaling maintains required capacity
```

This provides high availability inside the primary region.

---

## 5. Regional Failure

If Hyderabad experiences a regional application failure, local ALB and Auto Scaling recovery are not enough.

At this point the multi-region DR mechanism is used.

```text
Hyderabad unavailable
        ↓
Primary endpoint unhealthy
        ↓
Route 53 failover
        ↓
Mumbai DR
```

---

## 6. Route 53 Failover

The DNS architecture is:

```text
                finance.best.2bd.net
                        │
                        ▼
                     Route 53
                        │
              ┌─────────┴─────────┐
              │                   │
              ▼                   ▼
          HYD-ALB              MUM-ALB
          Primary              Secondary
```

Normal operation:

```text
User → Route 53 → Hyderabad
```

Failure operation:

```text
HYD endpoint unavailable
        ↓
Route 53 failover condition
        ↓
Mumbai secondary endpoint selected
        ↓
User traffic reaches MUM-ALB
```

---

## 7. Complete Regional Failover Flow

```text
                     USER
                       │
                       ▼
              finance.best.2bd.net
                       │
                       ▼
                    Route 53
                       │
                       ▼
              HYD Primary Endpoint
                       │
                       ▼
                 HYD Failure
                       │
                       ▼
            Primary becomes unhealthy
                       │
                       ▼
              Route 53 Failover
                       │
                       ▼
                   MUM-ALB
                       │
                       ▼
                 MUM-APP-TG
                       │
                       ▼
                 MUM-APP-ASG
                       │
                       ▼
               MUM EC2 Instances
                       │
                       ▼
               Docker Application
                       │
                       ▼
          DynamoDB Global Table Replica
```

---

## 8. Database Availability During Failover

Application traffic redirection is useful only if the database is also available in the DR region.

The project uses a DynamoDB Global Table:

```text
HYD DynamoDB
FIN-TRANSACTIONS
       │
       │ Cross-Region Replication
       ▼
MUM DynamoDB
FIN-TRANSACTIONS
```

During failover:

```text
User
 ↓
MUM Application
 ↓
MUM DynamoDB Replica
```

This allows the DR application to continue using replicated transaction data.

---

## 9. Application Image Availability

The Docker application image was stored in ECR in both regions.

```text
HYD ECR → finance-app
MUM ECR → finance-app
```

This prevents the Mumbai environment from depending on the Hyderabad ECR repository during a regional failure.

---

## 10. Failure Type and Traffic Response

| Failure | Traffic Handling |
|---|---|
| Single EC2 failure | ALB stops routing to unhealthy target |
| EC2 capacity loss | Auto Scaling launches replacement instance |
| Availability Zone failure | ALB sends traffic to healthy AZ |
| Application target failure | Target Group health checks remove unhealthy target |
| Primary regional application failure | Route 53 redirects users to Mumbai |
| Hyderabad regional outage | Mumbai warm DR serves the application |

---

## 11. Failover and Failback

### Failover

```text
HYD Healthy
   ↓
Users use Hyderabad

HYD Failure
   ↓
Route 53 Failover
   ↓
Users use Mumbai
```

### Failback

After Hyderabad is restored and verified healthy:

```text
HYD restored
    ↓
Health verified
    ↓
Primary endpoint becomes usable
    ↓
Traffic returns to Hyderabad
```

Normal architecture:

```text
Hyderabad = Primary
Mumbai    = DR
```

---

## 12. Observed Failover Result

Latest controlled test:

```text
Failure initiated:
23:32:10

Service available through Mumbai:
23:33:45
```

Observed recovery time:

```text
94.97 seconds
≈ 1 minute 35 seconds
```

Project RTO target:

```text
≤ 5 minutes
```

Result:

```text
94.97 seconds < 5 minutes
Status = ✅ Target met
```

The primary failure was manually initiated for the test. After the failure condition was created, the Route 53/service recovery path handled the transition to the DR environment.

---

## 13. Why Failover Is Not Instant

Regional failover may take some time because of:

```text
Failure
  ↓
Health-check evaluation
  ↓
Route 53 failover decision
  ↓
DNS response update
  ↓
Client / DNS cache behavior
  ↓
Connection to Mumbai
```

Therefore, the project does not claim zero recovery time.

---

## 14. Final Traffic Architecture

```text
                              USERS
                                │
                                ▼
                    finance.best.2bd.net
                                │
                                ▼
                             Route 53
                                │
               ┌────────────────┴────────────────┐
               │                                 │
               ▼                                 ▼
       HYDERABAD PRIMARY                    MUMBAI DR
          ap-south-2                        ap-south-1
               │                                 │
           HYD-ALB                           MUM-ALB
               │                                 │
         HYD-APP-TG                        MUM-APP-TG
               │                                 │
         HYD-APP-ASG                       MUM-APP-ASG
          /       \                         /       \
        EC2       EC2                     EC2       EC2
          \       /                         \       /
        Docker App                        Docker App
               │                                 │
               └──────────────┬──────────────────┘
                              │
                       DynamoDB Global
                            Table
                      HYD ↔ MUM Replica
```

---

## 15. Conclusion

The ELITE SPARK architecture uses two levels of traffic recovery:

1. **Infrastructure-level recovery inside Hyderabad**
   - ALB
   - Target Group health checks
   - Auto Scaling
   - Multi-AZ deployment

2. **Regional disaster recovery**
   - Route 53 failover
   - Mumbai warm DR environment
   - MUM ALB and Auto Scaling
   - DynamoDB Global Table replica
   - Regional ECR image availability

This allows the application to continue operating during both infrastructure failures and a larger primary-region failure.

---

## Interview Answer

> During normal operation, users access `finance.best.2bd.net`, and Route 53 directs traffic to the Hyderabad Application Load Balancer. If an individual EC2 instance or Availability Zone fails, the ALB health checks stop routing traffic to unhealthy targets while Auto Scaling replaces failed capacity. If the Hyderabad regional application endpoint becomes unavailable, Route 53 failover routing redirects users to the Mumbai warm DR environment. Mumbai already contains the ALB, Auto Scaling Group, Docker application, regional ECR image and DynamoDB Global Table replica. During our controlled test, service recovery through Mumbai was observed in approximately 94.97 seconds.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 04:** Application Traffic Redirection During Infrastructure and Regional Failure
