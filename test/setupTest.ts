import { deployments } from "hardhat";
import { setupNamedUsers, setupUsers } from "@solarprotocol/hardhat-utils";
import { KswapToken, MasterChef } from "../typechain-types";

const setupTest = deployments.createFixture(async (hre) => {
  const { deployments, ethers, getNamedAccounts, getUnnamedAccounts } = hre;

  await deployments.fixture();

  const contracts = {
    Token: (await ethers.getContract("KswapToken")) as KswapToken,
    MasterChef: (await ethers.getContract("MasterChef")) as MasterChef,
  };

  const namedAccounts = await setupNamedUsers(
    await getNamedAccounts(),
    contracts
  );
  const unnamedAccounts = await setupUsers(
    await getUnnamedAccounts(),
    contracts
  );
  const owner = namedAccounts.owner;

  return {
    ...contracts,
    namedAccounts,
    unnamedAccounts,
    owner,
  };
});

export default setupTest;
