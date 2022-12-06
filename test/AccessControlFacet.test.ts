import "./setup-chai";
import setupTest from "./setupTest";
import { expect } from "chai";
import {
  DEFAULT_ADMIN_ROLE,
  MANAGER_ROLE,
  BLACKLIST_MANAGER_ROLE,
  TESTER_ROLE,
  PAUSE_MANAGER_ROLE,
} from "./constants";

describe("AccessControlFacet", () => {
  it("Should have initial state", async () => {
    const { Token, owner } = await setupTest();

    expect(await Token.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;

    expect(await Token.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.be.equal(1);
    expect(await Token.getRoleMemberCount(MANAGER_ROLE)).to.be.equal(0);
    expect(await Token.getRoleMemberCount(BLACKLIST_MANAGER_ROLE)).to.be.equal(
      0
    );
  });

  it("Should set the role admin", async () => {
    const { Token, owner } = await setupTest();

    expect(await Token.getRoleAdmin(BLACKLIST_MANAGER_ROLE)).to.be.equal(
      DEFAULT_ADMIN_ROLE
    );
    expect(await Token.getRoleAdmin(TESTER_ROLE)).to.be.equal(
      DEFAULT_ADMIN_ROLE
    );

    await owner.Token.setRoleAdmin(BLACKLIST_MANAGER_ROLE, MANAGER_ROLE);

    expect(await Token.getRoleAdmin(BLACKLIST_MANAGER_ROLE)).to.be.equal(
      MANAGER_ROLE
    );
    expect(await Token.getRoleAdmin(TESTER_ROLE)).to.be.equal(
      DEFAULT_ADMIN_ROLE
    );
  });

  it("Should grant and revoke roles", async () => {
    const { Token, owner, unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    expect(await Token.hasRole(TESTER_ROLE, testAccount.address)).to.be.false;

    await owner.Token.grantRole(TESTER_ROLE, testAccount.address);

    expect(await Token.hasRole(TESTER_ROLE, testAccount.address)).to.be.true;

    await owner.Token.revokeRole(TESTER_ROLE, testAccount.address);

    expect(await Token.hasRole(TESTER_ROLE, testAccount.address)).to.be.false;
  });

  it("Should allow to renounce a role", async () => {
    const { Token, owner, unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    expect(await Token.hasRole(TESTER_ROLE, testAccount.address)).to.be.false;

    await owner.Token.grantRole(TESTER_ROLE, testAccount.address);

    expect(await Token.hasRole(TESTER_ROLE, testAccount.address)).to.be.true;

    await testAccount.Token.renounceRole(TESTER_ROLE, testAccount.address);

    expect(await Token.hasRole(TESTER_ROLE, testAccount.address)).to.be.false;
  });

  it("Should fail setting role admin if not role admin", async () => {
    const { unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    await expect(
      testAccount.Token.setRoleAdmin(BLACKLIST_MANAGER_ROLE, MANAGER_ROLE)
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
      testAccount.Token.grantRole(TESTER_ROLE, testAccount.address)
    ).to.be.revertedWith(
      "AccessControl: account " +
        testAccount.address.toLowerCase() +
        " is missing role " +
        DEFAULT_ADMIN_ROLE
    );
  });

  it("Should revert renouncing a role for other accounts", async () => {
    const { owner, unnamedAccounts } = await setupTest();
    const testAccount = unnamedAccounts[0];

    await expect(
      owner.Token.renounceRole(TESTER_ROLE, testAccount.address)
    ).to.be.revertedWith("AccessControl: can only renounce roles for self");
  });

  it("Should enumerate role members", async () => {
    const { Token, owner, unnamedAccounts } = await setupTest();
    const roleToTest = PAUSE_MANAGER_ROLE;

    const accounts = unnamedAccounts.slice(0, 3);

    const accountAddresses: string[] = [];
    await Promise.all(
      accounts.map(async (account: { address: string }) => {
        accountAddresses.push(account.address.toLowerCase());
        await owner.Token.grantRole(roleToTest, account.address);
      })
    );

    const roleMemberCount = await Token.getRoleMemberCount(roleToTest);

    expect(roleMemberCount).to.be.equal(accounts.length);

    const roleMembers: string[] = [];
    for (let i = 0; i < roleMemberCount.toNumber(); i++) {
      roleMembers.push(
        (await Token.getRoleMember(roleToTest, i)).toLowerCase()
      );
    }

    expect(roleMembers).to.be.ofSize(roleMemberCount.toNumber());

    expect(roleMembers).to.be.equalTo(accountAddresses);
  });

  describe("SimpleBlacklistFacet", () => {
    it("Should always fallback to the default role", async () => {
      const { owner, unnamedAccounts } = await setupTest();
      const managerAccount = unnamedAccounts[0];
      const testAccount = unnamedAccounts[1];
      const blacklistedAccount = unnamedAccounts[2];

      await owner.Token.grantRole(
        BLACKLIST_MANAGER_ROLE,
        managerAccount.address
      );

      await managerAccount.Token["blacklist(address,string)"](
        blacklistedAccount.address,
        ""
      );

      await owner.Token["blacklist(address,string)"](
        blacklistedAccount.address,
        ""
      );

      await expect(
        testAccount.Token["blacklist(address,string)"](
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
      const { owner, unnamedAccounts } = await setupTest();
      const managerAccount = unnamedAccounts[0];
      const testAccount = unnamedAccounts[1];

      await owner.Token.grantRole(PAUSE_MANAGER_ROLE, managerAccount.address);

      await managerAccount.Token.pause();

      await owner.Token.unpause();

      await expect(testAccount.Token.pause()).to.be.revertedWith(
        "AccessControl: account " +
          testAccount.address.toLowerCase() +
          " is missing role " +
          PAUSE_MANAGER_ROLE
      );
    });
  });
});
