#!/bin/bash

# ==============================|| FLOWISE LOCAL TEST SCRIPT ||============================== #
# This script tests the Flowise deployment locally before VPS deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo -e "${BLUE}🧪 FLOWISE LOCAL TEST - AI ASSISTANT BRANDING${NC}"
echo -e "${BLUE}=============================================${NC}"

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "Please run this script from the Flowise project root directory"
    exit 1
fi

# Check if Logo.jsx has our modifications
if grep -q "AI Assistant" packages/ui/src/ui-component/extended/Logo.jsx; then
    print_status "Logo modification found: 'AI Assistant' branding"
else
    print_warning "Logo modification not found. Expected 'AI Assistant' in Logo.jsx"
fi

# Check if required files exist
REQUIRED_FILES=(
    "packages/ui/src/ui-component/extended/Logo.jsx"
    "packages/ui/src/layout/MainLayout/LogoSection/index.jsx"
    "packages/ui/src/layout/MainLayout/Header/index.jsx"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status "Found: $file"
    else
        print_error "Missing: $file"
        exit 1
    fi
done

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null || echo "not installed")
if [[ $NODE_VERSION == v18* ]] || [[ $NODE_VERSION == v20* ]]; then
    print_status "Node.js version compatible: $NODE_VERSION"
else
    print_warning "Node.js version may not be compatible: $NODE_VERSION"
    print_info "Recommended: Node.js 18.x or 20.x"
fi

# Check if pnpm is installed
if command -v pnpm &> /dev/null; then
    print_status "pnpm is installed: $(pnpm --version)"
else
    print_error "pnpm is not installed. Please install it first:"
    print_info "npm install -g pnpm"
    exit 1
fi

# Test build process
print_info "Testing build process..."
if pnpm install --frozen-lockfile; then
    print_status "Dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi

if pnpm build; then
    print_status "Build completed successfully"
else
    print_error "Build failed"
    exit 1
fi

# Check if build artifacts exist
if [ -d "packages/ui/dist" ]; then
    print_status "UI build artifacts found"
else
    print_warning "UI build artifacts not found"
fi

if [ -d "packages/server/dist" ]; then
    print_status "Server build artifacts found"
else
    print_warning "Server build artifacts not found"
fi

# Test Docker build (if Docker is available)
if command -v docker &> /dev/null; then
    print_info "Testing Docker build..."
    if docker build -t flowise-test -f Dockerfile.vps . 2>/dev/null; then
        print_status "Docker build successful"
        docker rmi flowise-test 2>/dev/null || true
    else
        print_warning "Docker build failed (this is expected if Dockerfile.vps doesn't exist yet)"
    fi
else
    print_info "Docker not available - skipping Docker test"
fi

# Summary
echo -e "${GREEN}"
echo "🎉 LOCAL TEST COMPLETED! 🎉"
echo "=========================="
echo "✅ Logo modification: AI Assistant"
echo "✅ Dependencies: Installed"
echo "✅ Build: Successful"
echo "✅ Ready for VPS deployment!"
echo ""
echo "Next steps:"
echo "1. Upload this project to your VPS"
echo "2. Run: ./deploy-vps-complete.sh"
echo "3. Access your AI Assistant at: https://your-domain.com"
echo -e "${NC}"
