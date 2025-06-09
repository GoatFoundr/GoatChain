#!/bin/bash

# Create data directory if it doesn't exist
mkdir -p ~/goatchain-data

# Initialize the blockchain with genesis block
docker run --rm -v ~/goatchain-data:/root/.ethereum -v $(pwd)/genesis.json:/genesis.json ethereum/client-go init /genesis.json

# Start the Geth node
docker run -d --name goatchain \
  -p 8545:8545 \
  -p 8546:8546 \
  -p 30303:30303 \
  -v ~/goatchain-data:/root/.ethereum \
  ethereum/client-go \
  --http \
  --http.addr "0.0.0.0" \
  --http.api "eth,net,web3,personal,miner,admin" \
  --http.corsdomain "https://goatfundr.com" \
  --http.vhosts "rpc.goatfundr.com" \
  --ws \
  --ws.addr "0.0.0.0" \
  --ws.api "eth,net,web3,personal,miner,admin" \
  --ws.origins "https://goatfundr.com" \
  --allow-insecure-unlock \
  --rpc.allow-unprotected-txs \
  --nodiscover \
  --networkid 1337 \
  --mine \
  --miner.threads 1 \
  --miner.etherbase "0x0000000000000000000000000000000000000000"

echo "GoatChain node is starting..."
echo "RPC URL: https://rpc.goatfundr.com"
echo "WebSocket URL: wss://rpc.goatfundr.com:8546" 