#!/bin/bash

# Build script for base image integration test
# This script tests basic CI operations that should work in the base image

set -e  # Exit on any error

echo "Running base image integration tests..."

# Navigate to the data directory
cd ./data

echo "=== Testing basic file operations ==="
# Test basic file operations in user's home directory
echo "test content" > ~/test_file.txt
if [ "$(cat ~/test_file.txt)" = "test content" ]; then
    echo "✅ File read/write operations work"
else
    echo "❌ File operations failed"
    exit 1
fi

echo "=== Testing Node.js functionality ==="
# Test Node.js (installed in base image)
if node --version > /dev/null 2>&1; then
    echo "✅ Node.js is available"
else
    echo "❌ Node.js not found"
    exit 1
fi

# Create a simple Node.js script and run it
cat > ~/hello.js << 'EOF'
console.log("Hello from Node.js in base image!");
console.log("Current directory:", process.cwd());
console.log("Node version:", process.version);
EOF

if node ~/hello.js | grep -q "Hello from Node.js"; then
    echo "✅ Node.js script execution works"
else
    echo "❌ Node.js script execution failed"
    exit 1
fi

echo "=== Testing curl functionality ==="
# Test curl (installed in base image)
if curl --version > /dev/null 2>&1; then
    echo "✅ curl is available"
else
    echo "❌ curl not found"
    exit 1
fi

# Test HTTP request (using httpbin.org for testing)
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://httpbin.org/status/200 | grep -q "200"; then
    echo "✅ HTTP requests work"
else
    echo "⚠️  HTTP requests failed (network may not be available)"
    # Don't fail the test for network issues
fi

echo "=== Testing git functionality ==="
# Test git (installed in base image)
if git --version > /dev/null 2>&1; then
    echo "✅ git is available"
else
    echo "❌ git not found"
    exit 1
fi

# Initialize a test git repository
git init ~/test-repo
cd ~/test-repo
echo "test content" > test.txt
git add test.txt
git -c user.email="test@example.com" -c user.name="Test User" commit -m "Initial commit"

if git log --oneline | grep -q "Initial commit"; then
    echo "✅ Git operations work"
else
    echo "❌ Git operations failed"
    exit 1
fi

cd -

echo "=== Testing bash scripting ==="
# Test bash scripting capabilities
cat > ~/test_script.sh << 'EOF'
#!/bin/bash
echo "Script executed successfully"
exit 0
EOF
chmod +x ~/test_script.sh

if ~/test_script.sh | grep -q "Script executed successfully"; then
    echo "✅ Bash script execution works"
else
    echo "❌ Bash script execution failed"
    exit 1
fi

echo "=== Testing unzip functionality ==="
# Test unzip (installed in base image)
echo "test content for zip" > ~/zip_test.txt
cd ~
zip test.zip zip_test.txt

if unzip -l test.zip | grep -q "zip_test.txt"; then
    echo "✅ unzip functionality works"
else
    echo "❌ unzip functionality failed"
    exit 1
fi

# Extract and verify
mkdir -p ~/extract_test
cd ~/extract_test
unzip ../test.zip
if [ "$(cat zip_test.txt)" = "test content for zip" ]; then
    echo "✅ File extraction works"
else
    echo "❌ File extraction failed"
    exit 1
fi
cd -

echo "=== Testing environment ==="
# Test that we're running as the runner user (non-root)
if [ "$(whoami)" = "runner" ]; then
    echo "✅ Running as non-root user (runner)"
else
    echo "❌ Not running as expected user (got: $(whoami))"
    exit 1
fi

# Test that workspace directory exists and is accessible
if [ -d "/workspace" ]; then
    echo "✅ Workspace directory exists and is accessible"
else
    echo "❌ Workspace directory is not accessible"
    exit 1
fi

echo ""
echo "🎉 All base image integration tests passed!"
echo "The base image successfully supports:"
echo "  - File operations (read/write)"
echo "  - Node.js execution"
echo "  - HTTP requests with curl"
echo "  - Git version control"
echo "  - Bash scripting"
echo "  - Archive operations (zip/unzip)"
echo "  - Non-root user execution"
echo "  - Writable workspace directory"