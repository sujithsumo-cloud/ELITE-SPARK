# Deliverable 09 — Controlled Failure Test and Recovery Results

## Project: ELITE SPARK

**Primary Region:** Hyderabad (`ap-south-2`)  
**DR Region:** Mumbai (`ap-south-1`)  
**Public DNS:** `finance.best.2bd.net`  
**DR Strategy:** Warm Disaster Recovery  
**RTO Target:** `≤ 5 minutes`

---

## 1. Objective

The purpose of this test was to confirm that the application could recover from a controlled primary-region failure and continue serving users through the Mumbai disaster-recovery environment.

The test recorded:

- failure start time,
- failure detection mechanism,
- recovery sequence,
- service restoration time,
- and final recovery duration.

---

## 2. Test Scenario

A controlled failure was manually introduced in the Hyderabad primary environment.

Normal traffic flow:

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

After the failure:

```text
HYD Primary Unavailable
        ↓
Route 53 Health / Failover Evaluation
        ↓
Mumbai Secondary Selected
        ↓
MUM-ALB
        ↓
MUM Application
        ↓
Service Restored
```

---

## 3. Test Timeline

| Event | Recorded Result |
|---|---|
| Failure initiated | **23:32:10** |
| Failure detection | Route 53 / endpoint health evaluation detected the primary as unavailable |
| Exact standalone detection timestamp | **Not separately captured in the final evidence** |
| DR endpoint selected | During the automated failover sequence |
| Service restored through Mumbai | **23:33:45** |
| Final measured recovery time | **94.97 seconds (~1 min 35 sec)** |
| RTO target | **≤ 5 minutes** |
| Result | **✅ RTO target met** |

> The failure was manually initiated. Detection, DNS failover, and service recovery after the failure condition were handled by the configured recovery path.

---

## 4. Failure Injection

The test intentionally made the Hyderabad primary application path unavailable.

```text
Healthy HYD Application
        ↓
Controlled Failure Initiated
        ↓
Primary Endpoint Becomes Unavailable
```

Failure start:

```text
23:32:10
```

The purpose was to simulate a serious primary application or regional infrastructure failure without waiting for a real outage.

---

## 5. Failure Detection

The regional failover design depended on the health of the primary application endpoint.

```text
HYD Endpoint
     ↓
Health Evaluation
     ↓
Healthy / Unhealthy
     ↓
Route 53 Failover Decision
```

Once the primary endpoint was considered unavailable, traffic could be directed to the Mumbai secondary environment.

### Detection-Time Note

A separate timestamp for the exact moment the health state changed to unhealthy was not preserved in the final test evidence.

Therefore, the report does **not invent a detection timestamp**.

The detection interval is included inside the measured end-to-end recovery time:

```text
Failure
  ↓
Detection
  ↓
Failover
  ↓
Recovery
```

---

## 6. Recovery Steps

The recovery process was:

```text
1. Controlled HYD failure initiated
        ↓
2. Primary application endpoint became unavailable
        ↓
3. Health/failover mechanism evaluated primary endpoint
        ↓
4. Route 53 selected the Mumbai secondary path
        ↓
5. Client traffic reached MUM-ALB
        ↓
6. MUM-ALB routed requests to healthy DR targets
        ↓
7. Mumbai Docker application served the request
        ↓
8. DR application used replicated DynamoDB data
        ↓
9. Application health was verified
```

No complete rebuild of the Mumbai infrastructure was required because it was already prepared as a warm DR environment.

---

## 7. DR Environment Used During Recovery

The recovery path used:

```text
Route 53
   ↓
MUM-ALB
   ↓
MUM-APP-TG
   ↓
MUM-APP-ASG
   ↓
EC2 / Docker Application
   ↓
DynamoDB Global Table Replica
```

Supporting DR components already existed in Mumbai:

- DR VPC
- public and private subnets
- Application Load Balancer
- Target Group
- Auto Scaling Group
- Docker application
- Mumbai ECR repository
- DynamoDB Global Table replica

