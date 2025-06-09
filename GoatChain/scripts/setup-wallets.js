const { ethers } = require("hardhat");

async function main() {
  console.log("Setting up wallet configurations...");

  // Network configuration for different wallets
  const networkConfig = {
    chainId: 1337,
    chainName: "GoatChain",
    nativeCurrency: {
      name: "GoatChain",
      symbol: "GOATCHAIN",
      decimals: 18
    },
    rpcUrls: ["https://rpc.goatfundr.com"],
    blockExplorerUrls: ["https://explorer.goatfundr.com"]
  };

  // MetaMask configuration
  console.log("\nMetaMask Configuration:");
  console.log("1. Open MetaMask");
  console.log("2. Click 'Add Network'");
  console.log("3. Enter the following details:");
  console.log(`   - Network Name: ${networkConfig.chainName}`);
  console.log(`   - RPC URL: ${networkConfig.rpcUrls[0]}`);
  console.log(`   - Chain ID: ${networkConfig.chainId}`);
  console.log(`   - Currency Symbol: ${networkConfig.nativeCurrency.symbol}`);
  console.log(`   - Block Explorer URL: ${networkConfig.blockExplorerUrls[0]}`);

  // Trust Wallet configuration
  console.log("\nTrust Wallet Configuration:");
  console.log("1. Open Trust Wallet");
  console.log("2. Go to Settings > Networks");
  console.log("3. Add Custom Network with the same details as above");

  // WalletConnect configuration
  console.log("\nWalletConnect Configuration:");
  console.log("1. Use the following network details in your dApp:");
  console.log(JSON.stringify(networkConfig, null, 2));

  // Token configuration
  console.log("\nToken Configuration:");
  console.log("After deployment, add the following token to your wallet:");
  console.log("1. Click 'Add Token'");
  console.log("2. Enter the GoatToken contract address");
  console.log("3. Symbol: GOATCHAIN");
  console.log("4. Decimals: 18");

  // Security recommendations
  console.log("\nSecurity Recommendations:");
  console.log("1. Always verify contract addresses");
  console.log("2. Use hardware wallets for large amounts");
  console.log("3. Never share your private keys");
  console.log("4. Enable transaction signing notifications");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 