# E2E Test Setup Guide

## Overview

This document outlines the end-to-end (E2E) testing setup for the PayKey backend application. The E2E tests verify the complete application workflow including authentication, payroll processing, tax calculations, and employee portal functionality.

## 📋 Test Coverage

The E2E test suite includes:
- **Authentication & Authorization** (`auth.e2e-spec.ts`)
- **Employee Portal** (`employee-portal.e2e-spec.ts`)
- **Payroll Management** (`payroll.e2e-spec.ts`, `payroll-batch-flow.e2e-spec.ts`)
- **Tax Calculations** (`taxes.e2e-spec.ts`)
- **User Profile Management** (`user-profile.e2e-spec.ts`)
- **Feature Access Control** (`feature-access.e2e-spec.ts`)
- **Reports & Analytics** (`reports.e2e-spec.ts`)
- **Subscription Management** (`subscriptions.e2e-spec.ts`)

**Current Status**: 122 tests, 100% passing rate

## 🛠️ Requirements

### System Requirements
- **Node.js**: Version 16 or higher
- **PostgreSQL**: Version 13 or higher
- **npm**: Latest version
- **Operating System**: macOS, Linux, or Windows

### Database Requirements
- **Database Name**: `paykey_test` (or configurable)
- **Database User**: PostgreSQL user with full access
- **Database Permissions**: CREATE, DROP, INSERT, UPDATE, DELETE, SELECT

### Environment Variables
```bash
# Required for test execution
DB_HOST=localhost
DB_PORT=5435
DB_USERNAME=postgres
DB_PASSWORD=admin
DB_DATABASE=paykey_test
NODE_ENV=test
```

## 🚀 Quick Start

### 1. Setup Database
```bash
# Create test database
createdb paykey_test

# Or using psql
psql -U postgres -c "CREATE DATABASE paykey_test;"
```

### 2. Install Dependencies
```bash
cd backend
npm install
```

### 3. Configure Environment
```bash
# Set test environment variables
export DB_HOST=localhost
export DB_PORT=5435
export DB_USERNAME=postgres
export DB_PASSWORD=your_password
export DB_DATABASE=paykey_test
export NODE_ENV=test
```

### 4. Run Tests
```bash
# Run all E2E tests
npm run test:e2e

# Run specific test file
npm run test:e2e -- --testPathPattern=employee-portal

# Run tests with coverage
npm run test:cov

# Run tests in watch mode (development)
npm run test:watch
```

## 📁 Test Structure

### Directory Layout
```
backend/test/
├── test-utils.ts          # Shared test utilities
├── test-setup.ts          # Global test configuration
├── jest-e2e.json         # Jest configuration
├── test-database.module   # Test database module
├── *.e2e-spec.ts         # Individual test files
└── integration/           # Integration test files
```

### Key Files

#### `test-utils.ts`
Provides utilities for test data generation:
- `generateTestEmail(testName)`: Creates unique test emails
- `generateTestPhone()`: Generates unique phone numbers
- `createTestUserData(overrides)`: Factory for test user objects
- `createTestWorkerData(overrides)`: Factory for test worker objects
- `cleanupTestData(dataSource)`: Cleans test data between runs

#### `test-setup.ts`
Global test configuration:
- Sets up test environment variables
- Configures before/after hooks
- Provides custom Jest matchers
- Handles test lifecycle management

#### `jest-e2e.json`
Jest configuration for E2E tests:
- Test environment setup
- Transform configurations
- Timeout settings
- Test isolation parameters

## 🔧 Configuration Details

### Database Configuration
Tests use a separate test database to ensure isolation:
```typescript
// test-database.module.ts
TypeOrmModule.forRootAsync({
  useFactory: async (configService: ConfigService) => ({
    type: 'postgres',
    host: configService.get<string>('DB_HOST', 'localhost'),
    port: parseInt(configService.get<string>('DB_PORT', '5432')),
    database: configService.get<string>('DB_DATABASE', 'paykey_test'),
    synchronize: true,        // Auto-create schema
    dropSchema: true,         // Clean slate for each run
    logging: false,           // Disable query logging
  })
})
```

### Test Data Isolation
Each test generates unique data to prevent conflicts:
```typescript
// Example from employee-portal.e2e-spec.ts
const userData = createTestUserData({
    firstName: 'Employer',
    lastName: 'Portal',
    businessName: 'Portal Test Corp'
});

const workerData = createTestWorkerData({
    name: 'Portal Worker'
});
```

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | localhost | Database host address |
| `DB_PORT` | 5432 | Database port number |
| `DB_USERNAME` | postgres | Database username |
| `DB_PASSWORD` | admin | Database password |
| `DB_DATABASE` | paykey_test | Test database name |
| `NODE_ENV` | test | Node environment |

