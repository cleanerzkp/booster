import "../../setup-chai";
import setupDiamondTest from "../../setupDiamondTest";
import { expect } from "chai";
import {
  DEFAULT_ADMIN_ROLE,
  MANAGER_ROLE,
  BLACKLIST_MANAGER_ROLE,
  TESTER_ROLE,
  PAUSE_MANAGER_ROLE,
} from "../../constants";
import {
  AccessControlFacet,
  PausableFacet,
  SimpleBlacklistFacet,
} from "../../../typechain-types";

const setupTest = async () => {
  return (await setupDiamondTest({
    facets: ["AccessControlFacet", "SimpleBlacklistFacet", "PausableFacet"],
  })) as {
    namedAccounts: {
      [name: string]: { address: string } & {
        Diamond: AccessControlFacet & SimpleBlacklistFacet & PausableFacet;
      };
    };
    unnamedAccounts: ({ address: string } & {
      Diamond: AccessControlFacet & SimpleBlacklistFacet & PausableFacet;
    })[];
    diamondOwner: { address: string } & {
      Diamond: AccessControlFacet & SimpleBlacklistFacet & PausableFacet;
    };
    Diamond: AccessControlFacet & SimpleBlacklistFacet & PausableFacet;
  };
};

describe("AccessControlFacet", () => {
  it("Should have initial state", async () => {
    const { Diamond, diamondOwner } = await setupTest();

    expect(await Diamond.hasRole(DEFAULT_ADMIN_ROLE, diamondOwner.address)).to
      .be.true;

    expect(await Diamond.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.be.equal(1);
    expect(await Diamond.getRoleMemberCount(MANAGER_ROLE)).to.be.equal(0);
    expect(
      await Diamond.getRoleMemberCount(BLACKLIST_MANAGER_ROLE)
    ).to.be.equal(0);
  });

  it("Should set the role admin", async () => {
    const { Diamond, diamondOwner } = await setupTest();

    expect(await Diamond.getRoleAdmin(BLACKLIST_MANAGER_ROLE)).to.be.equal(
      DEFAULT_ADMIN_ROLE
    );
    expect(await Diamond.getRoleAdmin(TESTER_ROLE)).to.be.equal(
      DEFAULT_ADMIN_ROLE
    );

    await diamondOwner.Diamond.setRoleAdmin(
      BLACKLIST_MANAGER_ROLE,
      MANAGER_ROLE
    );

    expect(await Diamond.getRoleAdmin(BLACKLIST_MANAGER_ROLE)).to.be.equal(
      MANAGER_ROLE
    );
    expect(await Diamond.getRoleAdmin(TESTER_ROLE)).to.be.equal(
      DEFAULT_ADMIN_ROLE
    );
  });

  it("Should grant and revoke roles", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    expect(await Diamond.hasRole(TESTER_ROLE, testAccount.address)).to.be.false;

    await diamondOwner.Diamond.grantRole(TESTER_ROLE, testAccount.address);

    expect(await Diamond.hasRole(TESTER_ROLE, testAccount.address)).to.be.true;

    await diamondOwner.Diamond.revokeRole(TESTER_ROLE, testAccount.address);

    expect(await Diamond.hasRole(TESTER_ROLE, testAccount.address)).to.be.false;
  });

  it("Should allow to renounce a role", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    expect(await Diamond.hasRole(TESTER_ROLE, testAccount.address)).to.be.false;

    await diamondOwner.Diamond.grantRole(TESTER_ROLE, testAccount.address);

    expect(await Diamond.hasRole(TESTER_ROLE, testAccount.address)).to.be.true;

    await testAccount.Diamond.renounceRole(TESTER_ROLE, testAccount.address);

    expect(await Diamond.hasRole(TESTER_ROLE, testAccount.address)).to.be.false;
  });

  it("Should fail setting role admin if not role admin", async () => {
    const { unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    await expect(
      testAccount.Diamond.setRoleAdmin(BLACKLIST_MANAGER_ROLE, MANAGER_ROLE)
    ).to.be.revertedWith(
      "AccessControl: account " +
        testAccount.address.toLowerCase() +
        " is missing role " +
        DEFAULT_ADMIN_ROLE
    );
  });

  it("Should fail granting role if not role admin", async () => {
    const { unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    await expect(
      testAccount.Diamond.grantRole(TESTER_ROLE, testAccount.address)
    ).to.be.revertedWith(
      "AccessControl: account " +
        testAccount.address.toLowerCase() +
        " is missing role " +
        DEFAULT_ADMIN_ROLE
    );
  });

  it("Should revert renouncing a role for other accounts", async () => {
    const { diamondOwner, unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    await expect(
      diamondOwner.Diamond.renounceRole(TESTER_ROLE, testAccount.address)
    ).to.be.revertedWith("AccessControl: can only renounce roles for self");
  });

  it("Should enumerate role members", async () => {
    const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();
    const roleToTest = PAUSE_MANAGER_ROLE;

    const accounts = unnamedAccounts.slice(0, 3);

    const accountAddresses: string[] = [];
    await Promise.all(
      accounts.map(async (account: { address: string }) => {
        accountAddresses.push(account.address.toLowerCase());
        await diamondOwner.Diamond.grantRole(roleToTest, account.address);
      })
    );

    const roleMemberCount = await Diamond.getRoleMemberCount(roleToTest);

    expect(roleMemberCount).to.be.equal(accounts.length);

    const roleMembers: string[] = [];
    for (let i = 0; i < roleMemberCount.toNumber(); i++) {
      roleMembers.push(
        (await Diamond.getRoleMember(roleToTest, i)).toLowerCase()
      );
    }

    expect(roleMembers).to.be.ofSize(roleMemberCount.toNumber());

    expect(roleMembers).to.be.equalTo(accountAddresses);
  });

  describe("SimpleBlacklistFacet", () => {
    it("Should always fallback to the default role", async () => {
      const { diamondOwner, unnamedAccounts } = await setupTest();
      const managerAccount = unnamedAccounts[0];
      const testAccount = unnamedAccounts[1];
      const blacklistedAccount = unnamedAccounts[2];

      await diamondOwner.Diamond.grantRole(
        BLACKLIST_MANAGER_ROLE,
        managerAccount.address
      );

      await managerAccount.Diamond["blacklist(address,string)"](
        blacklistedAccount.address,
        ""
      );

      await diamondOwner.Diamond["blacklist(address,string)"](
        blacklistedAccount.address,
        ""
      );

      await expect(
        testAccount.Diamond["blacklist(address,string)"](
          blacklistedAccount.address,
          ""
        )
      ).to.be.revertedWith(
        "AccessControl: account " +
          testAccount.address.toLowerCase() +
          " is missing role " +
          BLACKLIST_MANAGER_ROLE
      );
    });
  });

  describe("PausableFacet", () => {
    it("Should always fallback to the default role", async () => {
      const { diamondOwner, unnamedAccounts } = await setupTest();
      const managerAccount = unnamedAccounts[0];
      const testAccount = unnamedAccounts[1];

      await diamondOwner.Diamond.grantRole(
        PAUSE_MANAGER_ROLE,
        managerAccount.address
      );

      await managerAccount.Diamond.pause();

      await diamondOwner.Diamond.unpause();

      await expect(testAccount.Diamond.pause()).to.be.revertedWith(
        "AccessControl: account " +
          testAccount.address.toLowerCase() +
          " is missing role " +
          PAUSE_MANAGER_ROLE
      );
    });
  });
});
