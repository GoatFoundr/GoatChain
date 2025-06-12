/* eslint-disable no-console */
require("dotenv").config();
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with", deployer.address);

  // 1. Deploy GOATCHAIN token (UUPS)
  const GoatToken = await ethers.getContractFactory("GoatToken");
  const goatToken = await upgrades.deployProxy(GoatToken, [deployer.address], { kind: "uups" });
  await goatToken.deployed();
  console.log("GoatToken deployed at", goatToken.address);

  // 2. Deploy ArtistToken implementation (logic only, no proxy)
  const ArtistToken = await ethers.getContractFactory("ArtistToken");
  const artistTokenImpl = await ArtistToken.deploy();
  await artistTokenImpl.deployed();
  console.log("ArtistToken implementation deployed at", artistTokenImpl.address);

  // 3. Deploy ArtistRegistry (UUPS) with implementation address
  const ArtistRegistry = await ethers.getContractFactory("ArtistRegistry");
  const artistRegistry = await upgrades.deployProxy(ArtistRegistry, [artistTokenImpl.address], { kind: "uups" });
  await artistRegistry.deployed();
  console.log("ArtistRegistry deployed at", artistRegistry.address);

  // 4. Deploy FeeManager (UUPS) with platform & rewards addresses set to deployer for now
  const FeeManager = await ethers.getContractFactory("FeeManager");
  const feeManager = await upgrades.deployProxy(FeeManager, [deployer.address, deployer.address], { kind: "uups" });
  await feeManager.deployed();
  console.log("FeeManager deployed at", feeManager.address);

  console.log("Deployment complete ✅");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 