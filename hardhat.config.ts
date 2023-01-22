import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import "hardhat-ignore-warnings";
import "hardhat-abi-exporter";
import { nodeUrl, accounts } from "@solarprotocol/hardhat-utils";
/*
import * as tdly from "@tenderly/hardhat-tenderly";
tdly.setup({
  automaticVerifications: false,
});
/**/

import "./tasks/accounts";
import "./tasks/locks";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999,
      },
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    owner: {
      default: 1,
      localhost: "0xe56A248C316172D71238a30EbE936cD50bC91dcc",
      bsc: "0xe56A248C316172D71238a30EbE936cD50bC91dcc",
      bscTest: "0xF6c9eBd49C948888B921F150b03cF63a7Ab58a3A",
    },
    treasury: {
      default: 2,
      bsc: "0x09663794Fa898d3b2F6613D2732E7d998C276aFD",
    },
    aprManager: {
      default: "0xd07623eca042941d42c2eAf689759DF895550748",
    },
    router: "0x9fd7764e2303e7748736d115304350ec64e403b2",
  },
  networks: {
    hardhat: {
      // process.env.HARDHAT_FORK will specify the network that the fork is made from.
      // this line ensure the use of the corresponding accounts
      accounts: accounts(process.env.HARDHAT_FORK),
      forking: process.env.HARDHAT_FORK
        ? {
            url: nodeUrl(process.env.HARDHAT_FORK),
            blockNumber: process.env.HARDHAT_FORK_BLOCK
              ? parseInt(process.env.HARDHAT_FORK_BLOCK)
              : undefined,
          }
        : undefined,
      //gas: "auto",
      gas: 3e7,
      tags: ["test", "local"],
      saveDeployments: false,
    },
    localhost: {
      url: nodeUrl("localhost"),
      accounts: accounts("localhost"),
      tags: ["test", "local"],
      gas: "auto",
      saveDeployments: true,
    },
    bsc: {
      live: true,
      chainId: 56,
      url: nodeUrl("bsc"),
      accounts: accounts("bsc"),
      tags: ["production"],
      verify: {
        etherscan: {
          apiKey: process.env.BSCSCAN_API_KEY,
        },
      },
    },
    bscTest: {
      live: true,
      chainId: 56,
      url: nodeUrl("bsc"),
      accounts: accounts("bsc"),
      tags: ["production", "test"],
      verify: {
        etherscan: {
          apiKey: process.env.BSCSCAN_API_KEY,
        },
      },
    },
    operaTest: {
      live: true,
      chainId: 250,
      url: nodeUrl("opera"),
      accounts: accounts("opera"),
      tags: ["production", "test"],
      verify: {
        etherscan: {
          apiKey: process.env.FTMSCAN_API_KEY,
        },
      },
    },
  },
  abiExporter: {
    runOnCompile: true,
    clear: true,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS == "true" ? true : false,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    currency: process.env.GAS_REPORTER_CURRENCY || undefined,
    token: process.env.GAS_REPORTER_TOKEN || undefined,
    gasPriceApi: process.env.GAS_REPORTER_PRICE_API || undefined,
  },
  etherscan: {
    apiKey: {
      opera: process.env.FTMSCAN_API_KEY as string,
      ftmTestnet: process.env.FTMSCAN_API_KEY as string,
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY as string,
    },
  },
  contractSizer: {
    alphaSort: false,
    runOnCompile: false,
    disambiguatePaths: false,
    except: ["^.*Mock$"],
  },
  mocha: {
    timeout: 4000000,
  },
  /*
  tenderly: {
    project: "project",
    username: "0xFluffyBeard",
    forkNetwork: "opera",
    privateVerification: true,
  },
  /**/
};

export default config;
