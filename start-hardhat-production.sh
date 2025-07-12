#!/bin/bash
set -e

echo "🚀 Starting GoatChain Production Node with Hardhat!"
echo "Chain ID: 999191917"
echo "RPC: http://0.0.0.0:8545"
echo "WebSocket: ws://0.0.0.0:8546"

# Kill any existing hardhat processes
pkill -f hardhat || true

# Start Hardhat node in production mode
npx hardhat node \
    --hostname 0.0.0.0 \
    --port 8545 \
    --max-memory 4096 