import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { basename } from "path";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, catchUnknownSigner } = deployments;

  const { deployer, owner, treasury } = await getNamedAccounts();

  const tx = await catchUnknownSigner(
    deploy("PositiveImpact", {
      contract: "PositiveImpact",
      from: deployer,
      proxy: {
        owner: owner,
        execute: {
          onUpgrade: {
            methodName: "updateTreasuryAddress",
            args: [treasury],
          },
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
