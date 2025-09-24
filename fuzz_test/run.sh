#!/bin/bash
set -eu

export RPC_PORT=8095

# Start TypeScript RPC server in background
echo "Starting direct TypeScript RPC server..."
yarn tsx rpc_server.ts &
TS_SERVER_PID=$!
trap 'kill $TS_SERVER_PID' EXIT

# Wait for JavaScript server to start
sleep 2

project_dir="$(dirname "$0")/.."

# Run the Noir tests with oracle resolver
nargo --program-dir="$project_dir" test --oracle-resolver http://localhost:${RPC_PORT}
