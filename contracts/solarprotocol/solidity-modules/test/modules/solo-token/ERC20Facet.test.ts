import "../../setup-chai";
import setupDiamondTest from "../../setupDiamondTest";
import { expect } from "chai";
import { ethers, getUnnamedAccounts } from "hardhat";
import { TESTER_ROLE } from "../../constants";
import {
  AccessControlFacet,
  ERC20Facet,
  PausableFacet,
  SimpleBlacklistFacet,
} from "../../../typechain-types";

const setupTest = async () => {
  const unnamedAccounts = await getUnnamedAccounts();

  return (await setupDiamondTest({
    facets: [
      "ERC20Facet",
      "AccessControlFacet",
      "SimpleBlacklistFacet",
      "PausableFacet",
    ],
    migrationOptions: [
      {
        contract: "TestSetupSoloTokenMigration",
        signature: {
          abi: [
            "function migrate(address account1, address account2, address account3, address account4)",
          ],
          functionFragment: "migrate",
          args: [
            unnamedAccounts[0],
            unnamedAccounts[1],
            unnamedAccounts[2],
            unnamedAccounts[3],
          ],
        },
      },
    ],
  })) as {
    namedAccounts: {
      [name: string]: { address: string } & {
        Diamond: ERC20Facet &
          AccessControlFacet &
          SimpleBlacklistFacet &
          PausableFacet;
      };
    };
    unnamedAccounts: ({ address: string } & {
      Diamond: ERC20Facet &
        AccessControlFacet &
        SimpleBlacklistFacet &
        PausableFacet;
    })[];
    diamondOwner: { address: string } & {
      Diamond: ERC20Facet &
        AccessControlFacet &
        SimpleBlacklistFacet &
        PausableFacet;
    };
    Diamond: ERC20Facet &
      AccessControlFacet &
      SimpleBlacklistFacet &
      PausableFacet;
  };
};

