# Testing Framework Implementation Guide - Step by Step

## Current Status ✅
- [x] Comprehensive test files created (unit, integration, security, compliance, performance, E2E)
- [x] Test scripts added to package.json
- [x] Load testing configurations created (Artillery, K6)
- [x] CI/CD pipeline configuration ready
- [x] Coverage threshold enforcement script
- [x] Test data seeding script

## Step 1: Fix TypeScript Configuration

### Fix tsconfig.json error
Edit `backend/tsconfig.json` and remove the line:
```json
"ignoreDeprecations": "7.0"
```

## Step 2: Test Environment Setup

### Install Missing Dependencies
Run these commands in the backend directory:

```bash
# Install missing testing dependencies
npm install --save-dev jest-cli @types/jest

# Install load testing tools
npm install --save-dev artillery @artillery/cli

# Install additional test utilities
npm install --save-dev nock @faker-js/faker
```

### Update package.json with missing scripts
Replace the "seed:test-data" script with:
```json
"seed:test-data": "ts-node src/seed-test-data.ts"
```

## Step 3: Fix Enum Type Issues

The current error is due to enum mismatches. Fix these in the test files by using the correct enum values from the entities. Check the Worker entity for the correct enum values.

## Step 4: Run Tests (After Fixes)

### Unit Tests
```bash
cd backend
npm run test:unit
```

### Integration Tests  
```bash
npm run test:integration
```

### E2E Tests
```bash
npm run test:e2e
```

### Security Tests
```bash
npm run test:security
```

### Compliance Tests
```bash
npm run test:compliance
```

### Performance Tests
```bash
npm run test:performance
```

## Step 5: Set Up GitHub Repository Secrets

### Required GitHub Secrets
Set these in your GitHub repository settings > Secrets and variables > Actions:

```
SNYK_TOKEN=your_snyk_token_here
SONAR_TOKEN=your_sonarqube_token_here
DOCKER_USERNAME=your_dockerhub_username
DOCKER_PASSWORD=your_dockerhub_password
CODECOV_TOKEN=your_codecov_token_here
```

## Step 6: External Service Setup

### SonarQube Setup
1. Create account at sonarqube.cloud
2. Create new project for PayKey
3. Generate project token
4. Add token to GitHub secrets

### Codecov Setup  
1. Create account at codecov.io
2. Connect your GitHub repository
3. Generate upload token
4. Add token to GitHub secrets

### Snyk Security
1. Create account at snyk.io
2. Connect your GitHub repository
3. Generate API token
4. Add token to GitHub secrets

## Step 7: Mobile Testing Setup (Flutter)

### Add Flutter Testing Dependencies
Edit `mobile/pubspec.yaml` and add to dev_dependencies:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.5.4
  json_serializable: ^6.7.1
  freezed: ^2.4.6
  mockito: ^5.4.6
  integration_test:
    sdk: flutter
  golden_toolkit: ^0.15.0
```

### Create Flutter Test Files
Create these test files in the mobile directory:

```bash
# Unit tests
mobile/test/unit/
mobile/test/unit/repositories/
mobile/test/unit/providers/
mobile/test/unit/models/

# Integration tests  
mobile/integration_test/

# Widget tests
mobile/test/widget/
```

### Example Flutter Test File
Create `mobile/test/unit/repositories/payroll_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

@GenerateMocks([Dio])
import 'payroll_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late PayrollRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = PayrollRepository(mockDio);
  });

  test('fetchPayPeriods returns list of pay periods', () async {
    when(mockDio.get('/pay-periods')).thenAnswer(
      (_) async => Response(
        data: [
          {'id': '1', 'startDate': '2024-01-01', 'status': 'COMPLETED'},
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/pay-periods'),
      ),
    );

    final periods = await repository.fetchPayPeriods();
    expect(periods, hasLength(1));
    expect(periods[0].status, PayPeriodStatus.COMPLETED);
  });
}
```

## Step 8: Performance Testing Setup

### Install Load Testing Tools
```bash
# Global install for load testing
npm install -g artillery k6

