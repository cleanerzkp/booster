import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import { nodeUrl, accounts } from "@solarprotocol/hardhat-utils";

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const { getNamedAccounts, getUnnamedAccounts } = hre;

  console.log("Named", await getNamedAccounts());
  console.log("Unnamed", await getUnnamedAccounts());
});

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
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
    },
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
      gas: "auto",
      tags: ["test", "local"],
      saveDeployments: false,
    },
    localhost: {
      url: nodeUrl("localhost"),
      accounts: accounts("localhost"),
      tags: ["test", "local"],
      gas: "auto",
    },
    fuji: {
      live: true,
      chainId: 43113,
      url: nodeUrl("fuji"),
      accounts: accounts("fuji"),
      tags: ["staging"],
      verify: {
        etherscan: {
          apiKey: process.env.SNOWTRACE_API_KEY,
        },
      },
    },
    ftmTestnet: {
      live: true,
      chainId: 4002,
      url: nodeUrl("ftmTestnet"),
      accounts: accounts("ftmTestnet"),
      tags: ["staging"],
      gas: "auto",
      verify: {
        etherscan: {
          apiKey: process.env.FTMSCAN_API_KEY,
        },
      },
    },
    opera: {
      live: true,
      chainId: 250,
      url: nodeUrl("opera"),
      accounts: accounts("opera"),
      tags: ["production"],
      verify: {
        etherscan: {
          apiKey: process.env.FTMSCAN_API_KEY,
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
    tenderly: {
      live: true,
      chainId: 250,
      url: nodeUrl("tenderly"),
      accounts: accounts("tenderly"),
      tags: ["test"],
    },
  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS as unknown as boolean) || false,
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
  contractSizer: {},
};

export default config;
