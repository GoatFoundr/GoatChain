# GoatChain Enterprise Production Setup (Budget-Friendly)

## Infrastructure Overview
- **3 EC2 instances** (t3.small - $25/month each = $75/month)
- **Application Load Balancer** ($18/month)
- **CloudWatch monitoring** ($10/month)
- **Domain + SSL** (Free with Let's Encrypt)
- **Total Cost: ~$103/month**

## Node Architecture
```
Internet → CloudFlare (Free DDoS) → ALB → [Node1, Node2, Node3]
```

## Setup Instructions

### Step 1: Create 3 EC2 Instances
```bash
# Instance 1: goatchain-node-1 (Primary)
# Instance 2: goatchain-node-2 (Backup) 
# Instance 3: goatchain-node-3 (Backup)
# All t3.small with same security groups
```

### Step 2: Install on Each Node
```bash
# On each node, run:
cd ~
git clone https://github.com/GoatFoundr/GoatChain.git
cd GoatChain
npm install

# Create node-specific .env
cp .env.example .env.node1  # (or node2, node3)
```

### Step 3: Load Balancer Health Checks
- Target Group: Port 8545
- Health Check: `/` on port 8545
- Healthy Threshold: 2
- Unhealthy Threshold: 3

### Step 4: SSL Certificate (Free)
```bash
# Install certbot on each node
sudo apt install certbot
sudo certbot certonly --standalone -d blockchain.goatfundr.com
```

### Step 5: Monitoring
- CloudWatch logs for each node
- Custom metrics for block height
- SNS alerts for node failures

## Benefits
✅ **High Availability** (3 nodes)
✅ **Auto-failover** (ALB handles it)
✅ **SSL/HTTPS** (Free with Let's Encrypt)
✅ **DDoS Protection** (CloudFlare free tier)
✅ **Monitoring** (CloudWatch)
✅ **Cost-effective** (~$100/month vs $500+)

## Node Synchronization
- All nodes run same blockchain
- ALB routes traffic to healthy nodes
- If 1 node fails, 2 others continue
- Manual sync process for failed nodes 