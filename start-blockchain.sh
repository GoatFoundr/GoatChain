#!/bin/bash

# Start the blockchain node in the background
echo "Starting GoatChain blockchain node..."
npx hardhat node --port 8545 --hostname 0.0.0.0 > blockchain.log 2>&1 &

# Store the PID
echo $! > blockchain.pid
echo "Blockchain node started with PID: $!"
echo "Logs are being written to blockchain.log"

# Wait a moment for the node to start
sleep 3

# Check if the node is running
if curl -s http://localhost:8545 > /dev/null; then
    echo "✅ Blockchain node is running on port 8545"
else
    echo "❌ Failed to start blockchain node"
    cat blockchain.log
    exit 1
fi

echo "Node is ready for deployment!" 