#!/bin/bash

echo "Building simple fuzz test..."
cargo build --release

echo "Running simple fuzz test..."
cargo run --release --bin simple_fuzz_test
