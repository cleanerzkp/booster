// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";

contract TestFacet {
    function fooBar(string calldata foo, string calldata bar)
        external
        pure
        returns (string memory baz)
    {
        baz = string(abi.encodePacked(foo, "+", bar));
    }
}
