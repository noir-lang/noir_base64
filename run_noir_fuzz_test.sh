#!/bin/bash

echo "=== Noir Base64 Fuzz Test ==="
echo "This test compares Noir base64 implementation with Rust gRPC server"
echo ""

# Check if nargo is available
if ! command -v nargo &> /dev/null; then
    echo "Error: nargo command not found!"
    echo "Please install nargo or add it to your PATH"
    echo ""
    echo "To install nargo:"
    echo "  curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash"
    echo "  source ~/.bashrc"
    echo "  noirup"
    exit 1
fi

echo "Found nargo: $(which nargo)"

# Start gRPC server in background
echo "Starting gRPC server..."
cd fuzz_test
cargo run --release --bin grpc_server &
SERVER_PID=$!

# Wait for server to start
sleep 3

echo "Running Noir fuzz tests..."
cd ..

# Run the Noir tests
nargo test

# Clean up
echo "Stopping gRPC server..."
kill $SERVER_PID 2>/dev/null

echo "Fuzz test completed!"
