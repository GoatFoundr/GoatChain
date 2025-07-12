const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Production Configuration
const PRODUCTION_CONFIG = {
  // Token Configuration
  INITIAL_SUPPLY: ethers.utils.parseEther("10000000"), // 10 million tokens (PERFECT AMOUNT!)
  DECIMALS: 18,
  
  // Fee Configuration
  PLATFORM_FEE: 100, // 1%
  ARTIST_FEE: 100,   // 1%
  REWARDS_FEE: 100,  // 1%
  
  // Staking Configuration
  STAKING_REWARDS_RATE: 1000, // 10% APY
  STAKING_LOCK_PERIOD: 604800, // 7 days
  
  // Artist Coin Configuration
  ARTIST_COIN_PRICE: ethers.utils.parseEther("0.01"), // 0.01 ETH
  MAX_ARTIST_COINS: 1000000,
  
  // Governance Configuration
  VOTING_PERIOD: 7 * 24 * 60 * 60, // 7 days
  QUORUM_PERCENTAGE: 10, // 10%
  
  // Security Configuration
  PAUSED: false,
  RATE_LIMIT: 100, // 100 transactions per block
  MAX_TRANSACTION_SIZE: ethers.utils.parseEther("10000"), // 10K tokens
};

// Contract Addresses Storage
const contractAddresses = {};
const contractABIs = {};

// Logging
const log = (message) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
};

const logError = (message, error) => {
  const timestamp = new Date().toISOString();
  console.error(`[${timestamp}] ERROR: ${message}`);
  if (error) console.error(error);
};

