import { task } from "hardhat/config";

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const { getNamedAccounts, getUnnamedAccounts } = hre;

  console.log("Named", await getNamedAccounts());
  console.log("Unnamed", await getUnnamedAccounts());
});
