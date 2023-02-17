import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-truffle5";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-web3";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import * as dotenv from "dotenv";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";
import "tsconfig-paths";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 150,
          },
        },
      },
    ],
  },
  networks: {
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/gtre32RhjQXWRjUFJ4SJfCpy4ltJrqxY",
      gas: 5000000,
      chainId: 80001,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: {
      bsc: process.env.BSC_API_KEY_PROD ? process.env.BSC_API_KEY_PROD : "",
      bscTestnet: process.env.BSC_API_KEY ? process.env.BSC_API_KEY : "",
      avalanche: process.env.SNOWTRACE_API_KEY_PROD
        ? process.env.SNOWTRACE_API_KEY_PROD
        : "",
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY
        ? process.env.SNOWTRACE_API_KEY
        : "",
      polygonMumbai: process.env.MUMBAI_API_KEY
        ? process.env.MUMBAI_API_KEY
        : "",
    },
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 50000,
  },
};

export default config;
