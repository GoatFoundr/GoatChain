# GOATCHAIN Deployment Checklist

## Pre-deployment Checks

### Environment Setup
- [ ] Node.js v16+ installed
- [ ] npm installed
- [ ] Git installed
- [ ] AWS CLI installed and configured
- [ ] EC2 instance running (t2.micro or better)

### Security
- [ ] `.env` file created from `.env.example`
- [ ] Private keys and mnemonics properly set in `.env`
- [ ] No sensitive data in version control
- [ ] EC2 security groups configured:
  - [ ] Port 22 (SSH)
  - [ ] Port 8545 (RPC)
  - [ ] Port 8546 (WebSocket)
  - [ ] Port 30303 (P2P)

### Network Configuration
- [ ] EC2 instance has static IP or domain
- [ ] Network configuration updated in `config/node-config.json`
- [ ] RPC and WebSocket URLs properly configured

## Deployment Steps

1. Clone and Setup
   - [ ] Clone repository
   - [ ] Install dependencies (`npm install`)
   - [ ] Compile contracts (`npm run compile`)
   - [ ] Run tests (`npm test`)

2. EC2 Setup
   - [ ] SSH into EC2 instance
   - [ ] Install required dependencies
   - [ ] Configure node settings
   - [ ] Start Geth node

3. Contract Deployment
   - [ ] Deploy FeeManager
   - [ ] Deploy GOATCHAIN Token
   - [ ] Deploy LAZERDIM700 Token
   - [ ] Deploy Staking Contract
   - [ ] Initialize FeeManager

4. Post-deployment Verification
   - [ ] Check all contract addresses in `deployment-info.json`
   - [ ] Verify contract initialization
   - [ ] Test RPC connection
   - [ ] Test WebSocket connection
   - [ ] Verify staking functionality
   - [ ] Verify fee distribution

## Monitoring Setup

- [ ] Set up logging
- [ ] Configure monitoring tools
- [ ] Set up alerts
- [ ] Document monitoring endpoints

## Documentation

- [ ] Update README with deployment info
- [ ] Document contract addresses
- [ ] Update API documentation
- [ ] Create troubleshooting guide

## Backup

- [ ] Backup private keys
- [ ] Backup contract addresses
- [ ] Backup node configuration
- [ ] Document recovery procedures 