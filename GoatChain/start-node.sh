#!/bin/bash

# Create data directory if it doesn't exist
mkdir -p ~/goatchain-data

# Initialize the blockchain with genesis block
docker run --rm -v ~/goatchain-data:/root/.ethereum -v $(pwd)/genesis.json:/genesis.json ethereum/client-go init /genesis.json

# Stop existing container if it exists
docker stop goatchain || true
docker rm goatchain || true

# Start the Geth node with Cloudflare-friendly configuration
docker run -d --name goatchain \
  -p 8545:8545 \
  -p 8546:8546 \
  -p 30303:30303 \
  -v ~/goatchain-data:/root/.ethereum \
  ethereum/client-go \
  --http \
  --http.addr "0.0.0.0" \
  --http.api "eth,net,web3,personal,miner,admin" \
  --http.corsdomain "*" \
  --http.vhosts "rpc2.goatfundr.com" \
  --ws \
  --ws.addr "0.0.0.0" \
  --ws.api "eth,net,web3,personal,miner,admin" \
  --ws.origins "*" \
  --allow-insecure-unlock \
  --rpc.allow-unprotected-txs \
  --nodiscover \
  --networkid 1337 \
  --mine \
  --miner.threads 1 \
  --miner.etherbase "0x0000000000000000000000000000000000000000" \
  --maxpeers 50 \
  --syncmode "full" \
  --cache 2048 \
  --metrics \
  --metrics.addr "0.0.0.0" \
  --metrics.port 6060

echo "GoatChain node is starting..."
echo "RPC URL: https://rpc2.goatfundr.com"
echo "WebSocket URL: wss://rpc2.goatfundr.com:8546"
echo "Metrics URL: http://localhost:6060/debug/metrics"

# Wait for the node to start
sleep 5

# Check node status
docker logs goatchain 