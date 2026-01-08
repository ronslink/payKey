# scripts/run_tests_docker.ps1

Write-Host "🐳 Starting Local Docker E2E Tests..." -ForegroundColor Cyan

# 1. Cleanup old containers
Write-Host "🧹 Cleaning up old test containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down -v --remove-orphans

# 2. Build and run tests
Write-Host "🚀 Starting test environment and running tests..." -ForegroundColor Green
# We use --abort-on-container-exit so that when backend_test finishes (pass or fail), 
# everything shuts down. --exit-code-from backend_test makes the command return the test's exit code.
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit --exit-code-from backend_test

$testResult = $LASTEXITCODE

# 3. Cleanup
Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down -v

if ($testResult -eq 0) {
    Write-Host "✅ Tests Passed!" -ForegroundColor Green
} else {
    Write-Host "❌ Tests Failed!" -ForegroundColor Red
}

exit $testResult
