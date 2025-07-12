const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Deploying GoatChain to production...");

  // Load environment variables
  const rpcUrl = process.env.RPC_URL || "http://localhost:8545";
  const wsUrl = process.env.WS_URL || "ws://localhost:8546";
  const allowedOrigins = process.env.ALLOWED_ORIGINS || "https://yourdomain.com";

  console.log("Using RPC URL:", rpcUrl);
  console.log("Using WebSocket URL:", wsUrl);

  // Verify chain ID
  const network = await ethers.provider.getNetwork();
  if (network.chainId !== 999191917) {
    throw new Error(`Invalid chain ID. Expected 999191917, got ${network.chainId}`);
  }
  console.log("✅ Connected to chain ID:", network.chainId);

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.utils.formatEther(await deployer.getBalance()));

  // Deploy FeeManager first
  console.log("\n📦 Deploying FeeManager...");
  const FeeManager = await ethers.getContractFactory("FeeManager");
  const feeManager = await FeeManager.deploy(deployer.address, deployer.address);
  await feeManager.deployed();
  console.log("✅ FeeManager deployed to:", feeManager.address);

  // Deploy GOATCHAIN Token with FeeManager
  console.log("\n📦 Deploying GOATCHAIN Token...");
  const GoatChainToken = await ethers.getContractFactory("GoatChainToken");
  const goatChainToken = await GoatChainToken.deploy(feeManager.address);
  await goatChainToken.deployed();
  console.log("✅ GOATCHAIN Token deployed to:", goatChainToken.address);

  // Deploy LAZERDIM700 Token with FeeManager
  console.log("\n📦 Deploying LAZERDIM700 Token...");
  const LazerDimToken = await ethers.getContractFactory("LazerDimToken");
  const lazerDimToken = await LazerDimToken.deploy(feeManager.address);
  await lazerDimToken.deployed();
  console.log("✅ LAZERDIM700 Token deployed to:", lazerDimToken.address);

  // Deploy Staking Contract
  console.log("\n📦 Deploying Staking Contract...");
  const StakingContract = await ethers.getContractFactory("StakingContract");
  const stakingContract = await StakingContract.deploy(
    goatChainToken.address,
    feeManager.address
  );
  await stakingContract.deployed();
  console.log("✅ Staking Contract deployed to:", stakingContract.address);

  console.log("\n✅ All contracts deployed successfully!");

  // Save deployment addresses
  const deploymentInfo = {
    network: {
      chainId: network.chainId,
      rpcUrl: rpcUrl,
      wsUrl: wsUrl,
      allowedOrigins: allowedOrigins
    },
    contracts: {
      feeManager: feeManager.address,
      goatChainToken: goatChainToken.address,
      lazerDimToken: lazerDimToken.address,
      stakingContract: stakingContract.address
    },
    deploymentTime: new Date().toISOString(),
    deployer: deployer.address
  };

  fs.writeFileSync(
    path.join(__dirname, "../deployment-info.json"),
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log("\n🎉 Deployment complete!");
  console.log("🌐 Network RPC URL:", rpcUrl);
  console.log("🌐 Network WebSocket URL:", wsUrl);
  console.log("📋 Contract addresses saved to deployment-info.json");
  console.log("\n📝 Next steps:");
  console.log("1. Point your domain to your EC2 instance");
  console.log("2. Set up SSL certificate for HTTPS");
  console.log("3. Configure your frontend to use the new domain");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }); 