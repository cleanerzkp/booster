import "../../setup-chai";
import setupDiamondTest from "../../setupDiamondTest";
import { expect } from "chai";
import { BLACKLIST_MANAGER_ROLE } from "../../constants";
import {
  AccessControlFacet,
  SimpleBlacklistFacet,
} from "../../../typechain-types";

const setupTest = async () => {
  return (await setupDiamondTest({
    facets: ["AccessControlFacet", "SimpleBlacklistFacet"],
  })) as {
    namedAccounts: {
      [name: string]: { address: string } & {
        Diamond: AccessControlFacet & SimpleBlacklistFacet;
      };
    };
    unnamedAccounts: ({ address: string } & {
      Diamond: AccessControlFacet & SimpleBlacklistFacet;
    })[];
    diamondOwner: { address: string } & {
      Diamond: AccessControlFacet & SimpleBlacklistFacet;
    };
    Diamond: AccessControlFacet & SimpleBlacklistFacet;
  };
};

describe("SimpleBlacklistFacet", () => {
  it("Should blacklist an address", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount = unnamedAccounts[1];

    await diamondOwner.Diamond.grantRole(
      BLACKLIST_MANAGER_ROLE,
      managerAccount.address
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.false;

    await managerAccount.Diamond["blacklist(address,string)"](
      blacklistAccount.address,
      ""
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.true;
  });

  it("Should blacklist multiple addresses", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount1 = unnamedAccounts[1];
    const blacklistAccount2 = unnamedAccounts[2];
    const blacklistAccount3 = unnamedAccounts[3];

    await diamondOwner.Diamond.grantRole(
      BLACKLIST_MANAGER_ROLE,
      managerAccount.address
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount1.address))
      .to.be.false;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount2.address))
      .to.be.false;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount3.address))
      .to.be.false;

    await managerAccount.Diamond["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      ["", "", ""]
    );

    await expect(
      managerAccount.Diamond["blacklist(address[],string[])"](
        [
          blacklistAccount1.address,
          blacklistAccount2.address,
          blacklistAccount3.address,
        ],
        [""]
      )
    ).to.be.revertedWith("SimpleBlacklist: Not enough reasons");

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount1.address))
      .to.be.true;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount2.address))
      .to.be.true;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount3.address))
      .to.be.true;

    await managerAccount.Diamond["unblacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount1.address))
      .to.be.false;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount2.address))
      .to.be.false;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount3.address))
      .to.be.false;

    await managerAccount.Diamond["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );
  });

  it("Should unblacklist an address", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount = unnamedAccounts[1];

    await diamondOwner.Diamond.grantRole(
      BLACKLIST_MANAGER_ROLE,
      managerAccount.address
    );

    await managerAccount.Diamond["blacklist(address,string)"](
      blacklistAccount.address,
      ""
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.true;

    await managerAccount.Diamond["unblacklist(address,string)"](
      blacklistAccount.address,
      ""
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.false;
  });

  it("Should unblacklist multiple addresses", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount1 = unnamedAccounts[1];
    const blacklistAccount2 = unnamedAccounts[2];
    const blacklistAccount3 = unnamedAccounts[3];

    await diamondOwner.Diamond.grantRole(
      BLACKLIST_MANAGER_ROLE,
      managerAccount.address
    );

    await managerAccount.Diamond["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount1.address))
      .to.be.true;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount2.address))
      .to.be.true;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount3.address))
      .to.be.true;

    await managerAccount.Diamond["unblacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      ["", "", ""]
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount1.address))
      .to.be.false;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount2.address))
      .to.be.false;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount3.address))
      .to.be.false;

    await managerAccount.Diamond["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount1.address))
      .to.be.true;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount2.address))
      .to.be.true;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount3.address))
      .to.be.true;

    await managerAccount.Diamond["unblacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount1.address))
      .to.be.false;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount2.address))
      .to.be.false;
    expect(await Diamond["isBlacklisted(address)"](blacklistAccount3.address))
      .to.be.false;

    await expect(
      managerAccount.Diamond["unblacklist(address[],string[])"](
        [
          blacklistAccount1.address,
          blacklistAccount2.address,
          blacklistAccount3.address,
        ],
        [""]
      )
    ).to.be.revertedWith("SimpleBlacklist: Not enough reasons");
  });

  it("Should return blacklisted status for an address", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount = unnamedAccounts[1];

    await diamondOwner.Diamond.grantRole(
      BLACKLIST_MANAGER_ROLE,
      managerAccount.address
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.false;

    await managerAccount.Diamond["blacklist(address,string)"](
      blacklistAccount.address,
      ""
    );

    expect(await Diamond["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.true;
  });

  it("Should return blacklisted status for an address", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount1 = unnamedAccounts[1];
    const blacklistAccount2 = unnamedAccounts[2];
    const blacklistAccount3 = unnamedAccounts[3];

    await diamondOwner.Diamond.grantRole(
      BLACKLIST_MANAGER_ROLE,
      managerAccount.address
    );

    expect(
      await Diamond["isBlacklisted(address[])"]([
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ])
    ).to.be.false;

    await managerAccount.Diamond["blacklist(address,string)"](
      blacklistAccount1.address,
      ""
    );

    expect(
      await Diamond["isBlacklisted(address[])"]([
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ])
    ).to.be.true;

    await managerAccount.Diamond["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(
      await Diamond["isBlacklisted(address[])"]([
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ])
    ).to.be.true;
  });
});
