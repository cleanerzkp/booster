// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";

contract TestReceiveFacet {
    event EtherReceived(address sender, uint256 amount);

    // solhint-disable-next-line no-empty-blocks
    function receiveFallback() external {}

    //slither-disable-next-line locked-ether
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }
}