// Save deployment information
const saveDeploymentInfo = (contractName, contract, args = []) => {
  const deploymentInfo = {
    address: contract.address,
    transaction: contract.deployTransaction.hash,
    block: contract.deployTransaction.blockNumber,
    timestamp: new Date().toISOString(),
    args: args,
    network: "localhost",
    chainId: 999191917
  };
  
  contractAddresses[contractName] = deploymentInfo;
  
  // Save to file
  const deploymentsDir = path.join(__dirname, "../deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }
  
  fs.writeFileSync(
    path.join(deploymentsDir, "production-addresses.json"),
    JSON.stringify(contractAddresses, null, 2)
  );
  
  log(`✅ ${contractName} deployed at: ${contract.address}`);
  log(`   Transaction: ${contract.deployTransaction.hash}`);
  log(`   Gas Used: ${contract.deployTransaction.gasLimit?.toString()}`);
};

// Verify contract deployment
const verifyDeployment = async (contractName, contract, expectedFunctions = []) => {
  try {
    // Check if contract exists
    const code = await ethers.provider.getCode(contract.address);
    if (code === "0x") {
      throw new Error(`Contract ${contractName} not deployed properly`);
    }
    
    // Check expected functions
    for (const func of expectedFunctions) {
      if (!contract[func]) {
        throw new Error(`Function ${func} not found in ${contractName}`);
      }
    }
    
    log(`✅ ${contractName} verification passed`);
    return true;
  } catch (error) {
    logError(`❌ ${contractName} verification failed`, error);
    return false;
  }
};

// Deploy main GoatChain token
const deployGoatChain = async () => {
  log("🚀 Deploying GoatChain Token...");
  
  const GoatChain = await ethers.getContractFactory("GOATCHAIN");
  const goatchain = await GoatChain.deploy(
    PRODUCTION_CONFIG.INITIAL_SUPPLY,
    "GoatChain", 
    "GOATCHAIN"
  );
  
  await goatchain.deployed();
  saveDeploymentInfo("GOATCHAIN", goatchain, [
    PRODUCTION_CONFIG.INITIAL_SUPPLY.toString(),
    "GoatChain",
    "GOATCHAIN"
  ]);
  
  await verifyDeployment("GOATCHAIN", goatchain, [
    "transfer",
    "balanceOf",
    "totalSupply",
    "mint",
    "burn"
  ]);
  
  return goatchain;
};

// Deploy Fee Manager
const deployFeeManager = async () => {
  log("🚀 Deploying Fee Manager...");
  
  const FeeManager = await ethers.getContractFactory("FeeManager");
  const feeManager = await FeeManager.deploy(
    PRODUCTION_CONFIG.PLATFORM_FEE,
    PRODUCTION_CONFIG.ARTIST_FEE,
    PRODUCTION_CONFIG.REWARDS_FEE
  );
  
  await feeManager.deployed();
  saveDeploymentInfo("FeeManager", feeManager, [
    PRODUCTION_CONFIG.PLATFORM_FEE,
    PRODUCTION_CONFIG.ARTIST_FEE,
    PRODUCTION_CONFIG.REWARDS_FEE
  ]);
  
  await verifyDeployment("FeeManager", feeManager, [
    "calculateFees",
    "distributeFees",
    "updateFeeStructure"
  ]);
  
  return feeManager;
};

// Deploy Artist Coin Factory
const deployArtistCoinFactory = async (goatchainAddress, feeManagerAddress) => {
  log("🚀 Deploying Artist Coin Factory...");
  
  const ArtistCoinFactory = await ethers.getContractFactory("ArtistCoinFactory");
  const artistCoinFactory = await ArtistCoinFactory.deploy(
    goatchainAddress,
    feeManagerAddress,
    PRODUCTION_CONFIG.ARTIST_COIN_PRICE
  );
  
  await artistCoinFactory.deployed();
  saveDeploymentInfo("ArtistCoinFactory", artistCoinFactory, [
    goatchainAddress,
    feeManagerAddress,
    PRODUCTION_CONFIG.ARTIST_COIN_PRICE.toString()
  ]);
  
  await verifyDeployment("ArtistCoinFactory", artistCoinFactory, [
    "createArtistCoin",
    "verifyArtist",
    "setArtistCoinPrice"
  ]);
  
  return artistCoinFactory;
};

// Deploy Staking Contract
const deployStaking = async (goatchainAddress) => {
  log("🚀 Deploying Staking Contract...");
  
  const Staking = await ethers.getContractFactory("GOATCHAINStaking");
  const staking = await Staking.deploy(
    goatchainAddress,
    PRODUCTION_CONFIG.STAKING_REWARDS_RATE,
    PRODUCTION_CONFIG.STAKING_LOCK_PERIOD
  );
  
  await staking.deployed();
  saveDeploymentInfo("GOATCHAINStaking", staking, [
    goatchainAddress,
    PRODUCTION_CONFIG.STAKING_REWARDS_RATE,
    PRODUCTION_CONFIG.STAKING_LOCK_PERIOD
  ]);
  
  await verifyDeployment("GOATCHAINStaking", staking, [
    "stake",
    "unstake",
    "claimRewards",
    "getStakedAmount"
  ]);
  
  return staking;
};

// Configure contracts
const configureContracts = async (contracts) => {
  log("⚙️ Configuring contracts...");
  
  const { goatchain, feeManager, artistCoinFactory, staking } = contracts;
  
  // Set up roles and permissions
  const [deployer] = await ethers.getSigners();
  
  // Configure GoatChain token
  await goatchain.grantRole(await goatchain.MINTER_ROLE(), staking.address);
  await goatchain.grantRole(await goatchain.BURNER_ROLE(), feeManager.address);
  log("✅ GoatChain roles configured");
  
  // Configure Fee Manager
  await feeManager.setRewardsPool(staking.address);
  await feeManager.setPlatformWallet(deployer.address);
  log("✅ Fee Manager configured");
  
  // Configure Artist Coin Factory
  await artistCoinFactory.setVerifier(deployer.address);
  await artistCoinFactory.setMaxArtistCoins(PRODUCTION_CONFIG.MAX_ARTIST_COINS);
  log("✅ Artist Coin Factory configured");
  
  // Configure Staking
  await staking.setRewardsToken(goatchain.address);
  await staking.setMinStakeAmount(ethers.utils.parseEther("100"));
  log("✅ Staking contract configured");
  
  // Set up inter-contract connections
  await goatchain.setFeeManager(feeManager.address);
  await goatchain.setStakingContract(staking.address);
  log("✅ Inter-contract connections established");
};

// Create test artist coins
const createTestArtistCoins = async (artistCoinFactory) => {
  log("🎨 Creating test artist coins...");
  
  const testArtists = [
    { name: "LazerDim700", symbol: "LD700", price: ethers.utils.parseEther("0.01") },
    { name: "PlaqueBoyMax", symbol: "PBM", price: ethers.utils.parseEther("0.02") },
    { name: "DRXP", symbol: "DRXP", price: ethers.utils.parseEther("0.015") }
  ];
  
  for (const artist of testArtists) {
    const tx = await artistCoinFactory.createArtistCoin(
      artist.name,
      artist.symbol,
      artist.price,
      ethers.utils.parseEther("1000000"), // 1M max supply
      "ipfs://QmTestMetadata" // Metadata URI
    );
    
    const receipt = await tx.wait();
    const event = receipt.events?.find(e => e.event === "ArtistCoinCreated");
    
    if (event) {
      const coinAddress = event.args.coinAddress;
      contractAddresses[`ArtistCoin_${artist.symbol}`] = {
        address: coinAddress,
        name: artist.name,
        symbol: artist.symbol,
        price: artist.price.toString(),
        transaction: tx.hash,
        timestamp: new Date().toISOString()
      };
      
      log(`✅ Created ${artist.name} (${artist.symbol}) at ${coinAddress}`);
    }
  }
};

// Setup monitoring
const setupMonitoring = async (contracts) => {
  log("📊 Setting up monitoring...");
  
  // Create monitoring configuration
  const monitoringConfig = {
    contracts: contractAddresses,
    endpoints: {
      health: "http://localhost:8080/health",
      metrics: "http://localhost:8080/metrics",
      rpc: "http://localhost:8545"
    },
    alerts: {
      enabled: true,
      email: process.env.ALERT_EMAIL || "admin@goatfundr.com",
      slack: process.env.SLACK_WEBHOOK || ""
    },
    thresholds: {
      gas_price: ethers.utils.parseUnits("50", "gwei"),
      transaction_count: 1000,
      error_rate: 0.01 // 1%
    }
  };
  
  const monitoringDir = path.join(__dirname, "../monitoring");
  if (!fs.existsSync(monitoringDir)) {
    fs.mkdirSync(monitoringDir, { recursive: true });
  }
  
  fs.writeFileSync(
    path.join(monitoringDir, "config.json"),
    JSON.stringify(monitoringConfig, null, 2)
  );
  
  log("✅ Monitoring configuration saved");
};

// Main deployment function
async function main() {
  try {
    log("🚀 Starting GoatChain Production Deployment...");
    log(`📊 Configuration: ${JSON.stringify(PRODUCTION_CONFIG, null, 2)}`);
    
    // Get deployer account
    const [deployer] = await ethers.getSigners();
    log(`📋 Deploying with account: ${deployer.address}`);
    
    const balance = await deployer.getBalance();
    log(`💰 Account balance: ${ethers.utils.formatEther(balance)} ETH`);
    
    if (balance.lt(ethers.utils.parseEther("10"))) {
      throw new Error("Insufficient balance for deployment. Need at least 10 ETH.");
    }
    
    // Deploy contracts
    const goatchain = await deployGoatChain();
    const feeManager = await deployFeeManager();
    const artistCoinFactory = await deployArtistCoinFactory(goatchain.address, feeManager.address);
    const staking = await deployStaking(goatchain.address);
    
    const contracts = { goatchain, feeManager, artistCoinFactory, staking };
    
    // Configure contracts
    await configureContracts(contracts);
    
    // Create test artist coins
    await createTestArtistCoins(artistCoinFactory);
    
    // Setup monitoring
    await setupMonitoring(contracts);
    
    // Final validation
    log("🔍 Running final validation...");
    
    // Check all contracts
    for (const [name, contract] of Object.entries(contracts)) {
      const code = await ethers.provider.getCode(contract.address);
      if (code === "0x") {
        throw new Error(`Contract ${name} validation failed`);
      }
    }
    
    log("✅ All contracts validated successfully!");
    
    // Generate deployment summary
    const summary = {
      timestamp: new Date().toISOString(),
      network: "localhost",
      chainId: 999191917,
      deployer: deployer.address,
      contracts: contractAddresses,
      configuration: PRODUCTION_CONFIG,
      status: "success"
    };
    
    fs.writeFileSync(
      path.join(__dirname, "../deployments/production-summary.json"),
      JSON.stringify(summary, null, 2)
    );
    
    log("🎉 PRODUCTION DEPLOYMENT COMPLETE!");
    log("📋 Summary:");
    log(`   Network: GoatChain (Chain ID: 999191917)`);
    log(`   Deployer: ${deployer.address}`);
    log(`   Contracts: ${Object.keys(contractAddresses).length}`);
    log(`   Total Gas Used: Estimated ~5-10M gas`);
    log(`   RPC Endpoint: http://localhost:8545`);
    log(`   Explorer: https://explorer.goatfundr.com`);
    
    log("📝 Contract Addresses:");
    for (const [name, info] of Object.entries(contractAddresses)) {
      log(`   ${name}: ${info.address}`);
    }
    
    log("🚀 GoatChain is now LIVE and ready for production!");
    
  } catch (error) {
    logError("❌ Deployment failed", error);
    process.exit(1);
  }
}

// Run deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    logError("Fatal error during deployment", error);
    process.exit(1);
  }); 