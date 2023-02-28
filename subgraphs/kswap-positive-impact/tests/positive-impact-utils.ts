import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  Blacklisted,
  Contributed,
  Initialized,
  UnBlacklisted
} from "../generated/PositiveImpact/PositiveImpact"

export function createBlacklistedEvent(
  account: Address,
  reason: string
): Blacklisted {
  let blacklistedEvent = changetype<Blacklisted>(newMockEvent())

  blacklistedEvent.parameters = new Array()

  blacklistedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  blacklistedEvent.parameters.push(
    new ethereum.EventParam("reason", ethereum.Value.fromString(reason))
  )

  return blacklistedEvent
}

export function createContributedEvent(
  account: Address,
  amount: BigInt
): Contributed {
  let contributedEvent = changetype<Contributed>(newMockEvent())

  contributedEvent.parameters = new Array()

  contributedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  contributedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return contributedEvent
}

export function createInitializedEvent(version: i32): Initialized {
  let initializedEvent = changetype<Initialized>(newMockEvent())

  initializedEvent.parameters = new Array()

  initializedEvent.parameters.push(
    new ethereum.EventParam(
      "version",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(version))
    )
  )

  return initializedEvent
}

export function createUnBlacklistedEvent(
  account: Address,
  reason: string
): UnBlacklisted {
  let unBlacklistedEvent = changetype<UnBlacklisted>(newMockEvent())

  unBlacklistedEvent.parameters = new Array()

  unBlacklistedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  unBlacklistedEvent.parameters.push(
    new ethereum.EventParam("reason", ethereum.Value.fromString(reason))
  )

  return unBlacklistedEvent
}
