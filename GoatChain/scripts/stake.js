/* eslint-disable no-console */
require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const { STAKING_CONTRACT, STAKE_AMOUNT } = process.env;
  if (!STAKING_CONTRACT || !STAKE_AMOUNT) {
    throw new Error("Please set STAKING_CONTRACT and STAKE_AMOUNT env vars");
  }

  const staking = await ethers.getContractAt("StakingRewards", STAKING_CONTRACT);
  const stakingTokenAddress = await staking.stakingToken();
  const stakingToken = await ethers.getContractAt("IERC20", stakingTokenAddress);

  const [wallet] = await ethers.getSigners();
  const amountWithDecimals = ethers.parseUnits(STAKE_AMOUNT, 18);
  const allowance = await stakingToken.allowance(wallet.address, STAKING_CONTRACT);

  if (allowance < amountWithDecimals) {
    console.log("Approving staking contract...");
    const approveTx = await stakingToken.approve(STAKING_CONTRACT, amountWithDecimals);
    await approveTx.wait();
  }

  console.log(`Staking ${STAKE_AMOUNT} tokens in ${STAKING_CONTRACT}...`);
  const tx = await staking.stake(amountWithDecimals);
  await tx.wait();
  console.log("Stake successful! Tx hash:", tx.hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 