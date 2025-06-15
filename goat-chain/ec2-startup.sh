#!/bin/bash

# Create necessary directories
mkdir -p /home/ec2-user/goat-chain/data
cd /home/ec2-user/goat-chain

# Create password file
echo "your-password-here" > password.txt

# Initialize genesis block if not already done
if [ ! -f "/home/ec2-user/goat-chain/data/geth/chaindata/CURRENT" ]; then
    geth --datadir /home/ec2-user/goat-chain/data init genesis.json
fi

# Start Geth with proper configuration
nohup geth \
    --datadir /home/ec2-user/goat-chain/data \
    --networkid 999191917 \
    --http \
    --http.addr 0.0.0.0 \
    --http.port 8545 \
    --http.api eth,net,web3,personal,miner \
    --http.corsdomain "*" \
    --http.vhosts "*" \
    --allow-insecure-unlock \
    --unlock 0x7c0d52faab596c08f484e3478aebc6205f3f5d8c \
    --password password.txt \
    --mine \
    --miner.etherbase 0x7c0d52faab596c08f484e3478aebc6205f3f5d8c \
    --miner.gasprice 1000000000 \
    --miner.gaslimit 8000000 \
    --nodiscover \
    --verbosity 3 \
    > geth.log 2>&1 &

# Save the process ID
echo $! > geth.pid 