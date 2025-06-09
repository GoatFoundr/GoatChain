const hre = require("hardhat");

async function main() {
  console.log("Verifying GoatChain contracts...");

  // Verify GoatToken
  try {
    await hre.run("verify:verify", {
      address: process.env.GOAT_TOKEN_ADDRESS,
      constructorArguments: [],
    });
    console.log("GoatToken verified");
  } catch (error) {
    console.log("GoatToken verification failed:", error);
  }

  // Verify GoatFeeCollector
  try {
    await hre.run("verify:verify", {
      address: process.env.FEE_COLLECTOR_ADDRESS,
      constructorArguments: [],
    });
    console.log("GoatFeeCollector verified");
  } catch (error) {
    console.log("GoatFeeCollector verification failed:", error);
  }

  // Verify GoatExchange
  try {
    await hre.run("verify:verify", {
      address: process.env.EXCHANGE_ADDRESS,
      constructorArguments: [],
    });
    console.log("GoatExchange verified");
  } catch (error) {
    console.log("GoatExchange verification failed:", error);
  }

  // Verify GoatStaking
  try {
    await hre.run("verify:verify", {
      address: process.env.STAKING_ADDRESS,
      constructorArguments: [],
    });
    console.log("GoatStaking verified");
  } catch (error) {
    console.log("GoatStaking verification failed:", error);
  }

  // Verify GoatRewards
  try {
    await hre.run("verify:verify", {
      address: process.env.REWARDS_ADDRESS,
      constructorArguments: [],
    });
    console.log("GoatRewards verified");
  } catch (error) {
    console.log("GoatRewards verification failed:", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 