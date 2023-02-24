import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { basename } from "path";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, catchUnknownSigner } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  const tx = await catchUnknownSigner(
    deploy("MasterChef", {
      contract: "MasterChef",
      from: deployer,
      proxy: {
        owner: owner,
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
