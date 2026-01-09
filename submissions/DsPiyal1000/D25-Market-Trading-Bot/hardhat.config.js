require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks:{
    injective_testnet: {
      url: process.env.INJ_TESTNET_RPC_URL,
      accounts: process.env.PRIVATE_KEY? [process.env.PRIVATE_KEY] : [],
      chainId: 1439,
      gasPrice: 160000000,
      gas: 20000000
    },
  }
};