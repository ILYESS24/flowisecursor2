#!/bin/bash

# Render Build Script for Flowise
echo "🚀 Starting Flowise build for Render..."

# Set environment variables
export NODE_ENV=production
export PORT=${PORT:-10000}

# Install dependencies
echo "📦 Installing dependencies..."
pnpm install --frozen-lockfile

# Build the project
echo "🔨 Building Flowise..."
pnpm build

# Verify build
if [ -f "packages/server/dist/index.js" ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed - dist/index.js not found"
    exit 1
fi

# Set permissions for render-start.js
chmod +x packages/server/bin/render-start.js

echo "🎉 Build completed successfully!"