## 📝 Writing New Tests

### Test File Template
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { 
    createTestUserData, 
    createTestWorkerData 
} from './test-utils';

describe('New Feature E2E', () => {
    let app: INestApplication;
    let authToken: string;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        // Create test user
        const userData = createTestUserData({
            firstName: 'Test',
            lastName: 'User',
            businessName: 'Test Company'
        });

        await request(app.getHttpServer())
            .post('/auth/register')
            .send({
                email: userData.email,
                password: userData.password,
                firstName: userData.firstName,
                lastName: userData.lastName,
                businessName: userData.businessName,
                phone: userData.phone
            });

        const loginRes = await request(app.getHttpServer())
            .post('/auth/login')
            .send({ email: userData.email, password: userData.password });

        authToken = loginRes.body.access_token;
    });

    afterAll(async () => {
        if (app) {
            await app.close();
        }
    });

    describe('Feature Tests', () => {
        it('should test the feature', async () => {
            const res = await request(app.getHttpServer())
                .post('/api/endpoint')
                .set('Authorization', `Bearer ${authToken}`)
                .send({ /* test data */ })
                .expect(201);

            expect(res.body).toHaveProperty('expectedProperty');
        });
    });
});
```

### Best Practices

1. **Use Test Utilities**: Always use `createTestUserData()` and `createTestWorkerData()`
2. **Unique Test Data**: Each test should generate unique identifiers
3. **Proper Cleanup**: Clean up in `afterAll()` hooks
4. **Descriptive Tests**: Use clear, descriptive test names
5. **Error Handling**: Test both success and failure scenarios
6. **Status Codes**: Verify appropriate HTTP status codes

## 🔍 Troubleshooting

### Common Issues

#### 1. Database Connection Errors
```bash
Error: connect ECONNREFUSED 127.0.0.1:5435
```
**Solution**: Ensure PostgreSQL is running and accessible on the specified port.

#### 2. Database Does Not Exist
```bash
Error: database "paykey_test" does not exist
```
**Solution**: Create the test database:
```bash
createdb paykey_test
```

#### 3. Permission Denied
```bash
Error: password authentication failed for user "postgres"
```
**Solution**: Verify database credentials and permissions.

#### 4. Port Already in Use
```bash
Error: listen EADDRINUSE: address already in use :::5435
```
**Solution**: Change the DB_PORT or stop the conflicting service.

#### 5. Test Timeout
```bash
Timeout - Async callback was not invoked within the 30000 ms timeout
```
**Solution**: Increase timeout in `jest-e2e.json` or optimize test performance.

### Debug Mode
```bash
# Run tests with debug output
npm run test:e2e -- --verbose --detectOpenHandles

# Run specific test with full output
npm run test:e2e -- --testPathPattern=employee-portal --verbose
```

### Performance Issues
- Run tests sequentially (`maxWorkers: 1` in config)
- Monitor database connection pool
- Check for memory leaks in long-running tests
- Use test timeouts appropriately

## 📊 Test Results

### Current Test Status
```
Test Suites: 15 passed, 15 total
Tests:       122 passed, 122 total
Snapshots:   0 total
Time:        17.96 s
```

### Test Categories
- **Authentication**: 8 tests
- **Employee Portal**: 6 tests
- **Payroll Processing**: 15 tests
- **Tax Calculations**: 9 tests
- **User Management**: 5 tests
- **Reports**: 4 tests
- **API Integration**: 75+ tests

## 🚀 Continuous Integration

### GitHub Actions Example
```yaml
name: E2E Tests
on: [push, pull_request]
jobs:
  test-e2e:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: paykey_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '16'
      - run: npm ci
        working-directory: ./backend
      - run: npm run test:e2e
        working-directory: ./backend
        env:
          DB_HOST: localhost
          DB_PORT: 5432
          DB_USERNAME: postgres
          DB_PASSWORD: postgres
          DB_DATABASE: paykey_test
```

## 📚 Additional Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [NestJS Testing Guide](https://docs.nestjs.com/fundamentals/testing)
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [PostgreSQL Testing Best Practices](https://thoughtbot.com/blog/testing-postgres)

## 🤝 Contributing

When adding new E2E tests:

1. Follow the established patterns in existing test files
2. Use the test utilities provided in `test-utils.ts`
3. Ensure tests are independent and can run in any order
4. Add appropriate cleanup in `afterAll()` hooks
5. Update this documentation if adding new test categories

For questions or issues, please refer to the troubleshooting section or create an issue in the project repository.