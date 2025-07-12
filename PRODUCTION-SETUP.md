# GoatChain Production Setup

## Quick Setup

### 1. Environment Variables
Create a `.env` file in your GoatChain directory:

```bash
# Your domain and endpoints
RPC_URL=https://your-domain.com:8545
WS_URL=wss://your-domain.com:8546

# Allowed origins for CORS (comma-separated)
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://goatfundr.com

# Your wallet mnemonic (12 words)
MNEMONIC=your twelve word mnemonic phrase here for deployment wallet
```

### 2. Domain Setup
1. Point your domain to your EC2 instance IP
2. Set up SSL certificate (Let's Encrypt recommended)
3. Configure nginx/apache to proxy to port 8545/8546

### 3. Deploy to Production
```bash
npm run deploy:production
```

## Security Fixed ✅
- ❌ `allowUnprotectedTxs: true` → ✅ `allowUnprotectedTxs: false`
- ❌ `cors: ["*"]` → ✅ `cors: ["${ALLOWED_ORIGINS}"]`
- ❌ Hardcoded IP → ✅ Domain-based URLs
- ✅ Added rate limiting
- ✅ Added proper mining intervals

## What Changed
- **node-config.json**: Fixed security vulnerabilities
- **hardhat.config.js**: Added proper configuration
- **deploy-ec2.js**: Updated for domain-based deployment
- **package.json**: Added production deployment script

Your blockchain is now production-ready! 🚀 