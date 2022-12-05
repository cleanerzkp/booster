import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { basename } from "path";
import { ethers } from "ethers";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, owner, treasury } = await getNamedAccounts();

  await deploy("KswapToken", {
    contract: "KswapToken",
    from: deployer,
    proxy: {
      owner: owner,
      execute: {
        methodName: "initialize",
        args: [
          owner,
          [treasury],
          [ethers.utils.parseEther((851e5).toString())],
        ],
      },
    },
    skipIfAlreadyDeployed: true,
    log: true,
  });
};

export default func;
func.tags = ["Initial"];
func.id = basename(__filename, ".ts");
