import "./setup-chai";
import setupTest from "./setupTest";
import { expect } from "chai";
import { BLACKLIST_MANAGER_ROLE } from "./constants";

describe("SimpleBlacklistFacet", () => {
  it("Should blacklist an address", async () => {
    const { Token, owner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount = unnamedAccounts[1];

    await owner.Token.grantRole(BLACKLIST_MANAGER_ROLE, managerAccount.address);

    expect(await Token["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.false;

    await managerAccount.Token["blacklist(address,string)"](
      blacklistAccount.address,
      ""
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.true;
  });

  it("Should blacklist multiple addresses", async () => {
    const { Token, owner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount1 = unnamedAccounts[1];
    const blacklistAccount2 = unnamedAccounts[2];
    const blacklistAccount3 = unnamedAccounts[3];

    await owner.Token.grantRole(BLACKLIST_MANAGER_ROLE, managerAccount.address);

    expect(await Token["isBlacklisted(address)"](blacklistAccount1.address)).to
      .be.false;
    expect(await Token["isBlacklisted(address)"](blacklistAccount2.address)).to
      .be.false;
    expect(await Token["isBlacklisted(address)"](blacklistAccount3.address)).to
      .be.false;

    await managerAccount.Token["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      ["", "", ""]
    );

    await expect(
      managerAccount.Token["blacklist(address[],string[])"](
        [
          blacklistAccount1.address,
          blacklistAccount2.address,
          blacklistAccount3.address,
        ],
        [""]
      )
    ).to.be.revertedWith("SimpleBlacklist: Not enough reasons");

    expect(await Token["isBlacklisted(address)"](blacklistAccount1.address)).to
      .be.true;
    expect(await Token["isBlacklisted(address)"](blacklistAccount2.address)).to
      .be.true;
    expect(await Token["isBlacklisted(address)"](blacklistAccount3.address)).to
      .be.true;

    await managerAccount.Token["unblacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount1.address)).to
      .be.false;
    expect(await Token["isBlacklisted(address)"](blacklistAccount2.address)).to
      .be.false;
    expect(await Token["isBlacklisted(address)"](blacklistAccount3.address)).to
      .be.false;

    await managerAccount.Token["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );
  });

  it("Should unblacklist an address", async () => {
    const { Token, owner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount = unnamedAccounts[1];

    await owner.Token.grantRole(BLACKLIST_MANAGER_ROLE, managerAccount.address);

    await managerAccount.Token["blacklist(address,string)"](
      blacklistAccount.address,
      ""
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.true;

    await managerAccount.Token["unblacklist(address,string)"](
      blacklistAccount.address,
      ""
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.false;
  });

  it("Should unblacklist multiple addresses", async () => {
    const { Token, owner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount1 = unnamedAccounts[1];
    const blacklistAccount2 = unnamedAccounts[2];
    const blacklistAccount3 = unnamedAccounts[3];

    await owner.Token.grantRole(BLACKLIST_MANAGER_ROLE, managerAccount.address);

    await managerAccount.Token["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount1.address)).to
      .be.true;
    expect(await Token["isBlacklisted(address)"](blacklistAccount2.address)).to
      .be.true;
    expect(await Token["isBlacklisted(address)"](blacklistAccount3.address)).to
      .be.true;

    await managerAccount.Token["unblacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      ["", "", ""]
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount1.address)).to
      .be.false;
    expect(await Token["isBlacklisted(address)"](blacklistAccount2.address)).to
      .be.false;
    expect(await Token["isBlacklisted(address)"](blacklistAccount3.address)).to
      .be.false;

    await managerAccount.Token["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount1.address)).to
      .be.true;
    expect(await Token["isBlacklisted(address)"](blacklistAccount2.address)).to
      .be.true;
    expect(await Token["isBlacklisted(address)"](blacklistAccount3.address)).to
      .be.true;

    await managerAccount.Token["unblacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount1.address)).to
      .be.false;
    expect(await Token["isBlacklisted(address)"](blacklistAccount2.address)).to
      .be.false;
    expect(await Token["isBlacklisted(address)"](blacklistAccount3.address)).to
      .be.false;

    await expect(
      managerAccount.Token["unblacklist(address[],string[])"](
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
    const { Token, owner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount = unnamedAccounts[1];

    await owner.Token.grantRole(BLACKLIST_MANAGER_ROLE, managerAccount.address);

    expect(await Token["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.false;

    await managerAccount.Token["blacklist(address,string)"](
      blacklistAccount.address,
      ""
    );

    expect(await Token["isBlacklisted(address)"](blacklistAccount.address)).to
      .be.true;
  });

  it("Should return blacklisted status for an address", async () => {
    const { Token, owner, unnamedAccounts } = await setupTest();
    const managerAccount = unnamedAccounts[0];
    const blacklistAccount1 = unnamedAccounts[1];
    const blacklistAccount2 = unnamedAccounts[2];
    const blacklistAccount3 = unnamedAccounts[3];

    await owner.Token.grantRole(BLACKLIST_MANAGER_ROLE, managerAccount.address);

    expect(
      await Token["isBlacklisted(address[])"]([
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ])
    ).to.be.false;

    await managerAccount.Token["blacklist(address,string)"](
      blacklistAccount1.address,
      ""
    );

    expect(
      await Token["isBlacklisted(address[])"]([
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ])
    ).to.be.true;

    await managerAccount.Token["blacklist(address[],string[])"](
      [
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ],
      []
    );

    expect(
      await Token["isBlacklisted(address[])"]([
        blacklistAccount1.address,
        blacklistAccount2.address,
        blacklistAccount3.address,
      ])
    ).to.be.true;
  });
});
