#!/bin/bash

echo "Stopping GoatChain blockchain node..."

# Check if PID file exists
if [ -f blockchain.pid ]; then
    PID=$(cat blockchain.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "Stopping process with PID: $PID"
        kill $PID
        rm blockchain.pid
        echo "✅ Blockchain node stopped"
    else
        echo "Process $PID not found"
        rm blockchain.pid
    fi
else
    echo "No PID file found, trying to kill by process name..."
    pkill -f "hardhat node"
    echo "✅ Blockchain processes stopped"
fi

echo "Blockchain node shutdown complete!" 