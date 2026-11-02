#!/bin/bash
set -eu

# Allow callers to override the RPC server port.
export RPC_PORT="${RPC_PORT:-8095}"

# Resolve repository paths relative to this script.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
fuzz_test_dir="$project_dir/fuzz_test"

(
    # Run the TypeScript oracle server from its package directory.
    cd "$fuzz_test_dir"

    # Install oracle server dependencies when running from a fresh clone.
    if [ ! -d "node_modules" ]; then
        echo "Installing RPC server dependencies..."
        yarn install --frozen-lockfile 2>&1 || yarn install 2>&1
    fi

    # Start the TypeScript RPC server in the background.
    echo "Starting direct TypeScript RPC server..."
    yarn tsx rpc_server.ts &
    TS_SERVER_PID=$!

    # Stop the RPC server when the test command exits.
    cleanup() {
        kill "$TS_SERVER_PID" 2>/dev/null || true
    }
    trap cleanup EXIT

    # Wait briefly for the RPC server to accept requests.
    sleep 2

    # Run the Noir tests against the local oracle resolver.
    nargo --program-dir="$project_dir" test --oracle-resolver "http://localhost:${RPC_PORT}"
)
