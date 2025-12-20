# Load Testing Guide for PayKey

## 📋 Overview

This guide provides comprehensive instructions for load testing the PayKey application using **k6**, ensuring the backend (running in Docker) can handle production-level traffic.

## 🎯 Testing Strategy

### Test Coverage Gaps Identified

Based on analysis of the existing test suite:

#### **Backend Testing** ✅ Strong E2E Coverage
- **122 passing E2E tests** covering all major features
- **Missing**: Unit tests for complex service logic (tax calculations, payroll deductions)
- **Issue**: Performance test (`test/performance/performance.ts`) doesn't properly seed workers

#### **Mobile Testing** ⚠️ Critical Gap
- **Only 3 widget/unit tests** for 17 feature modules
- **Missing**: Tests for auth, leave_management, employee_portal, taxes, time_tracking, etc.

#### **Load Testing** ✅ Framework Ready
- k6 and Artillery scripts already set up
- **Recommendation**: Use **k6** as primary tool

---

## 🚀 Load Testing with k6

### Why k6?
- ✅ Modern, JavaScript-based scripting
- ✅ Better metrics and real-time monitoring
- ✅ Flexible thresholds and assertions
- ✅ Works seamlessly with Dockerized backends
- ✅ Excellent reporting (JSON, HTML, InfluxDB, Grafana)

---

## 🛠️ Setup Instructions

### 1. Install k6

```bash
# macOS
brew install k6

# Linux
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Windows (via Chocolatey)
choco install k6
```

### 2. Verify Docker Backend is Running

```bash
# Start Docker services
docker-compose up -d

# Verify backend is accessible
curl http://localhost:3000/api

# Check backend logs
docker-compose logs -f backend
```

### 3. Create Test User for Load Testing

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "loadtest@paykey.com",
    "password": "LoadTest123!",
    "firstName": "Load",
    "lastName": "Test",
    "businessName": "Load Testing Inc"
  }'
```

---

## 📊 Running Load Tests

### Option 1: Quick Smoke Test (Recommended First)

```bash
# Navigate to test directory
cd /Users/ron/Desktop/payKey/backend/test/load

# Run with minimal load (10 virtual users, 1 minute)
k6 run --vus 10 --duration 1m k6-performance-test.js
```

### Option 2: Standard Load Test

```bash
# Run the full test with ramping stages
k6 run k6-performance-test.js
```

**Expected Output:**
```
✓ login successful
✓ payroll calculation successful
✓ payroll calculation fast
✓ workers list successful
✓ workers list fast
✓ tax calculation successful
✓ tax calculation fast

...

checks.........................: 100.00% ✓ 1450 ✗ 0  
data_received..................: 2.5 MB  42 kB/s
data_sent......................: 1.2 MB  20 kB/s
http_req_duration..............: avg=145ms min=45ms med=120ms max=850ms p(95)=285ms p(99)=450ms
http_req_failed................: 0.00%   ✓ 0    ✗ 1450
iterations.....................: 1450    24/s
vus............................: 100     min=0  max=200
```

### Option 3: Custom Load Profile

```bash
# Override test stages via CLI
k6 run --stage 30s:50 --stage 1m:100 --stage 30s:0 k6-performance-test.js
```

### Option 4: Test Against Dockerized Backend

```bash
# Ensure BASE_URL points to Docker backend
k6 run \
  -e BASE_URL=http://localhost:3000 \
  -e TEST_EMAIL=loadtest@paykey.com \
  -e TEST_PASSWORD=LoadTest123! \
  k6-performance-test.js
