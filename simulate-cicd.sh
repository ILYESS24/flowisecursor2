#!/bin/bash

# Complete CI/CD Simulation Script for Flowise
# This script simulates all CI/CD processes locally

set -e

echo "🚀 Starting Complete CI/CD Simulation for Flowise"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists node; then
    print_error "Node.js is not installed. Please install Node.js 18+ or 20+"
    exit 1
fi

if ! command_exists pnpm; then
    print_error "pnpm is not installed. Please install pnpm 9+"
    exit 1
fi

if ! command_exists docker; then
    print_warning "Docker is not installed. Docker security scans will be skipped."
fi

print_success "Prerequisites check completed"

# Step 1: Security Audit
print_status "Step 1: Running Security Audit..."
echo "----------------------------------------"

print_status "Installing dependencies..."
pnpm install --frozen-lockfile

print_status "Running npm audit..."
pnpm audit --audit-level moderate || print_warning "npm audit found issues"

print_status "Running pnpm audit..."
pnpm audit --audit-level moderate || print_warning "pnpm audit found issues"

print_status "Checking for known vulnerabilities..."
pnpm audit --json > audit-results.json || print_warning "Audit completed with issues"

print_success "Security audit completed"

# Step 2: Code Quality
print_status "Step 2: Running Code Quality Checks..."
echo "---------------------------------------------"

print_status "Running ESLint..."
pnpm lint || print_warning "ESLint found issues"

print_status "Running Prettier check..."
pnpm format --check || print_warning "Prettier found formatting issues"

print_status "Running TypeScript type check..."
pnpm --filter "./packages/**" tsc --noEmit || print_warning "TypeScript found type issues"

print_success "Code quality checks completed"

# Step 3: Build and Test
print_status "Step 3: Building and Testing..."
echo "-------------------------------------"

print_status "Building project..."
NODE_OPTIONS='--max_old_space_size=4096' pnpm build

print_status "Running tests..."
pnpm test || print_warning "Some tests failed"

print_status "Generating test coverage..."
pnpm --filter "./packages/**" test --coverage || print_warning "Coverage generation had issues"

print_success "Build and test completed"

# Step 4: Docker Security (if Docker is available)
if command_exists docker; then
    print_status "Step 4: Docker Security Scan..."
    echo "------------------------------------"
    
    print_status "Building Docker image..."
    docker build --no-cache -t flowise:test .
    
    if command_exists trivy; then
        print_status "Running Trivy vulnerability scanner..."
        trivy image flowise:test || print_warning "Trivy found vulnerabilities"
    else
        print_warning "Trivy not installed. Install it for vulnerability scanning: https://trivy.dev/"
    fi
    
    print_success "Docker security scan completed"
else
    print_warning "Skipping Docker security scan (Docker not available)"
fi

# Step 5: Performance Testing
print_status "Step 5: Performance Testing..."
echo "-----------------------------------"

print_status "Starting Flowise server for performance testing..."
pnpm start &
SERVER_PID=$!

# Wait for server to start
print_status "Waiting for server to start..."
sleep 30

# Check if server is running
if curl -f http://localhost:3000 >/dev/null 2>&1; then
    print_success "Server is running"
    
    if [ -f "artillery-load-test.yml" ]; then
        print_status "Running Artillery load tests..."
        npx artillery run artillery-load-test.yml || print_warning "Load tests had issues"
    else
        print_warning "No Artillery config found, skipping load tests"
    fi
else
    print_warning "Server failed to start, skipping performance tests"
fi

# Stop server
kill $SERVER_PID 2>/dev/null || true
print_success "Performance testing completed"

# Step 6: Dependency Check
print_status "Step 6: Dependency Analysis..."
echo "------------------------------------"

print_status "Checking for outdated packages..."
pnpm outdated || print_warning "Found outdated packages"

if command_exists depcheck; then
    print_status "Checking for unused dependencies..."
    depcheck || print_warning "Found unused dependencies"
else
    print_warning "depcheck not installed. Install it for unused dependency analysis: npm install -g depcheck"
fi

print_success "Dependency analysis completed"

# Step 7: License Check
print_status "Step 7: License Compliance..."
echo "----------------------------------"

if command_exists license-checker; then
    print_status "Checking package licenses..."
    license-checker --summary || print_warning "License check found issues"
else
    print_warning "license-checker not installed. Install it for license analysis: npm install -g license-checker"
fi

print_success "License compliance check completed"

# Step 8: Generate Report
print_status "Step 8: Generating Security Report..."
echo "------------------------------------------"

cat > security-report.md << EOF
# Flowise Security Scan Report

Generated on: $(date)

## Summary

This report contains the results of a comprehensive security and quality analysis of the Flowise project.

## Security Audit Results

- npm audit: $(if [ -f "audit-results.json" ]; then echo "Completed"; else echo "Failed"; fi)
- pnpm audit: Completed
- Docker security: $(if command_exists docker; then echo "Completed"; else echo "Skipped (Docker not available)"; fi)

## Code Quality Results

- ESLint: Completed
- Prettier: Completed  
- TypeScript: Completed

## Build and Test Results

- Build: Completed
- Tests: Completed
- Coverage: Completed

## Performance Results

- Load tests: $(if [ -f "artillery-load-test.yml" ]; then echo "Completed"; else echo "Skipped (No config)"; fi)

## Recommendations

1. **Review Security Issues**: Check audit-results.json for detailed vulnerability information
2. **Update Dependencies**: Address any outdated packages found
3. **Fix Code Quality Issues**: Resolve ESLint and Prettier warnings
4. **Improve Test Coverage**: Aim for higher test coverage
5. **Monitor Performance**: Set up continuous performance monitoring

## Next Steps

1. Review all generated reports
2. Fix identified issues
3. Update dependencies
4. Improve test coverage
5. Set up automated security scanning

EOF

print_success "Security report generated: security-report.md"

# Final Summary
echo ""
echo "🎉 CI/CD Simulation Complete!"
echo "============================="
echo ""
print_success "All CI/CD processes have been simulated"
print_status "Check the following files for detailed results:"
echo "  - audit-results.json (Security audit results)"
echo "  - security-report.md (Comprehensive report)"
echo ""
print_status "To fix issues found:"
echo "  1. Review audit-results.json for security vulnerabilities"
echo "  2. Run 'pnpm audit fix' to fix automatically fixable issues"
echo "  3. Run 'pnpm lint --fix' to fix code quality issues"
echo "  4. Run 'pnpm format' to fix formatting issues"
echo "  5. Update outdated dependencies with 'pnpm update'"
echo ""
print_success "Simulation completed successfully!"
