import "../../setup-chai";
import setupDiamondTest from "../../setupDiamondTest";
import { expect } from "chai";
import { PAUSE_MANAGER_ROLE } from "../../constants";
import { AccessControlFacet, PausableFacet } from "../../../typechain-types";

const setupTest = async () => {
  return (await setupDiamondTest({
    facets: ["AccessControlFacet", "PausableFacet"],
  })) as {
    namedAccounts: {
      [name: string]: { address: string } & {
        Diamond: AccessControlFacet & PausableFacet;
      };
    };
    unnamedAccounts: ({ address: string } & {
      Diamond: AccessControlFacet & PausableFacet;
    })[];
    diamondOwner: { address: string } & {
      Diamond: AccessControlFacet & PausableFacet;
    };
    Diamond: AccessControlFacet & PausableFacet;
  };
};

describe("PausableFacet", () => {
  it("Should pause and unpause the contract", async () => {
    const { Diamond, diamondOwner } = await setupTest();

    expect(await Diamond.paused()).to.be.false;

    await diamondOwner.Diamond.pause();

    expect(await Diamond.paused()).to.be.true;

    await diamondOwner.Diamond.unpause();

    expect(await Diamond.paused()).to.be.false;
  });

  it("Should fail pause and unpause if not pause manager", async () => {
    const { unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    await expect(testAccount.Diamond.pause()).to.be.revertedWith(
      "AccessControl: account " +
        testAccount.address.toLowerCase() +
        " is missing role " +
        PAUSE_MANAGER_ROLE
    );

    await expect(testAccount.Diamond.unpause()).to.be.revertedWith(
      "AccessControl: account " +
        testAccount.address.toLowerCase() +
        " is missing role " +
        PAUSE_MANAGER_ROLE
    );
  });

  it("Should fail pause and unpause if already in that state", async () => {
    const { diamondOwner, unnamedAccounts } = await setupTest();

    const caller = unnamedAccounts.pop();

    await diamondOwner.Diamond.grantRole(
      PAUSE_MANAGER_ROLE,
      caller?.address as string
    );

    await expect(caller?.Diamond.unpause()).to.be.revertedWith(
      "Pausable: not paused"
    );

    await caller?.Diamond.pause();

    await expect(caller?.Diamond.pause()).to.be.revertedWith(
      "Pausable: paused"
    );
  });
});
