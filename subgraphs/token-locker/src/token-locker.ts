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

function createAction(
  user: User,
  type: string,
  event: DepositEvent | RedeemEvent
): Action {
  log.info("Action event logType: []", [event.logType as string]);

  let action = new Action(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );

  action.type = type;
  action.account = user.address;
  action.user = user.id;
  action.amount = event.params.amount;
  action.reward = event.params.reward;
  action.duration = event.params.duration.toI32();
  action.lockedAt = event.params.lockedAt.toI32();

  action.blockNumber = event.block.number;
  action.blockTimestamp = event.block.timestamp;
  action.transactionHash = event.transaction.hash;

  return action;
}

export function handleDeposit(event: DepositEvent): void {
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

  createAction(user, "deposit", event);
}

export function handleRedeem(event: RedeemEvent): void {
  let user = createUserEntity(event.params.account);

  store.remove(
    "Lock",
    user.id.concatI32(event.params.duration.toI32()).toHex()
  );

  createAction(user, "redeem", event);
}