---

## 8. Recovery Verification

Service restoration was verified through the application endpoint.

```text
finance.best.2bd.net
        ↓
Mumbai DR Path
        ↓
Application Responded Successfully
```

Recorded restoration time:

```text
23:33:45
```

This confirmed that the service was available again through the DR region.

---

## 9. Recovery-Time Calculation

Failure time:

```text
23:32:10
```

Recovery time:

```text
23:33:45
```

Measured test result:

```text
94.97 seconds
≈ 1 minute 35 seconds
```

Project RTO target:

```text
≤ 5 minutes
= ≤ 300 seconds
```

Comparison:

```text
Observed RTO = 94.97 seconds
Target RTO   = 300 seconds

94.97 < 300
```

Result:

```text
✅ RTO TARGET MET
```

---

## 10. Recovery Flow

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
                    HYD PRIMARY PATH
                            │
                         FAILURE
                            │
                            ▼
                  Primary Unavailable
                            │
                            ▼
                 Health / Failover Check
                            │
                            ▼
                      Route 53 DR
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
                    Docker Application
                            │
                            ▼
                  DynamoDB DR Replica
                            │
                            ▼
                     SERVICE RESTORED
```

---

## 11. What Was Automated and Manual?

### Manual

```text
Controlled failure initiation
```

### Automated / Preconfigured Recovery Path

```text
Health evaluation
        ↓
Route 53 failover behavior
        ↓
Traffic redirection
        ↓
Mumbai application serving requests
```

This distinction is important.

The project does **not** claim that the disaster itself was automatically created or that every operational decision was zero-touch.

---

## 12. Test Result Summary

| Item | Result |
|---|---|
| Controlled failure performed | ✅ |
| Primary endpoint became unavailable | ✅ |
| Failover mechanism activated | ✅ |
| Mumbai DR served application | ✅ |
| Service recovery verified | ✅ |
| Recovery time measured | ✅ |
| Observed RTO | **94.97 sec** |
| RTO target | **≤ 5 min** |
| Target achieved | ✅ |

---

## 13. Test Limitations

The test had several important limitations:

- the failure was intentionally initiated rather than caused by a real AWS regional outage,
- the exact standalone health-detection timestamp was not separately recorded,
- DNS/client caching can affect failover time,
- the measured RTO is an observed test result, not a guaranteed recovery time,
- the environment used warm DR rather than active-active architecture.

These limitations should be documented rather than hidden.

---

## 14. Conclusion

The controlled failure test demonstrated that the ELITE SPARK application could recover from loss of the Hyderabad primary application path by serving traffic through the Mumbai warm DR environment.

The recorded test was:

```text
Failure Started : 23:32:10
Service Restored: 23:33:45

Observed RTO:
94.97 seconds
≈ 1 minute 35 seconds

Target RTO:
≤ 5 minutes

Result:
✅ PASSED
```

The failure itself was manually initiated, while the configured Route 53/service recovery path handled traffic transition to Mumbai.

The test therefore demonstrated that the observed recovery performance was within the project's defined RTO target.

---

## Interview Answer

> I performed a controlled failure test by intentionally making the Hyderabad primary application path unavailable. The failure started at 23:32:10. The primary endpoint was then detected as unavailable by the configured health and failover mechanism, and Route 53 redirected application traffic to the Mumbai warm DR environment. Mumbai already had the ALB, Auto Scaling Group, Docker application and DynamoDB replica available, so no full infrastructure rebuild was required. The application was successfully available through Mumbai at 23:33:45. The measured end-to-end recovery time was 94.97 seconds, or about 1 minute 35 seconds, which was inside our RTO target of five minutes. The exact standalone health-detection timestamp was not separately captured, so I document that as a test limitation rather than inventing a value.

---

**Deliverable Status:** ✅ Complete  
**Deliverable 09:** Controlled Failure Test, Detection, Recovery Steps and Final Recovery Time
