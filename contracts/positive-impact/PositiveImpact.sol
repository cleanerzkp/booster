// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {Initializer} from "@solarprotocol/solidity-modules/contracts/modules/utils/initializer/Initializer.sol";
import {PausableFacet, LibPausable} from "@solarprotocol/solidity-modules/contracts/modules/pausable/PausableFacet.sol";
import {SimpleBlacklistFacet, LibSimpleBlacklist} from "@solarprotocol/solidity-modules/contracts/modules/blacklist/SimpleBlacklistFacet.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PositiveImpact is Initializer, PausableFacet, SimpleBlacklistFacet {
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public treasury;

    event Contributed(address account, uint256 amount);

    function contribute(uint256 amount) external {
        require(amount > 0, "Amount is 0");

        token.safeTransferFrom(msg.sender, treasury, amount);

        emit Contributed(msg.sender, amount);
    }

    function updateTreasuryAddress(
        address newTreasuryAddress
    ) external onlyOwner {
        treasury = newTreasuryAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == _getOwner(), "NOT_AUTHORIZED");
        _;
    }

    function _getOwner() internal view returns (address ownerAddress) {
        // solhint-disable no-inline-assembly
        // slither-ignore-next-line assembly
        assembly {
            ownerAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
        // solhint-enable
    }

    function initialize(IERC20 token_, address treasury_) external initializer {
        token = token_;
        treasury = treasury_;
    }
}