```

---

## 🔧 Updated k6 Script (Docker-Ready)

The existing `k6-performance-test.js` needs minor updates to work with Docker and dynamic configuration:

### Recommended Improvements

1. **Environment Variables**: Use `__ENV` for dynamic configuration
2. **Docker Network**: Ensure script can reach `localhost:3000`
3. **Test Data Setup**: Create workers before testing
4. **Better Error Handling**: Improve failure messages

### Updated Script Location
`/Users/ron/Desktop/payKey/backend/test/load/k6-performance-test.js`

---

## 📈 Interpreting Results

### Key Metrics to Monitor

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| `http_req_duration` (p95) | < 500ms | < 1000ms |
| `http_req_failed` | < 1% | < 5% |
| Payroll Calculation | < 3000ms | < 5000ms |
| Worker List | < 1000ms | < 2000ms |
| Tax Calculation | < 2000ms | < 3000ms |

### Success Criteria
- ✅ **95% of requests** complete under 500ms
- ✅ **Error rate** below 1%
- ✅ **No 500 errors** during test
- ✅ Backend stays stable under 200 concurrent users

### Warning Signs
- ⚠️ p95 latency > 1000ms
- ⚠️ Error rate > 5%
- ⚠️ Database connection pool exhaustion
- ⚠️ Memory leaks in long-running tests

---

## 🐛 Troubleshooting

### Issue 1: Connection Refused
```bash
Error: connect ECONNREFUSED 127.0.0.1:3000
```
**Solution**: Ensure Docker backend is running
```bash
docker-compose up -d backend
docker-compose logs backend
```

### Issue 2: Authentication Failures
```bash
Error: login failed - cannot proceed with load test
```
**Solution**: Verify test user exists or create it
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"loadtest@paykey.com","password":"LoadTest123!","firstName":"Load","lastName":"Test"}'
```

### Issue 3: Database Timeouts
```bash
Error: QueryFailedError: timeout
```
**Solution**: Check database connection pool and indices
```bash
# View database logs
docker-compose logs db

# Check active connections
docker-compose exec db psql -U postgres -d paykey -c "SELECT count(*) FROM pg_stat_activity;"
```

### Issue 4: High Error Rates
**Possible Causes**:
- Database connection pool exhausted
- Missing indexes on frequently queried tables
- CPU/Memory limits on Docker container
- Network throttling

**Solution**: Check resource usage
```bash
# Monitor Docker container stats
docker stats paykey_backend

# Increase connection pool (backend .env)
DB_CONNECTION_POOL_SIZE=50
```

---

## 📊 Advanced Testing Scenarios

### Scenario 1: Payroll-Heavy Load
```bash
# Create custom test script focusing on payroll
k6 run --stage 1m:50 --stage 3m:50 --stage 1m:0 k6-payroll-stress-test.js
```

### Scenario 2: Spike Testing
```bash
# Sudden traffic spike
k6 run --stage 10s:0 --stage 30s:500 --stage 1m:0 k6-performance-test.js
```

### Scenario 3: Endurance Testing
```bash
# Long-running test (8 hours)
k6 run --stage 5m:50 --stage 8h:50 --stage 5m:0 k6-performance-test.js
```

### Scenario 4: Multi-Tenant Simulation
Create multiple test users and distribute load across them.

---

## 🎯 Next Steps

### Immediate Actions
1. ✅ **Run Smoke Test**: Verify baseline performance
2. ✅ **Fix Performance Test**: Properly seed 50 workers in `test/performance/performance.ts`
3. ⚠️ **Add Mobile Tests**: Create widget tests for critical flows

### Short-Term Goals
- Add unit tests for `TaxesService`, `AccountingService`
- Implement load testing in CI/CD pipeline
- Set up monitoring dashboard (Grafana + k6)

### Long-Term Goals
- Implement distributed load testing (cloud-based)
- Add chaos engineering (network failures, DB crashes)
- Performance benchmarking across releases

---

## 📚 Resources

- [k6 Documentation](https://k6.io/docs/)
- [k6 Examples](https://github.com/grafana/k6-examples)
- [Load Testing Best Practices](https://k6.io/docs/testing-guides/load-testing-best-practices/)
- [Docker Performance Tuning](https://docs.docker.com/config/containers/resource_constraints/)

---

## 🤝 Contributing

When adding new load tests:
1. Follow the existing k6 script structure
2. Use environment variables for configuration
3. Add proper error handling and checks
4. Document expected performance thresholds
5. Test against Docker-ized backend

---

**Last Updated**: December 11, 2025  
**Maintained By**: PayKey Engineering Team
