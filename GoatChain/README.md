# GoatChain

GoatChain is a standalone EVM-compatible blockchain purpose-built for trusted artist token launches, staking and community engagement.

## Key Facts

* **Chain ID:** 1338
* **RPC:** https://rpc2.goatfundr.com
* **Symbol:** GOATCHAIN
* **Client:** Nethermind
* **Primary Wallets:** MetaMask, TrustWallet, Rainbow, Coinbase Wallet & any WalletConnect wallet.

## Tokenomics

| Bucket                     | Allocation |
|----------------------------|------------|
| Artist Partnerships        | 400 M (40%)|
| Platform Development       | 200 M (20%)|
| Community Incentives       | 200 M (20%)|
| Team (2-year vesting)      | 100 M (10%)|
| Liquidity & Market Making  | 100 M (10%)|

Total supply: **1 B GOATCHAIN**

## Folder Structure

```
.
├── contracts        # Solidity sources (upgradeable)
├── scripts          # Hardhat helper & deployment scripts
├── test             # Mocha/Chai tests (TBD)
├── hardhat.config.js
└── package.json
```

## Set-up

```bash
# 1. Install deps (Node.js ≥16 required)
npm install

# 2. Copy .env.example -> .env and fill PRIVATE_KEY etc.

# 3. Compile contracts
npm run compile

# 4. Deploy core on GoatChain network
npm run deploy
```

## Launching an Artist Token

```bash
ARTIST_REGISTRY=<deployed_registry>
ARTIST_WALLET=0x...
TOKEN_NAME="Awesome Artist Token"
TOKEN_SYMBOL=ARTIST
INITIAL_SUPPLY=1000000
npx hardhat run scripts/launchArtistToken.js --network goatchain
```

## Staking

```bash
STAKING_CONTRACT=<staking_contract>
STAKE_AMOUNT=1000
npx hardhat run scripts/stake.js --network goatchain
```

## Security

* All contracts are upgradeable via UUPS proxies.
* OpenZeppelin libraries: OwnableUpgradeable, ERC20Upgradeable, VestingWallet, etc.
* Fee caps enforced in `FeeManager`.
* Events emitted for all critical actions.

Prepared for third-party audit (e.g. CertiK).

