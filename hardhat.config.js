require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 999191917,
      gas: 8000000,
      gasPrice: 20000000000,
      blockGasLimit: 8000000,
      mining: {
        auto: true,
        interval: 15000
      },
      accounts: {
        mnemonic: process.env.MNEMONIC || "test test test test test test test test test test test junk",
        count: 10,
        accountsBalance: "10000000000000000000000"
      }
    },
    production: {
      url: process.env.RPC_URL || "http://localhost:8545",
      accounts: {
        mnemonic: process.env.MNEMONIC || "test test test test test test test test test test test junk"
      },
      chainId: 999191917,
      gas: 8000000,
      gasPrice: 20000000000,
      timeout: 60000
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD"
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  mocha: {
    timeout: 40000
  }
}; 