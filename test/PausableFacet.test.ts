import "./setup-chai";
import setupTest from "./setupTest";
import { expect } from "chai";
import { PAUSE_MANAGER_ROLE } from "./constants";

describe("PausableFacet", () => {
  it("Should pause and unpause the contract", async () => {
    const { Token, owner } = await setupTest();

    expect(await Token.paused()).to.be.false;

    await owner.Token.pause();

    expect(await Token.paused()).to.be.true;

    await owner.Token.unpause();

    expect(await Token.paused()).to.be.false;
  });

  it("Should fail pause and unpause if not pause manager", async () => {
    const { unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    await expect(testAccount.Token.pause()).to.be.revertedWith(
      "AccessControl: account " +
        testAccount.address.toLowerCase() +
        " is missing role " +
        PAUSE_MANAGER_ROLE
    );

    await expect(testAccount.Token.unpause()).to.be.revertedWith(
      "AccessControl: account " +
        testAccount.address.toLowerCase() +
        " is missing role " +
        PAUSE_MANAGER_ROLE
    );
  });

  it("Should fail pause and unpause if already in that state", async () => {
    const { owner, unnamedAccounts } = await setupTest();

    const caller = unnamedAccounts[1];

    await owner.Token.grantRole(PAUSE_MANAGER_ROLE, caller?.address as string);

    await expect(caller?.Token.unpause()).to.be.revertedWith(
      "Pausable: not paused"
    );

    await caller?.Token.pause();

    await expect(caller?.Token.pause()).to.be.revertedWith("Pausable: paused");
  });
});
