require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    injective_testnet: {
      url: 'https://k8s.testnet.json-rpc.injective.network',
      chainId: 1439,  // Chain ID officiel pour le testnet Injective
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 60000,
      httpHeaders: {
        'accept': 'application/json',
        'content-type': 'application/json'
      },
      gas: 8000000,
      gasPrice: 500000000,  // 0.5 Gwei
      gasMultiplier: 1.5
    }
  },
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test"
  },
  mocha: {
    timeout: 100000
  }
};
