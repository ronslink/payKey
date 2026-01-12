# Multi-User Load Testing Guide

## 🎯 Overview

Testing with **multiple users making concurrent transactions** is critical for PayKey because:

1. **Multi-Tenant Architecture** - Each employer is a separate tenant
2. **Database Isolation** - Ensures users can't see each other's data
3. **Resource Contention** - Tests database locks, connection pools
4. **Real-World Scenarios** - End-of-month when many employers process payroll simultaneously

---

## 🆚 Single-User vs Multi-User Testing

### Single-User Testing (`k6-performance-test.js`)
- ✅ Tests API performance
- ✅ Measures response times
- ✅ Validates scalability
- ❌ All requests use the **same user account**
- ❌ Doesn't test multi-tenant isolation
- ❌ Doesn't reveal tenant-specific issues

### Multi-User Testing (`k6-multi-user-test.js`)
- ✅ Creates **multiple employer accounts**
- ✅ Each virtual user represents a different employer
- ✅ Tests data isolation (users can't see each other's workers)
- ✅ Tests database locking and concurrency
- ✅ Reveals multi-tenant bugs
- ✅ **This is what you asked for!**

---

## 🚀 Running Multi-User Tests

### Test 1: Basic Multi-User Load Test

**File**: `k6-multi-user-test.js`

This creates **10 employers** by default and simulates them all using PayKey concurrently.

```bash
# Navigate to test directory
cd /Users/ron/Desktop/payKey/backend/test/load

# Run with 10 employers (default)
k6 run k6-multi-user-test.js

# Run with 20 employers
k6 run -e NUM_USERS=20 k6-multi-user-test.js

# Run with custom base URL and 15 employers
k6 run \
  -e BASE_URL=http://localhost:3000 \
  -e NUM_USERS=15 \
  k6-multi-user-test.js
```

**What it does**:
1. **Setup Phase**: Creates N employer accounts (e.g., 10)
2. **Test Phase**: Virtual users randomly pick employers and perform:
   - List workers
   - Calculate taxes
   - Check pay periods
   - Create workers (20% chance)
   - Check accounting
3. **Result**: See how the system handles multiple tenants simultaneously

---

### Test 2: Realistic Business Scenarios

**File**: `k6-realistic-scenarios.js`

This simulates **three concurrent scenarios** that happen in real business:

```bash
# Run realistic scenario test
k6 run k6-realistic-scenarios.js
```

**Scenarios Simulated**:

1. **Monthly Payroll Rush** (20 employers)
   - Creates pay period
   - Calculates payroll
   - Reviews statistics
   - Processes payroll
   - **Tests**: Heavy database writes, transaction locks

2. **Worker Management** (10 employers, continuous)
   - List workers
   - Add new workers
   - Update worker salaries
   - **Tests**: Concurrent reads/writes, data isolation

3. **Tax Filing Deadline** (30 employers, spike)
   - Retrieve submissions
   - Calculate taxes for multiple workers
   - Submit tax returns
   - **Tests**: Deadline spike handling, CPU load

**Timeline**:
```
0min ━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━8min
         │   │   │   │   │   │   │
Payroll: ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
Workers: ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
Tax:         ▓▓▓▓▓▓▓▓▓▓
```

---

## 📊 What to Monitor During Multi-User Tests

### Database Issues to Watch For

#### 1. **Connection Pool Exhaustion**
```bash
# Monitor during test
docker-compose exec db psql -U postgres -d paykey -c \
  "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';"
```

**Warning Signs**:
- Error: `too many clients already`
- Connections > 50 (default pool size)

**Solution**:
```env
# backend/.env
DB_CONNECTION_POOL_SIZE=100
```

#### 2. **Deadlocks**
```bash
# Check for deadlocks
docker-compose exec db psql -U postgres -d paykey -c \
  "SELECT * FROM pg_stat_database WHERE datname = 'paykey';"
```

**Warning Signs**:
- Error: `deadlock detected`
- Conflicting transactions
- High `deadlocks` count in pg_stat_database

**Solution**: Review transaction isolation levels and query order

#### 3. **Slow Queries Under Load**
```bash
# Enable query logging
docker-compose exec db psql -U postgres -d paykey -c \
  "ALTER SYSTEM SET log_min_duration_statement = 1000;" # Log queries > 1s
```

**Check logs**:
```bash
docker-compose logs db | grep "duration:"
```

#### 4. **Data Isolation Issues** (Critical!)
If users can see each other's data, you have a **security bug**.

**Test manually**:
1. Create 2 employers via the multi-user test
2. Login as Employer 1
3. Try to access Employer 2's workers
4. Should return 0 or 403 Forbidden

---

## 🎯 Expected Results

### Baseline Performance (10 Employers)

| Metric | Target | Critical |
|--------|--------|----------|
| http_req_duration (p95) | < 800ms | < 1500ms |
| http_req_failed | < 2% | < 5% |
| Payroll processing | < 10s | < 20s |
| Worker creation | < 500ms | < 1000ms |
| Database connections | < 50 | < 80 |

### Expected Test Output

