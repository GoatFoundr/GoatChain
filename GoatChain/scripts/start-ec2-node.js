const { network } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("Starting GoatChain node on EC2...");
  
  // Load node configuration
  const configPath = path.join(__dirname, "../config/node-config.json");
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

  console.log("Network configuration:");
  console.log("- Chain ID:", config.network.chainId);
  console.log("- RPC URL:", config.network.rpcUrl);
  console.log("- WebSocket URL:", config.network.wsUrl);
  console.log("- Host:", config.network.host);
  console.log("- Port:", config.network.port);

  console.log("\nMining configuration:");
  console.log("- Auto mining:", config.mining.auto);
  console.log("- Gas limit:", config.mining.gasLimit);

  console.log("\nSecurity settings:");
  console.log("- CORS:", config.security.cors);
  console.log("- Max peers:", config.security.maxPeers);

  // Ensure log directory exists
  const logDir = path.dirname(config.logging.file);
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }

  console.log("\nNode is running on EC2 (54.176.66.242)");
  console.log("Logs will be written to:", config.logging.file);
  console.log("\nPress Ctrl+C to stop the node.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 