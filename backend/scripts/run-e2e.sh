#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Starting E2E Test Suite Automation...${NC}"

# 1. Check Prerequisites
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: docker could not be found.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: docker-compose could not be found.${NC}"
    exit 1
fi

# Ensure we are in the project root (assuming script is in backend/scripts/run-e2e.sh)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_ROOT"

echo -e "${YELLOW}📂 Working Directory: $(pwd)${NC}"

# 2. Start Test Environment
echo -e "${YELLOW}📦 Spinning up Test Database & Redis...${NC}"
docker-compose -f docker-compose.test.yml up -d db_test redis_test

# 3. Wait for Database Readiness
echo -e "${YELLOW}⏳ Waiting for Database to be ready...${NC}"
MAX_RETRIES=30
COUNT=0
until docker exec paykey_db_test pg_isready -U paykey -d paykey_test > /dev/null 2>&1; do
    echo -n "."
    sleep 1
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo -e "\n${RED}❌ Timeout waiting for Database.${NC}"
        docker-compose -f docker-compose.test.yml logs db_test
        exit 1
    fi
done
echo -e "\n${GREEN}✅ Database is up and running!${NC}"

# 4. Run Tests
echo -e "${YELLOW}🧪 Running E2E Tests...${NC}"
# Use cross-env explicitly if needed, but jest-e2e.json handles environment mostly.
# We pass --detectOpenHandles to catch lingering connections.
# WE MUST POINT TO THE EXPOSED PORTS (5433, 6380) since we are running on Host
cd backend
export DB_PORT=5433
export REDIS_PORT=6380
export DB_USER=postgres
export DB_USERNAME=postgres
export DB_NAME=paykey_test
export DB_PASSWORD=Tina76
export CI=true
if npm run test:e2e -- --detectOpenHandles; then
    echo -e "${GREEN}✅ All Tests Passed!${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}❌ Tests Failed.${NC}"
    EXIT_CODE=1
fi
cd ..

# 5. Cleanup
echo -e "${YELLOW}🧹 Cleaning up Test Environment...${NC}"
docker-compose -f docker-compose.test.yml down -v

exit $EXIT_CODE
