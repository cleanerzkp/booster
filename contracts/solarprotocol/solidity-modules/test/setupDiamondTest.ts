import { deployments } from "hardhat";
import {
  formatMigration,
  FormatMigrationOptions,
  setupNamedUsers,
  setupUsers,
} from "@solarprotocol/hardhat-utils";

interface DiamondTestOptions {
  facets: string[];
  migrationOptions?: FormatMigrationOptions[];
}

const setupDiamondTest = deployments.createFixture(async (hre, options) => {
  const { deployments, ethers, getNamedAccounts, getUnnamedAccounts } = hre;
  const opt = options as DiamondTestOptions;
  const { diamond } = deployments;
  const accounts = await getNamedAccounts();

  await deployments.fixture();

  const migrations: {
    name: string;
    contractAddress: string;
    data: string;
  }[] = [];

  if ((opt.migrationOptions?.length as number) > 0) {
    const migrationOptions = opt.migrationOptions as FormatMigrationOptions[];
    await Promise.all(
      migrationOptions.map(async (migrationOptions) => {
        migrations.push(await formatMigration(hre, migrationOptions));
      })
    );
  }

  await diamond.deploy("TestDiamond", {
    diamondContract: "Diamond",
    from: accounts.deployer,
    owner: accounts.owner,
    facets: opt.facets,
    execute:
      (migrations.length as number) > 0
        ? {
            contract: "MigratableInit",
            methodName: "addMigrations",
            args: [migrations, true],
          }
        : undefined,
    log: true,
  });

  const contracts = {
    Diamond: await ethers.getContract("TestDiamond"),
  };

  const namedAccounts = await setupNamedUsers(
    await getNamedAccounts(),
    contracts
  );
  const unnamedAccounts = await setupUsers(
    await getUnnamedAccounts(),
    contracts
  );
  const diamondOwner = namedAccounts.owner;

  return {
    ...contracts,
    namedAccounts,
    unnamedAccounts,
    diamondOwner,
  };
});

export default setupDiamondTest;
