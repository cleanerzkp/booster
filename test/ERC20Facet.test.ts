import "./setup-chai";
import setupTest from "./setupTest";
import { expect } from "chai";
import { ethers } from "hardhat";
import { TESTER_ROLE, MINTER_ROLE } from "./constants";

const INITIAL_MINT_AMOUNT = ethers.utils.parseEther((851e5).toString());

describe("ERC20Facet", () => {
  it("Should have a name", async () => {
    const { Token } = await setupTest();

    expect(await Token.name()).to.be.equal("KyotoSwap Token");
  });

  it("Should have a symbol", async () => {
    const { Token } = await setupTest();

    expect(await Token.symbol()).to.be.equal("KSWAP");
  });

  it("Should have 18 decimals", async () => {
    const { Token } = await setupTest();

    expect(await Token.decimals()).to.be.equal(18);
  });

  describe("Initial mint", () => {
    it("Should mint the correct supply", async () => {
      const { Token } = await setupTest();

      expect(await Token.totalSupply()).to.be.equal(INITIAL_MINT_AMOUNT);
    });

    it("Should mint correct vault balances", async () => {
      const { Token, owner } = await setupTest();

      expect(await Token.balanceOf(owner.address)).to.be.equal(
        INITIAL_MINT_AMOUNT
      );
    });
  });

  describe("Transfer", () => {
    it("Should decrease balance of the sender and increase balance of the recipient", async () => {
      const { Token, owner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[0];
      const recipient = unnamedAccounts[5];
      const anotherAccount = unnamedAccounts[6];

      const amount = ethers.utils.parseEther("1000");

      await owner.Token.grantRole(MINTER_ROLE, owner.address);
      await owner.Token.mint(sender.address, amount);

      const totalSupply = await Token.totalSupply();
      const senderBalance = await Token.balanceOf(sender?.address as string);
      const recipientBalance = await Token.balanceOf(
        recipient?.address as string
      );
      const anotherAccountBalance = await Token.balanceOf(
        anotherAccount?.address as string
      );

      await sender?.Token.transfer(recipient?.address as string, amount);

      expect(await Token.totalSupply()).to.be.equal(totalSupply);
      expect(await Token.balanceOf(sender?.address as string)).to.be.equal(
        senderBalance.sub(amount)
      );
      expect(await Token.balanceOf(recipient?.address as string)).to.be.equal(
        recipientBalance.add(amount)
      );
      expect(
        await Token.balanceOf(anotherAccount?.address as string)
      ).to.be.equal(anotherAccountBalance);
    });

    it("Should fail if sender's balance is lower than the amount", async () => {
      const { Token, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[6];
      const recipient = unnamedAccounts[7];
      const amount = ethers.utils.parseEther("1000");

      await expect(
        sender.Token.transfer(recipient?.address as string, amount)
      ).to.be.revertedWithCustomError(
        Token,
        "ERC20TransferAmountExceedsBalance"
      );
    });
  });

  describe("PausableFacet", () => {
    it("Should fail the contract is paused", async () => {
      const { owner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[8];
      const recipient = unnamedAccounts[9];
      const amount = ethers.utils.parseEther("1000");

      await owner.Token.pause();

      await expect(
        sender?.Token.transfer(recipient?.address as string, amount)
      ).to.be.revertedWith("Pausable: paused");
    });

    it("Should succeed when the contract is paused but the caller has tester role or is owner", async () => {
      const { Token, owner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[0];
      const recipient = unnamedAccounts[5];
      const amount = ethers.utils.parseEther("1000");

      await owner.Token.grantRole(MINTER_ROLE, owner.address);
      await owner.Token.mint(sender.address, amount.mul(2));

      const recipientBalance = await Token.balanceOf(
        recipient?.address as string
      );

      await sender?.Token.transfer(owner.address, amount);

      await owner.Token.pause();

      await owner.Token.grantRole(TESTER_ROLE, sender?.address as string);

      await sender?.Token.transfer(recipient?.address as string, amount);

      expect(await Token.balanceOf(recipient?.address as string)).to.be.equal(
        recipientBalance.add(amount)
      );

      await owner.Token.transfer(recipient?.address as string, amount);

      expect(await Token.balanceOf(recipient?.address as string)).to.be.equal(
        recipientBalance.add(amount.mul(2))
      );
    });
  });

  describe("SimpleBlacklistFacet", () => {
    it("Should revert if sender is blacklisted", async () => {
      const { owner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[5];
      const recipient = unnamedAccounts[6];
      const amount = ethers.utils.parseEther("1000");

      await owner.Token["blacklist(address[],string[])"](
        [sender?.address as string],
        []
      );

      await expect(
        sender?.Token.transfer(recipient?.address as string, amount)
      ).to.be.revertedWith(
        "SimpleBlacklist: account " +
          sender?.address.toLowerCase() +
          " is blacklisted"
      );
    });

    it("Should revert if recipient is blacklisted", async () => {
      const { owner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[5];
      const recipient = unnamedAccounts[6];
      const amount = ethers.utils.parseEther("1000");

      await owner.Token["blacklist(address[],string[])"](
        [recipient?.address as string],
        []
      );

      await expect(
        sender?.Token.transfer(recipient?.address as string, amount)
      ).to.be.revertedWith(
        "SimpleBlacklist: account " +
          recipient?.address.toLowerCase() +
          " is blacklisted"
      );
    });
  });

  describe("Allowance", () => {
    it("Should approve an allowance", async () => {
      const { Token, unnamedAccounts } = await setupTest();

      const holder = unnamedAccounts[5];
      const spender = unnamedAccounts[6];
      const amount = ethers.utils.parseEther("1000");

      expect(
        await Token.allowance(
          holder?.address as string,
          spender?.address as string
        )
      ).to.be.equal(0);

      await holder?.Token.approve(spender?.address as string, amount);

      expect(
        await Token.allowance(
          holder?.address as string,
          spender?.address as string
        )
      ).to.be.equal(amount);
    });

    it("Should allow spender to transfer approved amount", async () => {
      const { Token, owner, unnamedAccounts } = await setupTest();

      const holder = unnamedAccounts[0];
      const spender = unnamedAccounts[5];
      const recipient = unnamedAccounts[6];
      const amount = ethers.utils.parseEther("1000");

      await owner.Token.grantRole(MINTER_ROLE, owner.address);
      await owner.Token.mint(holder.address, amount);

      const holderBalance = await Token.balanceOf(holder?.address as string);
      const spenderBalance = await Token.balanceOf(spender?.address as string);
      const recipientBalance = await Token.balanceOf(
        recipient?.address as string
      );

      await holder?.Token.approve(spender?.address as string, amount);

      expect(
        await Token.allowance(
          holder?.address as string,
          spender?.address as string
        )
      ).to.be.equal(amount);

      await spender?.Token.transferFrom(
        holder?.address as string,
        recipient?.address as string,
        amount
      );

      expect(await Token.balanceOf(holder?.address as string)).to.be.equal(
        holderBalance.sub(amount)
      );

      expect(await Token.balanceOf(spender?.address as string)).to.be.equal(
        spenderBalance
      );

      expect(await Token.balanceOf(recipient?.address as string)).to.be.equal(
        recipientBalance.add(amount)
      );

      expect(
        await Token.allowance(
          holder?.address as string,
          spender?.address as string
        )
      ).to.be.equal(0);
    });
  });
});
