import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { Blacklisted } from "../generated/schema"
import { Blacklisted as BlacklistedEvent } from "../generated/PositiveImpact/PositiveImpact"
import { handleBlacklisted } from "../src/positive-impact"
import { createBlacklistedEvent } from "./positive-impact-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let account = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let reason = "Example string value"
    let newBlacklistedEvent = createBlacklistedEvent(account, reason)
    handleBlacklisted(newBlacklistedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("Blacklisted created and stored", () => {
    assert.entityCount("Blacklisted", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "Blacklisted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "account",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "Blacklisted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "reason",
      "Example string value"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
