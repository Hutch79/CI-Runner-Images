#!/bin/bash

# Build script for Node.js 22 demo application
# This script builds the application located in ./data

set -e  # Exit on any error

echo "Building Node.js 22 demo application..."

# Navigate to the data directory where the application is located
cd ./data

# Install dependencies
echo "Installing dependencies..."
npm install

# Build the application (if build script exists)
if npm run | grep -q "build"; then
    echo "Building the application..."
    npm run build
else
    echo "No build script found, skipping build step"
fi

# Run basic tests (if test script exists)
if npm run | grep -q "test"; then
    echo "Running tests..."
    npm test
else
    echo "No test script found, skipping tests"
fi

echo "Build completed successfully!"

# Start the application to verify it works
echo "Starting the application..."
timeout 10s npm start &
APP_PID=$!

# Wait a moment for the app to start
sleep 3

# Check if the application process is still running
if ! kill -0 $APP_PID 2>/dev/null; then
    echo "❌ Application failed to start"
    exit 1
fi

# Check if the app is responding
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
    echo "✅ Application is responding correctly"
else
    echo "❌ Application is not responding"
    kill $APP_PID 2>/dev/null || true
    exit 1
fi

# Clean up
kill $APP_PID 2>/dev/null || true
echo "Application test completed successfully!"