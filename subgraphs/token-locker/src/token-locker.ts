import {
  Deposit as DepositEvent,
  Redeem as RedeemEvent,
} from "../generated/TokenLocker/TokenLocker";
import { User, Lock, Action } from "../generated/schema";
import { Bytes, log, store } from "@graphprotocol/graph-ts";

function createUserEntity(account: Bytes): User {
  let user = User.load(account);
  if (user === null) {
    user = new User(account);
    user.address = account.toHexString();
    user.save();
  }

  return user;
}

export function handleDeposit(event: DepositEvent): void {
  log.debug("DepositEvent: {}, {}, {}, {}, {}, {}", [
    event.params.account.toHexString(),
    event.params.amount.toString(),
    event.params.reward.toString(),
    event.params.duration.toString(),
    event.params.lockedAt.toString(),
    event.params.expiresAt.toString()
  ]);

  let user = createUserEntity(event.params.account);

  let lock = new Lock(user.id.concatI32(event.params.duration.toI32()));
  lock.account = user.address;
  lock.user = user.id;
  lock.amount = event.params.amount;
  lock.reward = event.params.reward;
  lock.duration = event.params.duration.toI32();
  lock.lockedAt = event.params.lockedAt.toI32();
  lock.expiresAt = event.params.expiresAt.toI32();

  lock.blockNumber = event.block.number;
  lock.blockTimestamp = event.block.timestamp;
  lock.transactionHash = event.transaction.hash;

  lock.save();

  let action = new Action(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );

  action.type = "deposit";
  action.account = user.address;
  action.user = user.id;
  action.amount = event.params.amount;
  action.reward = event.params.reward;
  action.duration = event.params.duration.toI32();
  action.lockedAt = event.params.lockedAt.toI32();

  action.blockNumber = event.block.number;
  action.blockTimestamp = event.block.timestamp;
  action.transactionHash = event.transaction.hash;

  action.save();
}

export function handleRedeem(event: RedeemEvent): void {
  log.debug("RedeemEvent: {}, {}, {}, {}, {}", [
    event.params.account.toHexString(),
    event.params.amount.toString(),
    event.params.reward.toString(),
    event.params.duration.toString(),
    event.params.lockedAt.toString(),
  ]);

  let user = createUserEntity(event.params.account);

  store.remove(
    "Lock",
    user.id.concatI32(event.params.duration.toI32()).toHex()
  );

  let action = new Action(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );

  action.type = "redeem";
  action.account = user.address;
  action.user = user.id;
  action.amount = event.params.amount;
  action.reward = event.params.reward;
  action.duration = event.params.duration.toI32();
  action.lockedAt = event.params.lockedAt.toI32();

  action.blockNumber = event.block.number;
  action.blockTimestamp = event.block.timestamp;
  action.transactionHash = event.transaction.hash;

  action.save();
}
