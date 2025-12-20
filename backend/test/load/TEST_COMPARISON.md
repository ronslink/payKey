# Load Test Comparison Guide

## 🎯 Which Load Test Should I Run?

Quick decision matrix to choose the right test for your needs:

| Scenario | Test to Use | Duration | Users |
|----------|-------------|----------|-------|
| **Quick smoke test** | `k6-performance-test.js --vus 10 --duration 1m` | 1 min | 10 VUs |
| **Basic performance check** | `k6-performance-test.js` | 16 min | 0→100→200 |
| **Multi-tenant verification** | `k6-multi-user-test.js` | 9 min | 10 employers |
| **End-of-month simulation** | `k6-realistic-scenarios.js` | 8 min | 30 employers |
| **Stress test** | `k6-multi-user-test.js -e NUM_USERS=50` | 9 min | 50 employers |

---

## 📋 Detailed Comparison

### Test 1: Single-User Performance Test
**File**: `k6-performance-test.js`

| Aspect | Details |
|--------|---------|
| **Purpose** | Measure API performance and response times |
| **Users** | 1 test account, multiple virtual users |
| **What it tests** | API speed, scalability, throughput |
| **What it doesn't test** | Multi-tenancy, data isolation, resource contention |
| **Best for** | Daily CI/CD checks, baseline performance |
| **Run time** | 16 minutes (full), 1 minute (smoke) |
| **Command** | `k6 run k6-performance-test.js` |

**Pros**:
- ✅ Fast setup (1 user)
- ✅ Easy to debug
- ✅ Good for API benchmarks
- ✅ Perfect for CI/CD

**Cons**:
- ❌ Doesn't test multi-tenancy
- ❌ Won't catch data leakage bugs
- ❌ Doesn't simulate realistic usage

**Sample Output**:
```
http_req_duration..............: avg=145ms p(95)=285ms
http_req_failed................: 0.00%
workers_duration...............: avg=125ms p(95)=245ms
tax_duration...................: avg=450ms p(95)=850ms
```

---

### Test 2: Multi-User/Multi-Tenant Test
**File**: `k6-multi-user-test.js`

| Aspect | Details |
|--------|---------|
| **Purpose** | Test multiple distinct tenants concurrently |
| **Users** | 10+ distinct employer accounts |
| **What it tests** | Data isolation, concurrency, multi-tenant architecture |
| **What it doesn't test** | Complex business workflows |
| **Best for** | Security testing, multi-tenant validation |
| **Run time** | 9 minutes |
| **Command** | `k6 run k6-multi-user-test.js` |

**Pros**:
- ✅ Tests data isolation (critical for SaaS)
- ✅ Reveals multi-tenant bugs
- ✅ Tests database locking
- ✅ Realistic concurrent usage

**Cons**:
- ❌ Longer setup (creates N users)
- ❌ More complex to debug
- ❌ Requires more database resources

**Sample Output**:
```
✓ [User 1] workers list successful
✓ [User 3] tax calculation successful
✓ [User 5] worker created
✓ [User 2] accounting check

concurrent users: 10
http_req_duration..............: avg=245ms p(95)=650ms
api_errors.....................: 15 (1.2%)
```

---

### Test 3: Realistic Business Scenarios
**File**: `k6-realistic-scenarios.js`

| Aspect | Details |
|--------|---------|
| **Purpose** | Simulate real business workflows and peak usage |
| **Users** | 30 distinct employers across 3 scenarios |
| **What it tests** | End-of-month rushes, tax deadlines, continuous operations |
| **What it doesn't test** | Individual API performance |
| **Best for** | Pre-production validation, capacity planning |
| **Run time** | 8 minutes |
| **Command** | `k6 run k6-realistic-scenarios.js` |

**Pros**:
- ✅ Most realistic test
- ✅ Tests actual business workflows
- ✅ Reveals bottlenecks
- ✅ Tests peak usage patterns

**Cons**:
- ❌ Longest setup time
- ❌ Most complex
- ❌ Hardest to debug

**Sample Output**:
```
scenarios: 3 active
  monthly_payroll_rush....: 20 VUs, 8m duration
  worker_management.......: 10 VUs, 8m duration
  tax_filing_deadline.....: 30 VUs, 4m duration

concurrent_payrolls............: 387
payroll_success_rate...........: 96.50%
payroll_processing_time........: avg=8500ms p(95)=15000ms
```

---

## 🎓 When to Use Each Test

