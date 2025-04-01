#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to check if Redis is running
check_redis() {
    print_header "Checking Redis Connection"
    if ! redis-cli ping > /dev/null 2>&1; then
        echo -e "${RED}❌ Redis is not running. Please start Redis first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Redis is running${NC}"
}

# Activate the virtual environment
print_header "Activating Python Environment"
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo -e "${GREEN}✅ Virtual environment activated${NC}"
else
    echo -e "${RED}❌ Virtual environment not found. Please run the setup script first: cd .. && ./setup.sh${NC}"
    exit 1
fi

# Function to check required dependencies
check_dependencies() {
    print_header "Checking Required Dependencies"
    
    # Check Python dependencies
    for pkg in boto3 redis google.cloud playwright browserstate; do
        if ! python -c "import $pkg" &> /dev/null; then
            echo -e "${RED}❌ Python package '$pkg' is not installed.${NC}"
            echo -e "${RED}Please run the setup script first: cd .. && ./setup.sh${NC}"
            exit 1
        fi
    done
    
    # Check TypeScript dependencies using package.json
    if [ ! -f "node_modules/playwright/package.json" ] || [ ! -f "node_modules/ts-node/package.json" ]; then
        echo -e "${RED}❌ TypeScript dependencies are not installed.${NC}"
        echo -e "${RED}Please run the setup script first: cd .. && ./setup.sh${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All dependencies installed${NC}"
}

# Main execution
echo -e "${BLUE}🚀 Starting Python -> Redis -> TypeScript Interop Test${NC}"

# Check prerequisites
check_redis
check_dependencies

# Run Python test
print_header "Running Python Test"
if ! python3 test_cross_language.py; then
    echo -e "${RED}❌ Python test failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python test completed successfully${NC}"

# Run TypeScript verification
print_header "Running TypeScript Verification"
if ! node --loader ts-node/esm verify_state.ts; then
    echo -e "${RED}❌ TypeScript verification failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ TypeScript verification completed successfully${NC}"

echo -e "\n${GREEN}✨ All tests completed successfully!${NC}" 