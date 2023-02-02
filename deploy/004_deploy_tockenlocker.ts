import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { basename } from "path";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, catchUnknownSigner } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  const kswapTokenAddress = (await deployments.get("KswapToken")).address;

  await catchUnknownSigner(
    deploy("TokenLocker", {
      contract: "TokenLocker",
      from: deployer,
      proxy: {
        owner: owner,
        execute: {
          methodName: "initialize",
          args: [kswapTokenAddress, owner],
        },
      },
      log: true,
    })
  );

  return true;
};

export default func;
func.tags = ["Initial"];
func.id = basename(__filename, ".ts");
