const hre = require("hardhat");

async function main() {
  console.log("Deploying GoatChain contracts...");

  // Deploy GoatToken
  console.log("Deploying GoatToken...");
  const GoatToken = await hre.ethers.getContractFactory("GoatToken");
  const goatToken = await GoatToken.deploy();
  await goatToken.waitForDeployment();
  console.log("GoatToken deployed to:", await goatToken.getAddress());

  // Deploy GoatLiquidityPool
  console.log("Deploying GoatLiquidityPool...");
  const GoatLiquidityPool = await hre.ethers.getContractFactory("GoatLiquidityPool");
  const goatLiquidityPool = await GoatLiquidityPool.deploy(await goatToken.getAddress());
  await goatLiquidityPool.waitForDeployment();
  console.log("GoatLiquidityPool deployed to:", await goatLiquidityPool.getAddress());

  // Set liquidity pool in GoatToken
  console.log("Setting liquidity pool in GoatToken...");
  await goatToken.setLiquidityPool(await goatLiquidityPool.getAddress());
  console.log("Liquidity pool set successfully");

  // Deploy ArtistTokenFactory
  console.log("Deploying ArtistTokenFactory...");
  const ArtistTokenFactory = await hre.ethers.getContractFactory("ArtistTokenFactory");
  const artistTokenFactory = await ArtistTokenFactory.deploy();
  await artistTokenFactory.waitForDeployment();
  console.log("ArtistTokenFactory deployed to:", await artistTokenFactory.getAddress());

  // Deploy GoatStaking
  console.log("Deploying GoatStaking...");
  const GoatStaking = await hre.ethers.getContractFactory("GoatStaking");
  const goatStaking = await GoatStaking.deploy();
  await goatStaking.waitForDeployment();
  console.log("GoatStaking deployed to:", await goatStaking.getAddress());

  console.log("\nDeployment Summary:");
  console.log("-------------------");
  console.log("GoatToken:", await goatToken.getAddress());
  console.log("GoatLiquidityPool:", await goatLiquidityPool.getAddress());
  console.log("ArtistTokenFactory:", await artistTokenFactory.getAddress());
  console.log("GoatStaking:", await goatStaking.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 