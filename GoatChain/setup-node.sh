#!/bin/bash

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y wget unzip curl

# Download and install Nethermind
wget https://github.com/NethermindEth/nethermind/releases/download/1.24.0/nethermind-linux-amd64-1.24.0.zip
unzip nethermind-linux-amd64-1.24.0.zip
sudo mv nethermind /usr/local/bin/

# Create config directory
mkdir -p ~/goatchain/config

# Create Nethermind config
cat > ~/goatchain/config/config.json << EOL
{
  "Init": {
    "WebSocketsEnabled": true,
    "StoreReceipts": true,
    "EnableUnsecuredDevWallet": false,
    "IsMining": true,
    "ChainSpecPath": "genesis.json",
    "BaseDbPath": "goatchain",
    "LogFileName": "goatchain.logs.txt",
    "MemoryHint": 8192,
    "MaxLogFileSize": 1024,
    "MaxLogFiles": 5
  },
  "Network": {
    "DiscoveryPort": 30303,
    "P2PPort": 30303,
    "ExternalIp": null,
    "LocalIp": "0.0.0.0",
    "MaxActivePeers": 25,
    "StaticPeers": []
  },
  "JsonRpc": {
    "Enabled": true,
    "Host": "0.0.0.0",
    "Port": 8545,
    "EnabledModules": ["Eth", "Net", "Web3", "Debug", "Trace", "TxPool", "Personal", "Admin"],
    "Timeout": 30000,
    "MaxRequestSize": 30000000,
    "MaxBatchSize": 100,
    "MaxConcurrentRequests": 100
  },
  "WebSockets": {
    "Enabled": true,
    "Host": "0.0.0.0",
    "Port": 8546
  },
  "Metrics": {
    "Enabled": true,
    "NodeName": "goatchain",
    "PushGatewayUrl": "",
    "IntervalSeconds": 5
  }
}
EOL

# Create systemd service
sudo tee /etc/systemd/system/goatchain.service << EOL
[Unit]
Description=GoatChain Node
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/goatchain
ExecStart=/usr/local/bin/nethermind/nethermind --config config.json
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

# Copy genesis file
cp genesis.json ~/goatchain/config/

# Set permissions
chmod +x /usr/local/bin/nethermind/nethermind
sudo chown -R ubuntu:ubuntu ~/goatchain

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable goatchain
sudo systemctl start goatchain

# Setup Nginx for RPC with Cloudflare compatibility
sudo apt-get install -y nginx

# Create SSL directory
sudo mkdir -p /etc/nginx/ssl

# Generate self-signed certificate (Cloudflare will handle the actual SSL)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/goatchain.key \
  -out /etc/nginx/ssl/goatchain.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=rpc.goatfundr.com"

sudo tee /etc/nginx/sites-available/goatchain << EOL
server {
    listen 80;
    server_name rpc.goatfundr.com;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name rpc.goatfundr.com;

    ssl_certificate /etc/nginx/ssl/goatchain.crt;
    ssl_certificate_key /etc/nginx/ssl/goatchain.key;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_stapling off;

    # Cloudflare compatibility
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 2400:cb00::/32;
    set_real_ip_from 2606:4700::/32;
    set_real_ip_from 2803:f800::/32;
    set_real_ip_from 2405:b500::/32;
    set_real_ip_from 2405:8100::/32;
    set_real_ip_from 2a06:98c0::/29;
    set_real_ip_from 2c0f:f248::/32;

    real_ip_header CF-Connecting-IP;

    # Increase timeouts for RPC
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;

    location / {
        proxy_pass http://localhost:8545;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # CORS headers for MetaMask
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/goatchain /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

echo "Setup complete! Your GoatChain node is now running."
echo "RPC endpoint: https://rpc.goatfundr.com" 