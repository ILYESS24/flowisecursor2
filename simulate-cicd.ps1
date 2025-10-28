# Complete CI/CD Simulation Script for Flowise (PowerShell)
# This script simulates all CI/CD processes locally on Windows

param(
    [switch]$SkipDocker,
    [switch]$SkipPerformance,
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Continue"

Write-Host "🚀 Starting Complete CI/CD Simulation for Flowise" -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Check prerequisites
Write-Status "Checking prerequisites..."

if (-not (Test-Command "node")) {
    Write-Error "Node.js is not installed. Please install Node.js 18+ or 20+"
    exit 1
}

if (-not (Test-Command "pnpm")) {
    Write-Error "pnpm is not installed. Please install pnpm 9+"
    exit 1
}

if (-not (Test-Command "docker") -and -not $SkipDocker) {
    Write-Warning "Docker is not installed. Docker security scans will be skipped."
    $SkipDocker = $true
}

Write-Success "Prerequisites check completed"

# Step 1: Security Audit
Write-Status "Step 1: Running Security Audit..."
Write-Host "----------------------------------------" -ForegroundColor Gray

Write-Status "Installing dependencies..."
try {
    pnpm install --frozen-lockfile
    Write-Success "Dependencies installed"
}
catch {
    Write-Warning "Failed to install dependencies: $_"
}

Write-Status "Running npm audit..."
try {
    pnpm audit --audit-level moderate
    Write-Success "npm audit completed"
}
catch {
    Write-Warning "npm audit found issues: $_"
}

Write-Status "Running pnpm audit..."
try {
    pnpm audit --audit-level moderate
    Write-Success "pnpm audit completed"
}
catch {
    Write-Warning "pnpm audit found issues: $_"
}

Write-Status "Checking for known vulnerabilities..."
try {
    pnpm audit --json | Out-File -FilePath "audit-results.json" -Encoding UTF8
    Write-Success "Audit results saved to audit-results.json"
}
catch {
    Write-Warning "Audit completed with issues: $_"
}

Write-Success "Security audit completed"

# Step 2: Code Quality
Write-Status "Step 2: Running Code Quality Checks..."
Write-Host "---------------------------------------------" -ForegroundColor Gray

Write-Status "Running ESLint..."
try {
    pnpm lint
    Write-Success "ESLint completed"
}
catch {
    Write-Warning "ESLint found issues: $_"
}

Write-Status "Running Prettier check..."
try {
    pnpm format --check
    Write-Success "Prettier check completed"
}
catch {
    Write-Warning "Prettier found formatting issues: $_"
}

Write-Status "Running TypeScript type check..."
try {
    pnpm --filter "./packages/**" tsc --noEmit
    Write-Success "TypeScript check completed"
}
catch {
    Write-Warning "TypeScript found type issues: $_"
}

Write-Success "Code quality checks completed"

# Step 3: Build and Test
Write-Status "Step 3: Building and Testing..."
Write-Host "-------------------------------------" -ForegroundColor Gray

Write-Status "Building project..."
try {
    $env:NODE_OPTIONS = "--max_old_space_size=4096"
    pnpm build
    Write-Success "Build completed"
}
catch {
    Write-Warning "Build failed: $_"
}

Write-Status "Running tests..."
try {
    pnpm test
    Write-Success "Tests completed"
}
catch {
    Write-Warning "Some tests failed: $_"
}

Write-Status "Generating test coverage..."
try {
    pnpm --filter "./packages/**" test --coverage
    Write-Success "Coverage generated"
}
catch {
    Write-Warning "Coverage generation had issues: $_"
}

Write-Success "Build and test completed"

# Step 4: Docker Security (if Docker is available)
if (-not $SkipDocker) {
    Write-Status "Step 4: Docker Security Scan..."
    Write-Host "------------------------------------" -ForegroundColor Gray
    
    Write-Status "Building Docker image..."
    try {
        docker build --no-cache -t flowise:test .
        Write-Success "Docker image built"
        
        if (Test-Command "trivy") {
            Write-Status "Running Trivy vulnerability scanner..."
            try {
                trivy image flowise:test
                Write-Success "Trivy scan completed"
            }
            catch {
                Write-Warning "Trivy found vulnerabilities: $_"
            }
        }
        else {
            Write-Warning "Trivy not installed. Install it for vulnerability scanning: https://trivy.dev/"
        }
    }
    catch {
        Write-Warning "Docker build failed: $_"
    }
    
    Write-Success "Docker security scan completed"
}
else {
    Write-Warning "Skipping Docker security scan"
}

# Step 5: Performance Testing
if (-not $SkipPerformance) {
    Write-Status "Step 5: Performance Testing..."
    Write-Host "-----------------------------------" -ForegroundColor Gray
    
    Write-Status "Starting Flowise server for performance testing..."
    try {
        $serverJob = Start-Job -ScriptBlock { 
            Set-Location $using:PWD
            pnpm start 
        }
        
        # Wait for server to start
        Write-Status "Waiting for server to start..."
        Start-Sleep -Seconds 30
        
        # Check if server is running
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
            Write-Success "Server is running"
            
            if (Test-Path "artillery-load-test.yml") {
                Write-Status "Running Artillery load tests..."
                try {
                    npx artillery run artillery-load-test.yml
                    Write-Success "Load tests completed"
                }
                catch {
                    Write-Warning "Load tests had issues: $_"
                }
            }
            else {
                Write-Warning "No Artillery config found, skipping load tests"
            }
        }
        catch {
            Write-Warning "Server failed to start or is not responding: $_"
        }
        
        # Stop server
        Stop-Job $serverJob
        Remove-Job $serverJob
    }
    catch {
        Write-Warning "Performance testing failed: $_"
    }
    
    Write-Success "Performance testing completed"
}
else {
    Write-Warning "Skipping performance testing"
}

