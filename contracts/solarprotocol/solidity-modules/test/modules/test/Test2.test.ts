import "../../setup-chai";
import { expect } from "chai";
import setupDiamondTest from "../../setupDiamondTest";

describe("Test2Facet", () => {
  it("Test 2", async () => {
    const { Diamond } = await setupDiamondTest({
      facets: ["Test2Facet"],
    });
    expect(await Diamond.fooBar2("foo", "bar")).to.be.equal("foo+2+bar");
  });
});
