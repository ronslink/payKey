# Load Testing

This directory contains load testing scripts for the PayKey backend API.

## 🚀 Quick Start

### Prerequisites
1. **Docker** - Backend runs in Docker
2. **k6** - Load testing tool

Install k6:
```bash
# macOS
brew install k6

# Linux (Debian/Ubuntu)
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | \
  sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Windows
choco install k6
```

### Running Load Tests

#### Option 1: Automated Script (Recommended)
```bash
cd backend/test/load
./run-load-test.sh
```

The script will:
- ✅ Check if Docker is running
- ✅ Verify backend accessibility
- ✅ Create test user if needed
- ✅ Run your chosen test type

#### Option 2: Manual Execution

1. **Start Docker Backend**
   ```bash
   docker-compose up -d
   ```

2. **Create Test User**
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

3. **Run Load Test**
   ```bash
   # Smoke test (quick validation)
   k6 run --vus 10 --duration 1m k6-performance-test.js

   # Full load test
   k6 run k6-performance-test.js

   # Custom parameters
   k6 run --vus 50 --duration 5m k6-performance-test.js
   ```

## 📊 Files in This Directory

### `k6-performance-test.js` ✅ **Single-User Load Test**
Modern JavaScript-based load test using k6.

**Features**:
- Environment variable configuration
- Custom metrics tracking
- Comprehensive error handling
- Tests critical endpoints:
  - Worker list (GET)
  - Tax calculation (POST)
  - Pay periods list (GET)

**Use Case**: Basic API performance testing, single tenant

**Configuration**:
```bash
k6 run \
  -e BASE_URL=http://localhost:3000 \
  -e TEST_EMAIL=loadtest@paykey.com \
  -e TEST_PASSWORD=LoadTest123! \
  k6-performance-test.js
```

### `k6-multi-user-test.js` 🆕 **Multi-Tenant Load Test**
Tests multiple employers (tenants) using PayKey concurrently.

**Features**:
- Creates N distinct employer accounts
- Each virtual user represents a different employer
- Tests data isolation and multi-tenant architecture
- Simulates realistic concurrent usage

**Use Case**: Multi-tenant testing, database isolation verification

**Configuration**:
```bash
# Test with 10 employers (default)
k6 run k6-multi-user-test.js

# Test with 20 employers
k6 run -e NUM_USERS=20 k6-multi-user-test.js
```

### `k6-realistic-scenarios.js` 🆕 **Business Scenario Testing**
Advanced scenario-based testing with multiple concurrent workflows.

**Features**:
- **Scenario 1**: Monthly payroll rush (20 employers processing simultaneously)
- **Scenario 2**: Continuous worker management (background operations)
- **Scenario 3**: Tax filing deadline spike (quarterly deadline simulation)
- Tests resource contention and real-world peak usage

**Use Case**: End-of-month testing, realistic business workflows

**Configuration**:
```bash
k6 run k6-realistic-scenarios.js
```


### `artillery-payroll-load-test.yml`
YAML-based load test using Artillery.

**Usage**:
```bash
npx artillery run artillery-payroll-load-test.yml
```

### `run-load-test.sh`
Automated setup and execution script.

**Features**:
- Validates Docker setup
- Creates test user
- Interactive test selection
- Smoke/Standard/Custom test options

## 📈 Understanding Results

### Key Metrics

| Metric | Target | Critical |
|--------|--------|----------|
| `http_req_duration` (p95) | < 500ms | < 1000ms |
| `http_req_failed` | < 1% | < 5% |
| `payroll_duration` (p95) | < 3000ms | < 5000ms |
| `workers_duration` (p95) | < 1000ms | < 2000ms |
| `tax_duration` (p95) | < 2000ms | < 3000ms |

### Sample Output
```
✓ login successful
✓ workers list successful
✓ workers list has data
✓ workers list fast
✓ tax calculation successful
✓ tax calculation has result
✓ tax calculation fast
✓ pay periods list successful
✓ pay periods list fast

checks.........................: 100.00% ✓ 1450 ✗ 0
data_received..................: 2.5 MB  42 kB/s
data_sent......................: 1.2 MB  20 kB/s
http_req_duration..............: avg=145ms min=45ms med=120ms max=850ms p(95)=285ms
http_req_failed................: 0.00%   ✓ 0    ✗ 1450
iterations.....................: 1450    24/s
payroll_duration...............: avg=1850ms p(95)=2450ms
workers_duration...............: avg=125ms p(95)=245ms
tax_duration...................: avg=450ms p(95)=850ms
```

## 🔧 Test Scenarios

### 1. Smoke Test
Quick validation that everything works.
```bash
k6 run --vus 10 --duration 1m k6-performance-test.js
```
- **Duration**: 1 minute
- **Users**: 10 concurrent
- **Purpose**: Quick validation

### 2. Standard Load Test
Gradual ramp-up to production load.
```bash
k6 run k6-performance-test.js
```
- **Duration**: 16 minutes
- **Users**: 0 → 100 → 200 → 0
- **Purpose**: Performance baseline

### 3. Stress Test
Push beyond normal capacity.
```bash
k6 run --stage 2m:500 --stage 5m:500 --stage 2m:0 k6-performance-test.js
```
- **Duration**: 9 minutes
- **Users**: 500 concurrent
- **Purpose**: Find breaking point

### 4. Spike Test
Sudden traffic surge.
```bash
k6 run --stage 10s:0 --stage 30s:500 --stage 1m:0 k6-performance-test.js
```
- **Duration**: 2 minutes
- **Pattern**: 0 → 500 instantly
- **Purpose**: Test recovery

## 🐛 Troubleshooting

### Backend Not Accessible
```
❌ Login failed with status: ECONNREFUSED
```
**Solution**:
```bash
docker-compose up -d
docker-compose logs backend
```

### Authentication Failures
```
❌ Login failed with status: 401
```
**Solution**: Recreate test user
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"loadtest@paykey.com","password":"LoadTest123!","firstName":"Load","lastName":"Test","businessName":"Load Test Inc"}'
```

### High Error Rates
**Check**:
1. Database connection pool
2. Docker container resources
3. Network throttling

**Monitor**:
```bash
# Container stats
docker stats paykey_backend

# Backend logs
docker-compose logs -f backend

# Database connections
docker-compose exec db psql -U postgres -d paykey \
  -c "SELECT count(*) FROM pg_stat_activity;"
```

## 📚 Resources

- [k6 Documentation](https://k6.io/docs/)
- [Load Testing Best Practices](https://k6.io/docs/testing-guides/load-testing-best-practices/)
- [PayKey Load Testing Guide](../../docs/LOAD_TESTING_GUIDE.md)
- [Test Coverage Analysis](../../docs/TEST_COVERAGE_ANALYSIS.md)

## 🤝 Contributing

When adding new load tests:
1. Use environment variables for configuration
2. Add proper error handling and checks
3. Document expected thresholds
4. Test against Docker backend first
5. Update this README

---

**Last Updated**: December 11, 2025
