#!/bin/bash
set -e

NODE_ID=${1:-"node1"}
echo "🏢 Starting GoatChain Enterprise Node: $NODE_ID"

# Load environment variables
source .env

# Create logs directory
mkdir -p /home/ubuntu/goatchain-logs

# Kill any existing processes
pkill -f hardhat || true

# Start health check server in background
cat > /tmp/health-server.js << 'EOF'
const http = require('http');
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({
      status: 'healthy',
      node: process.env.NODE_ID || 'unknown',
      timestamp: new Date().toISOString(),
      chainId: 999191917
    }));
  } else if (req.url === '/') {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('GoatChain Node OK');
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});
server.listen(8080, '0.0.0.0', () => {
  console.log('Health check server running on port 8080');
});
EOF

NODE_ID=$NODE_ID node /tmp/health-server.js &
HEALTH_PID=$!

# Start Hardhat node with enterprise settings
echo "🚀 Starting Hardhat Node (Enterprise Mode)"
npx hardhat node \
    --hostname 0.0.0.0 \
    --port 8545 \
    --max-memory 4096 \
    > /home/ubuntu/goatchain-logs/node-$NODE_ID.log 2>&1 &

HARDHAT_PID=$!

# Save PIDs for monitoring
echo $HEALTH_PID > /tmp/health.pid
echo $HARDHAT_PID > /tmp/hardhat.pid

echo "✅ Node $NODE_ID started successfully!"
echo "📊 Health check: http://localhost:8080/health"
echo "🔗 RPC endpoint: http://localhost:8545"
echo "📝 Logs: /home/ubuntu/goatchain-logs/node-$NODE_ID.log"

# Wait for processes (keeps script running)
wait $HARDHAT_PID 