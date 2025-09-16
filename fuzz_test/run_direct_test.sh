#!/bin/bash

echo "=== Direct Noir Base64 Oracle Test ==="
echo "This test compares Noir base64 implementation with Node.js base64 via oracles"
echo ""

# Check if nargo is available
if ! command -v nargo &> /dev/null; then
    echo "Error: nargo command not found!"
    echo "Please install nargo or add it to your PATH"
    exit 1
fi

echo "Found nargo: $(which nargo)"

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "Error: Node.js not found!"
    echo "Please install Node.js to run the JavaScript RPC server"
    exit 1
fi

echo "Found Node.js: $(which node)"

# Install JavaScript dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing JavaScript dependencies..."
    npm install
fi

# Start JavaScript RPC server in background
echo "Starting direct JavaScript RPC server..."
node direct_rpc_server.js &
JS_SERVER_PID=$!

# Wait for JavaScript server to start
sleep 2

echo "Running Noir oracle tests..."
cd /Users/jli/Desktop/noir-lang/noir_base64

# Run the Noir tests with oracle resolver
nargo test --oracle-resolver http://localhost:5556

# Clean up
echo "Stopping server..."
kill $JS_SERVER_PID 2>/dev/null

echo "Direct oracle test completed!"
