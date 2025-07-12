#!/bin/bash
set -e

echo "🔥 Starting GoatChain with REAL Geth - Production Mode!"

# Create data directory
mkdir -p /home/ubuntu/goatchain-data

# Initialize genesis block (only run once)
if [ ! -f /home/ubuntu/goatchain-data/geth/chaindata/000001.log ]; then
    echo "🌟 Initializing Genesis Block..."
    geth --datadir /home/ubuntu/goatchain-data init /home/ubuntu/GoatChain/genesis.json
fi

# Create account if it doesn't exist
if [ ! -f /home/ubuntu/goatchain-data/keystore/* ]; then
    echo "🔑 Creating mining account..."
    geth --datadir /home/ubuntu/goatchain-data account new --password <(echo "password123")
fi

# Start Geth node
echo "🚀 Starting Geth Node..."
geth \
    --datadir /home/ubuntu/goatchain-data \
    --networkid 999191917 \
    --http \
    --http.addr "0.0.0.0" \
    --http.port 8545 \
    --http.api "admin,db,eth,net,web3,personal,miner" \
    --http.corsdomain "*" \
    --ws \
    --ws.addr "0.0.0.0" \
    --ws.port 8546 \
    --ws.api "admin,db,eth,net,web3,personal,miner" \
    --ws.origins "*" \
    --mine \
    --maxpeers 50 \
    --cache 1024 \
    --syncmode "full" \
    --gcmode "archive" \
    --verbosity 3 