describe("ERC20Facet", () => {
  it("Should have a name", async () => {
    const { Diamond } = await setupTest();

    expect(await Diamond.name()).to.be.equal("TestToken");
  });

  it("Should have a symbol", async () => {
    const { Diamond } = await setupTest();

    expect(await Diamond.symbol()).to.be.equal("tTKN");
  });

  it("Should have 18 decimals", async () => {
    const { Diamond } = await setupTest();

    expect(await Diamond.decimals()).to.be.equal(18);
  });

  describe("Initial mint", () => {
    it("Should mint the correct supply", async () => {
      const { Diamond } = await setupTest();

      expect(await Diamond.totalSupply()).to.be.equal(
        ethers.utils.parseEther("1000000")
      );
    });

    it("Should mint correct vault balances", async () => {
      const { Diamond, unnamedAccounts } = await setupTest();

      expect(await Diamond.balanceOf(unnamedAccounts[0].address)).to.be.equal(
        ethers.utils.parseEther("100000")
      );

      expect(await Diamond.balanceOf(unnamedAccounts[1].address)).to.be.equal(
        ethers.utils.parseEther("200000")
      );

      expect(await Diamond.balanceOf(unnamedAccounts[2].address)).to.be.equal(
        ethers.utils.parseEther("300000")
      );

      expect(await Diamond.balanceOf(unnamedAccounts[3].address)).to.be.equal(
        ethers.utils.parseEther("400000")
      );
    });
  });

  describe("Transfer", () => {
    it("Should decrease balance of the sender and increase balance of the recipient", async () => {
      const { Diamond, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[0];
      const recipient = unnamedAccounts.pop();
      const anotherAccount = unnamedAccounts.pop();

      const amount = ethers.utils.parseEther("1000");

      const totalSupply = await Diamond.totalSupply();
      const senderBalance = await Diamond.balanceOf(sender?.address as string);
      const recipientBalance = await Diamond.balanceOf(
        recipient?.address as string
      );
      const anotherAccountBalance = await Diamond.balanceOf(
        anotherAccount?.address as string
      );

      await sender?.Diamond.transfer(recipient?.address as string, amount);

      expect(await Diamond.totalSupply()).to.be.equal(totalSupply);
      expect(await Diamond.balanceOf(sender?.address as string)).to.be.equal(
        senderBalance.sub(amount)
      );
      expect(await Diamond.balanceOf(recipient?.address as string)).to.be.equal(
        recipientBalance.add(amount)
      );
      expect(
        await Diamond.balanceOf(anotherAccount?.address as string)
      ).to.be.equal(anotherAccountBalance);
    });

    it("Should fail if sender's balance is lower than the amount", async () => {
      const { unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[6];
      const recipient = unnamedAccounts.pop();
      const amount = ethers.utils.parseEther("1000");

      await expect(
        sender.Diamond.transfer(recipient?.address as string, amount)
      ).to.be.revertedWith("ERC777: transfer amount exceeds balance");
    });
  });

  describe("PausableFacet", () => {
    it("Should fail the contract is paused", async () => {
      const { diamondOwner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts.pop();
      const recipient = unnamedAccounts.pop();
      const amount = ethers.utils.parseEther("1000");

      await diamondOwner.Diamond.pause();

      await expect(
        sender?.Diamond.transfer(recipient?.address as string, amount)
      ).to.be.revertedWith("Pausable: paused");
    });

    it("Should succeed when the contract is paused but the caller has tester role or is owner", async () => {
      const { Diamond, diamondOwner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts[0];
      const recipient = unnamedAccounts.pop();
      const amount = ethers.utils.parseEther("1000");

      const recipientBalance = await Diamond.balanceOf(
        recipient?.address as string
      );

      await sender?.Diamond.transfer(diamondOwner.address, amount);

      await diamondOwner.Diamond.pause();

      await diamondOwner.Diamond.grantRole(
        TESTER_ROLE,
        sender?.address as string
      );

      await sender?.Diamond.transfer(recipient?.address as string, amount);

      expect(await Diamond.balanceOf(recipient?.address as string)).to.be.equal(
        recipientBalance.add(amount)
      );

      await diamondOwner.Diamond.transfer(recipient?.address as string, amount);

      expect(await Diamond.balanceOf(recipient?.address as string)).to.be.equal(
        recipientBalance.add(amount.mul(2))
      );
    });
  });

  describe("SimpleBlacklistFacet", () => {
    it("Should revert if sender is blacklisted", async () => {
      const { diamondOwner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts.pop();
      const recipient = unnamedAccounts.pop();
      const amount = ethers.utils.parseEther("1000");

      await diamondOwner.Diamond["blacklist(address[],string[])"](
        [sender?.address as string],
        []
      );

      await expect(
        sender?.Diamond.transfer(recipient?.address as string, amount)
      ).to.be.revertedWith(
        "SimpleBlacklist: account " +
          sender?.address.toLowerCase() +
          " is blacklisted"
      );
    });

    it("Should revert if recipient is blacklisted", async () => {
      const { diamondOwner, unnamedAccounts } = await setupTest();

      const sender = unnamedAccounts.pop();
      const recipient = unnamedAccounts.pop();
      const amount = ethers.utils.parseEther("1000");

      await diamondOwner.Diamond["blacklist(address[],string[])"](
        [recipient?.address as string],
        []
      );

      await expect(
        sender?.Diamond.transfer(recipient?.address as string, amount)
      ).to.be.revertedWith(
        "SimpleBlacklist: account " +
          recipient?.address.toLowerCase() +
          " is blacklisted"
      );
    });
  });

  describe("Allowance", () => {
    it("Should approve an allowance", async () => {
      const { Diamond, unnamedAccounts } = await setupTest();

      const holder = unnamedAccounts.pop();
      const spender = unnamedAccounts.pop();
      const amount = ethers.utils.parseEther("1000");

      expect(
        await Diamond.allowance(
          holder?.address as string,
          spender?.address as string
        )
      ).to.be.equal(0);

      await holder?.Diamond.approve(spender?.address as string, amount);

      expect(
        await Diamond.allowance(
          holder?.address as string,
          spender?.address as string
        )
      ).to.be.equal(amount);
    });

    it("Should allow spender to transfer approved amount", async () => {
      const { Diamond, unnamedAccounts } = await setupTest();

      const holder = unnamedAccounts[0];
      const spender = unnamedAccounts.pop();
      const recipient = unnamedAccounts.pop();
      const amount = ethers.utils.parseEther("1000");

      const holderBalance = await Diamond.balanceOf(holder?.address as string);
      const spenderBalance = await Diamond.balanceOf(
        spender?.address as string
      );
      const recipientBalance = await Diamond.balanceOf(
        recipient?.address as string
      );

      await holder?.Diamond.approve(spender?.address as string, amount);

      expect(
        await Diamond.allowance(
          holder?.address as string,
          spender?.address as string
        )
      ).to.be.equal(amount);

      await spender?.Diamond.transferFrom(
        holder?.address as string,
        recipient?.address as string,
        amount
      );

      expect(await Diamond.balanceOf(holder?.address as string)).to.be.equal(
        holderBalance.sub(amount)
      );

      expect(await Diamond.balanceOf(spender?.address as string)).to.be.equal(
        spenderBalance
      );

      expect(await Diamond.balanceOf(recipient?.address as string)).to.be.equal(
        recipientBalance.add(amount)
      );

      expect(
        await Diamond.allowance(
          holder?.address as string,
          spender?.address as string
        )
      ).to.be.equal(0);
    });
  });
});