### Daily Development
```bash
# Quick validation after code changes
k6 run --vus 10 --duration 30s k6-performance-test.js
```
**Why**: Fast, catches performance regressions

### Before Merging PR
```bash
# Full single-user test
k6 run k6-performance-test.js
```
**Why**: Ensures no performance degradation

### Weekly Testing
```bash
# Multi-tenant validation
k6 run k6-multi-user-test.js
```
**Why**: Catches multi-tenant bugs, verifies data isolation

### Before Release
```bash
# Realistic scenarios
k6 run k6-realistic-scenarios.js

# Heavy multi-user load
k6 run -e NUM_USERS=50 k6-multi-user-test.js
```
**Why**: Validates production-readiness, capacity planning

### After Infrastructure Changes
```bash
# All tests in sequence
k6 run k6-performance-test.js
k6 run k6-multi-user-test.js
k6 run k6-realistic-scenarios.js
```
**Why**: Comprehensive validation of new infrastructure

---

## 🔍 What Each Test Reveals

### Security Issues
| Issue | Detected By |
|-------|-------------|
| Data leakage between tenants | ✅ `k6-multi-user-test.js` |
| Unauthorized access | ✅ `k6-multi-user-test.js` |
| SQL injection | ⚠️ All tests (if exists) |
| Auth bypass | ✅ All tests |

### Performance Issues
| Issue | Detected By |
|-------|-------------|
| Slow API endpoints | ✅ `k6-performance-test.js` |
| Database bottlenecks | ✅ `k6-realistic-scenarios.js` |
| Connection pool exhaustion | ✅ `k6-multi-user-test.js` |
| Memory leaks | ✅ All long-running tests |

### Scalability Issues
| Issue | Detected By |
|-------|-------------|
| Can't handle 100 concurrent users | ✅ `k6-performance-test.js` |
| Can't handle 50 tenants | ✅ `k6-multi-user-test.js` |
| Payroll rush crashes system | ✅ `k6-realistic-scenarios.js` |
| Database deadlocks | ✅ `k6-realistic-scenarios.js` |

---

## 📊 Success Criteria by Test

### Single-User Performance Test
```
✅ PASS if:
- http_req_duration p95 < 500ms
- http_req_failed < 1%
- No database errors
- No memory leaks

⚠️ WARNING if:
- http_req_duration p95 > 500ms but < 1000ms
- http_req_failed > 1% but < 5%

❌ FAIL if:
- http_req_duration p95 > 1000ms
- http_req_failed > 5%
- Database connection errors
```

### Multi-User Test
```
✅ PASS if:
- No data leakage (users can't see others' data)
- http_req_failed < 2%
- No deadlocks
- DB connections < 80

⚠️ WARNING if:
- http_req_failed > 2% but < 5%
- DB connections > 80 but < 100
- Occasional deadlocks (< 5)

❌ FAIL if:
- Data leakage detected (CRITICAL!)
- http_req_failed > 5%
- DB connections exhausted
- Frequent deadlocks (> 10)
```

### Realistic Scenarios
```
✅ PASS if:
- payroll_success_rate > 95%
- payroll_processing_time p95 < 15s
- No system crashes
- concurrent_payrolls > 300

⚠️ WARNING if:
- payroll_success_rate > 90% but < 95%
- payroll_processing_time p95 > 15s but < 30s
- Memory usage > 80%

❌ FAIL if:
- payroll_success_rate < 90%
- payroll_processing_time p95 > 30s
- System crashes or OOM errors
- Database locks system
```

---

## 🚀 Quick Start Commands

### I want to test basic performance:
```bash
k6 run k6-performance-test.js
```

### I want to verify multi-tenant security:
```bash
k6 run k6-multi-user-test.js
```

### I want to test end-of-month scenarios:
```bash
k6 run k6-realistic-scenarios.js
```

### I want to stress test with many tenants:
```bash
k6 run -e NUM_USERS=50 k6-multi-user-test.js
```

### I want a quick smoke test (fastest):
```bash
k6 run --vus 10 --duration 1m k6-performance-test.js
```

---

## 📚 Learn More

- [Load Testing Guide](../../../docs/LOAD_TESTING_GUIDE.md) - Complete guide
- [Multi-User Testing Guide](../../../docs/MULTI_USER_LOAD_TESTING.md) - Multi-tenant testing
- [Test Coverage Analysis](../../../docs/TEST_COVERAGE_ANALYSIS.md) - Gap analysis

---

**Last Updated**: December 11, 2025
