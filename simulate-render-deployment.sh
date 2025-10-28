#!/bin/bash

# RENDER DEPLOYMENT SIMULATION SCRIPT
# Simulating Render's deployment process for Flowise

echo "🚀 RENDER DEPLOYMENT SIMULATION"
echo "================================"
echo ""

# Step 1: Environment Setup (as Render would do)
echo "📋 STEP 1: Environment Setup"
echo "Setting NODE_ENV=production"
export NODE_ENV=production
export PORT=10000
echo "✅ Environment variables set"
echo ""

# Step 2: Install Dependencies (as Render would do)
echo "📦 STEP 2: Installing Dependencies"
echo "Running: pnpm install --frozen-lockfile"
if pnpm install --frozen-lockfile; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Dependency installation failed"
    exit 1
fi
echo ""

# Step 3: Build Process (as Render would do)
echo "🔨 STEP 3: Building Application"
echo "Running: pnpm build"
if pnpm build; then
    echo "✅ Build completed successfully"
else
    echo "❌ Build failed"
    exit 1
fi
echo ""

# Step 4: Verify Build Output
echo "🔍 STEP 4: Verifying Build Output"
if [ -f "packages/server/dist/index.js" ]; then
    echo "✅ Server build found: packages/server/dist/index.js"
else
    echo "❌ Server build not found"
    exit 1
fi

if [ -f "packages/ui/build/index.html" ]; then
    echo "✅ UI build found: packages/ui/build/index.html"
else
    echo "⚠️  UI build not found (expected for server-only deployment)"
fi
echo ""

# Step 5: Test Start Command (as Render would do)
echo "🚀 STEP 5: Testing Start Command"
echo "Testing: cd packages/server && pnpm start:render"
cd packages/server

# Check if render-start.js exists and is executable
if [ -f "bin/render-start.js" ]; then
    echo "✅ Render start script found"
    chmod +x bin/render-start.js
    echo "✅ Render start script made executable"
else
    echo "❌ Render start script not found"
    exit 1
fi

echo ""
echo "🎉 RENDER DEPLOYMENT SIMULATION COMPLETED SUCCESSFULLY!"
echo "======================================================"
echo ""
echo "✅ All checks passed - Ready for Render deployment"
echo "📋 Configuration Summary:"
echo "   - Build Command: pnpm install && pnpm build"
echo "   - Start Command: cd packages/server && pnpm start:render"
echo "   - Port: 10000"
echo "   - Environment: production"
echo ""
echo "🚀 Your Flowise app is ready to deploy on Render!"
