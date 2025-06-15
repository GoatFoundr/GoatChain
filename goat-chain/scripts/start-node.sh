#!/bin/bash

# Kill any existing geth processes
pkill -f geth

# Start geth with mining enabled and 1 thread
geth --datadir ./data \
    --networkid 1337 \
    --http \
    --http.addr "0.0.0.0" \
    --http.port 8545 \
    --http.api "eth,net,web3,personal,miner" \
    --http.corsdomain "*" \
    --allow-insecure-unlock \
    --mine \
    --miner.threads=1 \
    --miner.etherbase "0x0000000000000000000000000000000000000000" \
    --nodiscover \
    --verbosity 3 \
    --nat extip:$(curl -s ifconfig.me) \
    --nat extport:30303 \
    --port 30303 \
    --ws \
    --ws.addr "0.0.0.0" \
    --ws.port 8546 \
    --ws.api "eth,net,web3,personal,miner" \
    --ws.origins "*" \
    --unlock "0x0000000000000000000000000000000000000000" \
    --password ./password.txt \
    console 