import "../../setup-chai";
import { expect } from "chai";
import setupDiamondTest from "../../setupDiamondTest";
import { TestFacet } from "../../../typechain-types";

describe("TestFacet", () => {
  it("Test", async () => {
    const { Diamond } = (await setupDiamondTest({
      facets: ["TestFacet"],
    })) as {
      namedAccounts: {
        [name: string]: { address: string } & { Diamond: TestFacet };
      };
      unnamedAccounts: ({ address: string } & { Diamond: TestFacet })[];
      diamondOwner: { address: string } & { Diamond: TestFacet };
      Diamond: TestFacet;
    };

    expect(await Diamond.fooBar("foo", "bar")).to.be.equal("foo+bar");
  });
});
