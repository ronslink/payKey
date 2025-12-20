#!/bin/bash

# PayKey Load Testing Setup Script
# This script sets up and runs load tests against the Dockerized backend

set -e  # Exit on any error

echo "🚀 PayKey Load Testing Setup"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="http://localhost:3000"
TEST_EMAIL="loadtest@paykey.com"
TEST_PASSWORD="LoadTest123!"
TEST_FIRST_NAME="Load"
TEST_LAST_NAME="Test"
TEST_BUSINESS="Load Testing Inc"

# Step 1: Check if Docker is running
echo "📦 Step 1: Checking Docker services..."
if ! docker-compose ps | grep -q "paykey_backend.*Up"; then
    echo -e "${YELLOW}⚠️  Backend not running. Starting Docker services...${NC}"
    docker-compose up -d
    echo -e "${GREEN}✅ Docker services started${NC}"
    echo "⏳ Waiting 10 seconds for backend to be ready..."
    sleep 10
else
    echo -e "${GREEN}✅ Backend already running${NC}"
fi

# Step 2: Check if backend is accessible
echo ""
echo "🔍 Step 2: Verifying backend accessibility..."
if curl -s -f "${BASE_URL}/api" > /dev/null; then
    echo -e "${GREEN}✅ Backend is accessible at ${BASE_URL}${NC}"
else
    echo -e "${RED}❌ Backend not accessible at ${BASE_URL}${NC}"
    echo "Please check Docker logs: docker-compose logs backend"
    exit 1
fi

# Step 3: Check if k6 is installed
echo ""
echo "🔧 Step 3: Checking k6 installation..."
if command -v k6 &> /dev/null; then
    echo -e "${GREEN}✅ k6 is installed ($(k6 version))${NC}"
else
    echo -e "${RED}❌ k6 is not installed${NC}"
    echo ""
    echo "Please install k6:"
    echo "  macOS:   brew install k6"
    echo "  Linux:   See https://k6.io/docs/getting-started/installation/"
    echo "  Windows: choco install k6"
    exit 1
fi

# Step 4: Create or verify test user
echo ""
echo "👤 Step 4: Setting up test user..."

# Try to login first (user might already exist)
LOGIN_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/login_response.json \
    -X POST "${BASE_URL}/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${TEST_EMAIL}\",\"password\":\"${TEST_PASSWORD}\"}")

if [ "$LOGIN_RESPONSE" = "200" ] || [ "$LOGIN_RESPONSE" = "201" ]; then
    echo -e "${GREEN}✅ Test user already exists and can login${NC}"
else
    echo -e "${YELLOW}⚠️  Test user doesn't exist or can't login. Creating...${NC}"
    
    REGISTER_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/register_response.json \
        -X POST "${BASE_URL}/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\":\"${TEST_EMAIL}\",
            \"password\":\"${TEST_PASSWORD}\",
            \"firstName\":\"${TEST_FIRST_NAME}\",
            \"lastName\":\"${TEST_LAST_NAME}\",
            \"businessName\":\"${TEST_BUSINESS}\"
        }")
    
    if [ "$REGISTER_RESPONSE" = "200" ] || [ "$REGISTER_RESPONSE" = "201" ]; then
        echo -e "${GREEN}✅ Test user created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Registration returned status: ${REGISTER_RESPONSE}${NC}"
        echo "Response: $(cat /tmp/register_response.json)"
        echo "User might already exist. Continuing..."
    fi
fi

# Step 5: Run load test
echo ""
echo "🎯 Step 5: Running load test..."
echo ""
echo -e "${YELLOW}Choose test type:${NC}"
echo "  1) Smoke test (10 users, 1 minute) - Quick validation"
echo "  2) Standard test (Full ramp up) - ~16 minutes"
echo "  3) Custom test (Specify parameters)"
echo ""
read -p "Enter choice (1-3): " choice

cd "$(dirname "$0")"

case $choice in
    1)
        echo ""
        echo "Running smoke test..."
        k6 run --vus 10 --duration 1m \
            -e BASE_URL="${BASE_URL}" \
            -e TEST_EMAIL="${TEST_EMAIL}" \
            -e TEST_PASSWORD="${TEST_PASSWORD}" \
            k6-performance-test.js
        ;;
    2)
        echo ""
        echo "Running standard load test..."
        k6 run \
            -e BASE_URL="${BASE_URL}" \
            -e TEST_EMAIL="${TEST_EMAIL}" \
            -e TEST_PASSWORD="${TEST_PASSWORD}" \
            k6-performance-test.js
        ;;
    3)
        echo ""
        read -p "Enter number of virtual users: " vus
        read -p "Enter duration (e.g., 30s, 2m, 1h): " duration
        k6 run --vus ${vus} --duration ${duration} \
            -e BASE_URL="${BASE_URL}" \
            -e TEST_EMAIL="${TEST_EMAIL}" \
            -e TEST_PASSWORD="${TEST_PASSWORD}" \
            k6-performance-test.js
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Load test completed!${NC}"
echo ""
echo "📊 Review the metrics above for:"
echo "  - http_req_duration (p95) - Should be < 500ms"
echo "  - http_req_failed - Should be < 1%"
echo "  - Custom metrics: payroll_duration, workers_duration, tax_duration"
echo ""
echo "💡 Tips:"
echo "  - Monitor Docker stats: docker stats paykey_backend"
echo "  - View backend logs: docker-compose logs -f backend"
echo "  - Check database: docker-compose exec db psql -U postgres -d paykey"
