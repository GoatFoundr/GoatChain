# GoatChain Blockchain

This repository contains the necessary files to run a GoatChain node.

## Setup Instructions

1. Make sure Docker is installed on your system
2. Clone this repository
3. Make the start script executable:
   ```bash
   chmod +x start-node.sh
   ```
4. Start the node:
   ```bash
   ./start-node.sh
   ```

## RPC Endpoints

- RPC URL: https://goatfundr.com:8545
- WebSocket URL: wss://goatfundr.com:8546

## Configuration

The node is configured with:
- Network ID: 1337
- Chain ID: 1337
- Mining enabled
- HTTP and WebSocket RPC enabled
- CORS enabled for goatfundr.com

## Connecting to GoatChain

### MetaMask Configuration
1. Open MetaMask
2. Click on the network dropdown
3. Click "Add Network"
4. Fill in the following details:
   - Network Name: GoatChain
   - RPC URL: https://goatfundr.com:8545
   - Chain ID: 1337
   - Currency Symbol: ETH

### DNS Configuration
Make sure your domain (goatfundr.com) points to your EC2 instance's IP address.

### Security Groups
Make sure your EC2 security group allows:
- Inbound TCP on port 8545 (RPC)
- Inbound TCP on port 8546 (WebSocket)
- Inbound TCP on port 30303 (P2P)

## Monitoring

To check the node status:
```bash
docker logs -f goatchain
```

To stop the node:
```bash
docker stop goatchain
```

To restart the node:
```bash
docker start goatchain
``` 
