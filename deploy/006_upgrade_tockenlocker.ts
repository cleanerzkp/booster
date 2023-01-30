import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { basename } from "path";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, catchUnknownSigner } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  const tx = await catchUnknownSigner(
    deploy("TokenLocker", {
      contract: "TokenLocker",
      from: deployer,
      proxy: {
        owner: owner,
        execute: {
          methodName: "reinitialize",
          args: [[deployer]],
        },
      },
      log: true,
    })
  );

  if (!tx) {
    return true;
  }
};

export default func;
func.tags = ["Initial"];
func.id = basename(__filename, ".ts");
