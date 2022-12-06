import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { basename } from "path";
import { ethers } from "ethers";
import { MasterChefNewPoolInfo } from "../utils/types";

const START_BLOCK_NUMBER = 23707200;

const newFarms: MasterChefNewPoolInfo[] = [
  {
    lp: "0xA1F93348A691C371280bb33C1c7B66Bc1f978f47",
    lpName: "USDC-BUSD",
    allocPoint: 4405286344,
    isRegular: true,
  },
  {
    lp: "0x84Fe65e20c1Bb96F7c6f317c09de85Ba99114B73",
    lpName: "WBNB-BUSD",
    allocPoint: 9911894273,
    isRegular: true,
  },
  {
    lp: "0xDBa70124CF5BE4f83d1C386E2e3baf9EE3276c9C",
    lpName: "BTCB-BUSD",
    allocPoint: 5506607930,
    isRegular: true,
  },
  {
    lp: "0x47d941611Ac667CB7eaC2a2e1fd5848C8C15Bfd8",
    lpName: "ETH-BUSD",
    allocPoint: 6607929515,
    isRegular: true,
  },
  {
    lp: "0xdeaa71F53B25E01A77c8c60c0d4a9F4c00A5FB4c",
    lpName: "XRP-BUSD",
    allocPoint: 6607929515,
    isRegular: true,
  },
  {
    lp: "0x17BA6E4490469D8d567A5af7993B4Ac5fD0AedC4",
    lpName: "KSWAP-BUSD",
    allocPoint: 22026431720,
    isRegular: true,
  },
  {
    lp: "0xFE0c489A8C496816fdBf4d1EC52d69b7F2D1868A",
    lpName: "USDT-WBNB",
    allocPoint: 7488986784,
    isRegular: true,
  },
  {
    lp: "0xA124014552B3Bc41AdE8b8Ac75fcC92e18dFeBfE",
    lpName: "ADA-WBNB",
    allocPoint: 2202643172,
    isRegular: true,
  },
  {
    lp: "0x516434DD84577c2339965770B92919f91cA4Db89",
    lpName: "WBNB-LINK",
    allocPoint: 2202643172,
    isRegular: true,
  },
  {
    lp: "0x5037bf8d145Eefb5e48ddf27E5C648a07CF265EA",
    lpName: "DOT-WBNB",
    allocPoint: 2202643172,
    isRegular: true,
  },
  {
    lp: "0x1f1e5cd7Af6ca1a54E3F64052f499313208f71a0",
    lpName: "ADA-BUSD",
    allocPoint: 2202643172,
    isRegular: true,
  },
  {
    lp: "0x6Ce0AEb44Ab22Ad8bAB05A0F2af34bF3C2131d79",
    lpName: "BUSD-LINK",
    allocPoint: 2202643172,
    isRegular: true,
  },
  {
    lp: "0xD17c36273Fbf33Dbd118aBe7B273F75036D013f5",
    lpName: "DOT-BUSD",
    allocPoint: 2202643172,
    isRegular: true,
  },
  {
    lp: "0xD53FdA6B4238eCd4C4bAD67c18b146399DFBe893",
    lpName: "KSWAP-WBNB",
    allocPoint: 24229074890,
    isRegular: true,
  },
];

const getNewFarms = () =>
  newFarms.map((farm: MasterChefNewPoolInfo) => {
    return {
      lpToken: farm.lp,
      allocPoint: farm.allocPoint,
      startBlockNumber: START_BLOCK_NUMBER,
      isRegular: farm.isRegular,
    };
  });

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, owner, treasury } = await getNamedAccounts();

  const KSWAP = await deploy("KswapToken", {
    contract: "KswapToken",
    from: deployer,
    proxy: {
      owner: owner,
      execute: {
        methodName: "initialize",
        args: [owner, [owner], [ethers.utils.parseEther((851e5).toString())]],
      },
    },
    skipIfAlreadyDeployed: true,
    log: true,
  });

  await deploy("MasterChef", {
    contract: "MasterChef",
    from: deployer,
    proxy: {
      owner: owner,
      execute: {
        methodName: "initialize",
        args: [KSWAP.address, treasury, owner, getNewFarms()],
      },
    },
    //gasLimit: 3e7,
    skipIfAlreadyDeployed: true,
    log: true,
  });
};

export default func;
func.tags = ["Initial"];
func.id = basename(__filename, ".ts");