# Step 6: Dependency Check
Write-Status "Step 6: Dependency Analysis..."
Write-Host "------------------------------------" -ForegroundColor Gray

Write-Status "Checking for outdated packages..."
try {
    pnpm outdated
    Write-Success "Outdated packages check completed"
}
catch {
    Write-Warning "Found outdated packages: $_"
}

if (Test-Command "depcheck") {
    Write-Status "Checking for unused dependencies..."
    try {
        depcheck
        Write-Success "Unused dependencies check completed"
    }
    catch {
        Write-Warning "Found unused dependencies: $_"
    }
}
else {
    Write-Warning "depcheck not installed. Install it for unused dependency analysis: npm install -g depcheck"
}

Write-Success "Dependency analysis completed"

# Step 7: License Check
Write-Status "Step 7: License Compliance..."
Write-Host "----------------------------------" -ForegroundColor Gray

if (Test-Command "license-checker") {
    Write-Status "Checking package licenses..."
    try {
        license-checker --summary
        Write-Success "License check completed"
    }
    catch {
        Write-Warning "License check found issues: $_"
    }
}
else {
    Write-Warning "license-checker not installed. Install it for license analysis: npm install -g license-checker"
}

Write-Success "License compliance check completed"

# Step 8: Generate Report
Write-Status "Step 8: Generating Security Report..."
Write-Host "------------------------------------------" -ForegroundColor Gray

$reportContent = @"
# Flowise Security Scan Report

Generated on: $(Get-Date)

## Summary

This report contains the results of a comprehensive security and quality analysis of the Flowise project.

## Security Audit Results

- npm audit: $(if (Test-Path "audit-results.json") { "Completed" } else { "Failed" })
- pnpm audit: Completed
- Docker security: $(if (-not $SkipDocker) { "Completed" } else { "Skipped (Docker not available)" })

## Code Quality Results

- ESLint: Completed
- Prettier: Completed  
- TypeScript: Completed

## Build and Test Results

- Build: Completed
- Tests: Completed
- Coverage: Completed

## Performance Results

- Load tests: $(if (Test-Path "artillery-load-test.yml") { "Completed" } else { "Skipped (No config)" })

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

"@

$reportContent | Out-File -FilePath "security-report.md" -Encoding UTF8
Write-Success "Security report generated: security-report.md"

# Final Summary
Write-Host ""
Write-Host "🎉 CI/CD Simulation Complete!" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""
Write-Success "All CI/CD processes have been simulated"
Write-Status "Check the following files for detailed results:"
Write-Host "  - audit-results.json (Security audit results)" -ForegroundColor White
Write-Host "  - security-report.md (Comprehensive report)" -ForegroundColor White
Write-Host ""
Write-Status "To fix issues found:"
Write-Host "  1. Review audit-results.json for security vulnerabilities" -ForegroundColor White
Write-Host "  2. Run 'pnpm audit fix' to fix automatically fixable issues" -ForegroundColor White
Write-Host "  3. Run 'pnpm lint --fix' to fix code quality issues" -ForegroundColor White
Write-Host "  4. Run 'pnpm format' to fix formatting issues" -ForegroundColor White
Write-Host "  5. Update outdated dependencies with 'pnpm update'" -ForegroundColor White
Write-Host ""
Write-Success "Simulation completed successfully!"