```
scenarios: (100.00%) 3 scenarios, 60 max VUs, 8m30s max duration
┌─────────────────────┬──────────┬───────────┐
│ Scenario            │ VUs      │ Duration  │
├─────────────────────┼──────────┼───────────┤
│ monthly_payroll     │ 0 → 20   │ 8m        │
│ worker_management   │ 10       │ 8m        │
│ tax_filing         │ 0 → 30   │ 4m        │
└─────────────────────┴──────────┴───────────┘

✓ [Employer 1] workers list successful
✓ [Employer 3] payroll calculated
✓ [Employer 5] tax calculated for 45000
✓ [Employer 2] worker created

checks.........................: 98.50% ✓ 2851 ✗ 43
data_received..................: 8.5 MB  17 kB/s
http_req_duration..............: avg=485ms p(95)=1250ms
http_req_failed................: 1.50%  ✓ 43   ✗ 2851
concurrent_payrolls............: 387
payroll_processing_time........: avg=8500ms p(95)=15000ms
payroll_success_rate...........: 96.50% ✓ 374  ✗ 13
worker_creation_time...........: avg=245ms p(95)=580ms
```

---

## 🐛 Troubleshooting Multi-User Tests

### Issue 1: Setup Fails to Create Users
```
❌ Failed to setup user 5: 500
```

**Causes**:
- Backend not ready
- Database connection issues
- Rate limiting

**Solution**:
```bash
# Increase setup delay
sleep(0.5); // Instead of sleep(0.2)

# Or reduce number of users
k6 run -e NUM_USERS=5 k6-multi-user-test.js
```

### Issue 2: High Error Rate During Test
```
http_req_failed: 15.00% ✓ 450 ✗ 2550
```

**Causes**:
- Database connection pool exhausted
- Deadlocks
- Memory/CPU limits

**Debug**:
```bash
# Check Docker resources
docker stats paykey_backend

# Check database connections
docker-compose exec db psql -U postgres -d paykey -c \
  "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"

# Check backend logs
docker-compose logs --tail=100 backend | grep -i error
```

### Issue 3: Data Leakage Between Users
```
[Employer 1] workers list returned 50 workers (should be 5)
```

**This is a CRITICAL SECURITY BUG!**

**Check**:
1. Review `workers.service.ts` - ensure queries filter by `userId`
2. Review API guards - ensure JWT extracts correct user
3. Test database queries:
```sql
SELECT workers.*, users.email 
FROM workers 
JOIN users ON workers."userId" = users.id 
WHERE users.email = 'loadtest-employer1@paykey.com';
```

---

## 🎓 Advanced Scenarios

### Scenario 1: Peak Usage (End of Month)
Simulate 50 employers processing payroll simultaneously:

```bash
k6 run \
  -e NUM_USERS=50 \
  --stage 2m:100 \
  --stage 10m:100 \
  --stage 2m:0 \
  k6-multi-user-test.js
```

### Scenario 2: New Customer Onboarding Spike
Simulate 100 new employers signing up:

```bash
k6 run \
  -e NUM_USERS=100 \
  --stage 5m:200 \
  --stage 5m:0 \
  k6-multi-user-test.js
```

### Scenario 3: Tax Deadline (Quarterly)
Heavy read operations:

```bash
k6 run k6-realistic-scenarios.js
# Review the tax_filing_deadline scenario metrics
```

---

## 📈 Metrics to Track

### Application-Level Metrics

| Metric | What it Tests | Why Important |
|--------|--------------|---------------|
| `concurrent_payrolls` | How many payrolls running at once | Peak usage capacity |
| `payroll_success_rate` | % of payrolls that complete | Data integrity |
| `worker_creation_time` | Time to add worker | User experience |
| `api_errors` | Failed requests by error type | Reliability |

### Database-Level Metrics

```bash
# Query stats
docker-compose exec db psql -U postgres -d paykey -c \
  "SELECT calls, mean_exec_time, query FROM pg_stat_statements 
   ORDER BY mean_exec_time DESC LIMIT 10;"

# Lock stats
docker-compose exec db psql -U postgres -d paykey -c \
  "SELECT * FROM pg_locks WHERE granted = false;"

# Connection stats
docker-compose exec db psql -U postgres -d paykey -c \
  "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"
```

---

## ✅ Success Criteria for Multi-User Testing

### Must Pass:
- ✅ Zero data leakage (users can't see other users' data)
- ✅ < 5% error rate
- ✅ No database deadlocks
- ✅ < 80 concurrent database connections
- ✅ Payroll success rate > 95%

### Should Pass:
- ✅ p95 response time < 1500ms
- ✅ Payroll processing < 15s
- ✅ Worker creation < 500ms
- ✅ Graceful handling of connection pool exhaustion

### Nice to Have:
- ✅ p95 response time < 800ms
- ✅ Payroll processing < 10s
- ✅ Zero failed requests
- ✅ Auto-scaling on high load

---

## 🔗 Related Documentation

- [Load Testing Guide](../../../docs/LOAD_TESTING_GUIDE.md)
- [Test Coverage Analysis](../../../docs/TEST_COVERAGE_ANALYSIS.md)
- [E2E Test Setup](../../../docs/E2E_TEST_SETUP.md)

---

## 🎯 Quick Reference

```bash
# Basic multi-user (10 employers)
k6 run k6-multi-user-test.js

# Heavy load (50 employers)
k6 run -e NUM_USERS=50 k6-multi-user-test.js

# Realistic scenarios (payroll rush + tax deadline)
k6 run k6-realistic-scenarios.js

# Monitor database during test
docker-compose exec db psql -U postgres -d paykey -c \
  "SELECT count(*) FROM pg_stat_activity;"

# Check for errors
docker-compose logs backend | grep -i error
```

---

**Last Updated**: December 11, 2025  
**Purpose**: Multi-tenant load testing for PayKey SaaS application
