# GoatChain

GoatChain is a decentralized platform for artists to tokenize their content and connect with fans.

## Features

- Artist token creation and management
- Decentralized exchange for artist tokens
- Staking rewards for token holders
- Platform fees for sustainability
- Partner verification system
- Emergency functions for security

## Tokenomics

- **Token Symbol**: GOATCHAIN
- **Decimals**: 18
- **Total Supply**: 1,000,000,000 GOATCHAIN
- **Initial Supply**: 100,000,000 GOATCHAIN
- **Staking Rewards**: 200,000,000 GOATCHAIN
- **Ecosystem Fund**: 300,000,000 GOATCHAIN
- **Team Tokens**: 100,000,000 GOATCHAIN
- **Marketing**: 100,000,000 GOATCHAIN
- **Community Rewards**: 200,000,000 GOATCHAIN

## Fee Structure

- Platform Fee: 2% (capped at 4%)
- Artist Fee: 1% (capped at 2%)
- Liquidity Fee: 1%

## Security Features

- Reentrancy protection
- Pausable contracts
- Emergency functions
- Fee caps
- Partner verification
- Order expiration

## Wallet Support

- MetaMask
- Trust Wallet
- WalletConnect
- Hardware Wallets
- Mobile Wallets

## Network Configuration

```json
{
  "chainId": 1337,
  "chainName": "GoatChain",
  "nativeCurrency": {
    "name": "GoatChain",
    "symbol": "GOATCHAIN",
    "decimals": 18
  },
  "rpcUrls": ["https://rpc.goatfundr.com"],
  "blockExplorerUrls": ["https://explorer.goatfundr.com"]
}
```

## Installation

```bash
npm install
```

## Testing

```bash
npx hardhat test
```

## Deployment

```bash
npx hardhat run scripts/deploy.js --network [network]
```

## License

MIT 