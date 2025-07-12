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

# Start Geth node
echo "🚀 Starting Geth Node..."
geth \
    --datadir /home/ubuntu/goatchain-data \
    --networkid 999191917 \
    --rpc \
    --rpcaddr "0.0.0.0" \
    --rpcport 8545 \
    --rpcapi "admin,db,eth,net,web3,personal,miner" \
    --rpccorsdomain "*" \
    --ws \
    --wsaddr "0.0.0.0" \
    --wsport 8546 \
    --wsapi "admin,db,eth,net,web3,personal,miner" \
    --wsorigins "*" \
    --mine \
    --miner.threads 1 \
    --etherbase "0x0000000000000000000000000000000000000000" \
    --unlock "0x0000000000000000000000000000000000000000" \
    --password /dev/null \
    --allow-insecure-unlock \
    --maxpeers 50 \
    --cache 1024 \
    --syncmode "full" \
    --gcmode "archive" \
    --verbosity 3 \
    --log.file /home/ubuntu/goatchain-data/geth.log 