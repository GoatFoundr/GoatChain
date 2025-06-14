const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Deploying GoatChain to EC2 instance...");

  // Load node configuration
  const configPath = path.join(__dirname, "../config/node-config.json");
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

  // Verify chain ID
  const network = await ethers.provider.getNetwork();
  if (network.chainId !== 999191917) {
    throw new Error(`Invalid chain ID. Expected 999191917, got ${network.chainId}`);
  }
  console.log("Connected to chain ID:", network.chainId);

  // Deploy FeeManager first
  const FeeManager = await ethers.getContractFactory("FeeManager");
  const feeManager = await FeeManager.deploy();
  await feeManager.deployed();
  console.log("FeeManager deployed to:", feeManager.address);

  // Deploy GOATCHAIN Token with FeeManager
  const GoatChainToken = await ethers.getContractFactory("GoatChainToken");
  const goatChainToken = await GoatChainToken.deploy(feeManager.address);
  await goatChainToken.deployed();
  console.log("GOATCHAIN Token deployed to:", goatChainToken.address);

  // Deploy LAZERDIM700 Token with FeeManager
  const LazerDimToken = await ethers.getContractFactory("LazerDimToken");
  const lazerDimToken = await LazerDimToken.deploy(feeManager.address);
  await lazerDimToken.deployed();
  console.log("LAZERDIM700 Token deployed to:", lazerDimToken.address);

  // Deploy Staking Contract
  const StakingContract = await ethers.getContractFactory("StakingContract");
  const stakingContract = await StakingContract.deploy(
    goatChainToken.address,
    feeManager.address
  );
  await stakingContract.deployed();
  console.log("Staking Contract deployed to:", stakingContract.address);

  // Initialize FeeManager with contract addresses
  await feeManager.initialize(
    goatChainToken.address,
    lazerDimToken.address,
    stakingContract.address
  );
  console.log("FeeManager initialized with contract addresses");

  // Save deployment addresses
  const deploymentInfo = {
    network: {
      chainId: network.chainId,
      rpcUrl: config.network.rpcUrl,
      wsUrl: config.network.wsUrl
    },
    contracts: {
      feeManager: feeManager.address,
      goatChainToken: goatChainToken.address,
      lazerDimToken: lazerDimToken.address,
      stakingContract: stakingContract.address
    },
    deploymentTime: new Date().toISOString()
  };

  fs.writeFileSync(
    path.join(__dirname, "../deployment-info.json"),
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log("\nDeployment complete! ✅");
  console.log("Network RPC URL:", config.network.rpcUrl);
  console.log("Network WebSocket URL:", config.network.wsUrl);
  console.log("\nContract addresses have been saved to deployment-info.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 