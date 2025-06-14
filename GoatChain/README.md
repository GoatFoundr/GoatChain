# GOATCHAIN

GOATCHAIN is the official blockchain of Goat Fundr, a platform built to empower artists and fans through tokenized ownership, reward-based staking, and real-world utility.

## 🚀 Quick Start

1. Clone the repository:
```bash
git clone https://github.com/GoatFoundr/GoatChain.git
cd GoatChain
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Compile contracts:
```bash
npm run compile
```

5. Run tests:
```bash
npm test
```

## 🏗️ Deployment

### Local Development
```bash
npm run node
npm run deploy
```

### EC2 Deployment
1. Set up your EC2 instance (t2.micro recommended for free tier)
2. Configure security groups to allow:
   - SSH (port 22)
   - RPC (port 8545)
   - P2P (port 30303)
3. Deploy to EC2:
```bash
npm run deploy:ec2
```

## 📁 Project Structure

```
GoatChain/
├── contracts/           # Smart contracts
│   ├── GoatChainToken.sol
│   ├── ArtistToken.sol
│   ├── FeeManager.sol
│   └── StakingContract.sol
├── scripts/            # Deployment scripts
│   ├── deploy.js
│   ├── deploy-ec2.js
│   └── start-ec2-node.js
├── config/            # Configuration files
├── test/             # Test files
└── hardhat.config.js # Hardhat configuration
```

## 🔧 Configuration

### Network Configuration
- Local: http://localhost:8545
- EC2: Configure in .env file

### Contract Addresses
After deployment, update your .env file with the deployed contract addresses.

## 🛠️ Development

### Adding New Features
1. Create new contract in `contracts/`
2. Write tests in `test/`
3. Add deployment script in `scripts/`
4. Update documentation

### Testing
```bash
npm test
```

## 📝 License

MIT License - See LICENSE file for details

## 👥 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 🔗 Links

- [GitHub Repository](https://github.com/GoatFoundr/GoatChain)
- [Documentation](https://docs.goatfundr.com)
- [Discord Community](https://discord.gg/goatfundr) 