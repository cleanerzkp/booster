import "../../setup-chai";
import { expect } from "chai";
import setupDiamondTest from "../../setupDiamondTest";
import { ethers } from "hardhat";

describe("TestReceiveFacet", () => {
  it("Test Receive", async () => {
    const { Diamond, unnamedAccounts } = await setupDiamondTest({
      facets: ["TestReceiveFacet"],
    });

    const transaction = { to: Diamond.address, value: 11111 };
    const transactionResponse = ethers.provider
      .getSigner(unnamedAccounts[0].address)
      .sendTransaction(transaction);
    await expect(transactionResponse)
      .to.emit(Diamond, "EtherReceived")
      .withArgs(unnamedAccounts[0].address, transaction.value);
  });
});
