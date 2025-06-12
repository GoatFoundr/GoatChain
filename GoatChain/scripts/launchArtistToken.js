/* eslint-disable no-console */
require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const { ARTIST_WALLET, TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY } = process.env;
  if (!ARTIST_WALLET || !TOKEN_NAME || !TOKEN_SYMBOL || !INITIAL_SUPPLY) {
    throw new Error("Please set ARTIST_WALLET, TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY env vars");
  }

  const artistRegistryAddress = process.env.ARTIST_REGISTRY;
  if (!artistRegistryAddress) throw new Error("Please set ARTIST_REGISTRY env var to deployed registry address");

  const registry = await ethers.getContractAt("ArtistRegistry", artistRegistryAddress);
  const tx = await registry.registerArtist(TOKEN_NAME, TOKEN_SYMBOL, ARTIST_WALLET, ethers.parseUnits(INITIAL_SUPPLY, 18));
  console.log("Registering artist token ...");
  const receipt = await tx.wait();
  const event = receipt.logs.find((log) => log.topics[0] === registry.interface.getEvent("ArtistRegistered").topicHash);
  if (event) {
    const decoded = registry.interface.decodeEventLog("ArtistRegistered", event.data, event.topics);
    console.log("Artist token deployed at", decoded.token);
  } else {
    console.log("Artist token deployed (event not parsed). Tx hash:", tx.hash);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 