# Or use Docker for k6
docker pull loadimpact/k6
```

### Run Load Tests
```bash
# Artillery load test
artillery run test/load/artillery-payroll-load-test.yml

# K6 load test (requires local server running)
k6 run test/load/k6-performance-test.js
```

## Step 9: CI/CD Pipeline Activation

### Push to GitHub
Commit all files to your GitHub repository:

```bash
git add .
git commit -m "Add comprehensive testing framework"
git push origin main
```

### Check GitHub Actions
1. Go to your repository on GitHub
2. Click on "Actions" tab
3. Verify the workflow runs automatically
4. Check all test jobs pass

## Step 10: Monitor Coverage Reports

### Coverage Dashboards
- **Codecov**: https://codecov.io/gh/your-username/your-repo
- **SonarQube**: https://sonarcloud.io/dashboard?id=your-project-id

### Coverage Requirements
- **Overall**: 80% minimum
- **Critical modules** (Payroll, Taxes): 95% minimum  
- **Security modules**: 90% minimum

## Step 11: Continuous Monitoring

### Set Up Alerts
1. **Coverage Regression**: Set up alerts if coverage drops
2. **Performance Degradation**: Monitor load test results
3. **Security Vulnerabilities**: Weekly Snyk reports
4. **Test Failures**: Real-time notifications on PRs

### Regular Maintenance
- **Weekly**: Run full test suite locally
- **Monthly**: Review and update test coverage thresholds
- **Quarterly**: Audit test effectiveness and add missing tests

## Step 12: Production Readiness

### Staging Environment
Deploy to staging and run performance tests:
```bash
# Deploy to staging (replace with your actual deployment)
npm run deploy:staging

# Run performance tests against staging
artillery run test/load/artillery-payroll-load-test.yml --target https://staging.paykey.com
```

### Production Deployment
Only deploy after:
- [ ] All tests pass
- [ ] Coverage thresholds met
- [ ] Performance tests pass
- [ ] Security scan clean
- [ ] Compliance tests pass

## Troubleshooting Guide

### Common Issues

#### TypeScript Enum Errors
```bash
# Check enum definitions in entities
grep -r "enum" src/modules/*/entities/
```

#### Database Connection Issues
```bash
# Check test database is running
docker-compose up -d postgres
```

#### Missing Dependencies
```bash
# Reinstall all dependencies
rm -rf node_modules package-lock.json
npm install
```

#### Test Timeouts
Increase timeout in jest config for integration tests:
```javascript
testTimeout: 30000
```

## Success Metrics

### Test Execution
- [ ] All test suites pass locally
- [ ] CI/CD pipeline passes completely
- [ ] Coverage reports generated automatically
- [ ] Performance benchmarks met

### Code Quality
- [ ] No critical security vulnerabilities
- [ ] Code complexity maintained
- [ ] Technical debt under 5%
- [ ] Documentation current

### Business Impact
- [ ] Zero production tax calculation errors
- [ ] Faster development cycle (2x improvement)
- [ ] Higher confidence in deployments
- [ ] Reduced bug fix time (50% reduction)

## Next Steps After Implementation

1. **Set up monitoring dashboards**
2. **Implement test-driven development for new features**
3. **Add visual regression testing for mobile**
4. **Implement contract testing for APIs**
5. **Set up chaos testing for resilience**

## Timeline

- **Day 1**: Fix TypeScript issues and run basic tests
- **Day 2**: Set up external services (SonarQube, Codecov, Snyk)
- **Day 3**: Implement mobile testing and load testing
- **Day 4**: Configure CI/CD and deploy to staging
- **Day 5**: Performance testing and production readiness check

## Emergency Contacts

If you encounter issues:
1. Check the troubleshooting guide above
2. Review test logs in GitHub Actions
3. Verify external service configurations
4. Contact the development team for support

---

This comprehensive testing framework will provide enterprise-grade quality assurance, prevent costly errors, and enable confident feature development and deployments.