import {
  Contributed as ContributedEvent,
} from "../generated/PositiveImpact/PositiveImpact";
import {
  KyotoSwapRouter,
} from "../generated/PositiveImpact/KyotoSwapRouter";
import {
  KyotoSwapPair,
} from "../generated/PositiveImpact/KyotoSwapPair";
import {
  User,
  Contribution,
} from "../generated/schema";
import { Bytes, Address, BigInt, BigDecimal } from "@graphprotocol/graph-ts";

const KSWAP = Address.fromString("0x29ABc4D03D133D8Fd1F1C54318428353CE08727E");
const BUSD = Address.fromString("0xe9e7cea3dedca5984780bafc599bd69add087d56");
const ROUTER = Address.fromString("0xf177d077a8C65BaDE7154bCaB4Ac30005035e7a3");
const PAIR = Address.fromString("0x8379e36F123d7d9a03fB20317f4Cc1B19630B5b5");

function createUserEntity(account: Bytes): User {
  let user = User.load(account);
  if (user === null) {
    user = new User(account);
    user.address = account.toHexString();
    user.save();
  }

  return user;
}

export function handleContributed(event: ContributedEvent): void {
  let entity = new Contribution(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )

  let user = createUserEntity(event.params.account);

  entity.user = user.id;
  entity.amount = event.params.amount;

  const reserves = KyotoSwapPair.bind(PAIR).getReserves();
  entity.price = BigDecimal.fromString(reserves.value1.toString())
    .div(BigDecimal.fromString(reserves.value0.toString()));

  entity.value = entity.price.times(BigDecimal.fromString(entity.amount.toString()));

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
