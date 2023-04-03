import { ethers } from "hardhat";

const { utils } = ethers;

export const DEFAULT_ADMIN_ROLE = ethers.constants.HashZero;
export const MANAGER_ROLE = utils.keccak256(utils.toUtf8Bytes("MANAGER_ROLE"));
export const BLACKLIST_MANAGER_ROLE = utils.keccak256(
  utils.toUtf8Bytes("BLACKLIST_MANAGER_ROLE")
);
export const PAUSE_MANAGER_ROLE = utils.keccak256(
  utils.toUtf8Bytes("PAUSE_MANAGER_ROLE")
);
export const TESTER_ROLE = utils.keccak256(utils.toUtf8Bytes("TESTER_ROLE"));
