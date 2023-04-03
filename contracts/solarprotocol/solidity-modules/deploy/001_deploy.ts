import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { formatMigration } from "@solarprotocol/hardhat-utils";
import { basename } from "path";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { diamond, catchUnknownSigner } = deployments;

  const { deployer, owner } = await getNamedAccounts();

  const tx = await catchUnknownSigner(
    diamond.deploy("TestDiamond", {
      diamondContract: "Diamond",
      from: deployer,
      owner: owner,
      facets: [],
      log: true,
      execute: {
        contract: "MigratableInit",
        methodName: "addMigrations",
        args: [
          [
            await formatMigration(hre, {
              contract: "TestSetupAccessControlMigration",
            }),
          ],
          true,
        ],
      },
    })
  );

  if (!tx) {
    return true;
  }
};

export default func;
func.tags = ["Initial"];
func.id = basename(__filename, ".ts");
