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

import {LibTokenDistributor} from "./LibTokenDistributor.sol";
import {ITokenDitributor} from "./ITokenDitributor.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Library to migrate the token distribution strategies from the old storage slot to new V2 slot.
 * This is needed because of the nested Structs that can't be updated.
 */
library LibTokenDistributorV1Migration {
    struct Distribution {
        address destination;
        uint256 proportion;
    }

    struct Strategy {
        IERC20 token;
        Distribution[] distributions;
    }

    struct Storage {
        mapping(bytes32 => Strategy) strategyMap;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256(
            "solarprotocol.contracts.token-distributor.LibTokenDistributor"
        );

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            s.slot := slot
        }
        // solhint-enable
    }

    /**
     * @dev Migrates the old V1 `strategyId` to V2.
     *
     * @param strategyId Id of the distribution strategy.
     */
    function migrate(bytes32 strategyId) internal {
        Strategy memory oldStrategy = _storage().strategyMap[strategyId];

        if (oldStrategy.distributions.length == 0) {
            return;
        }

        uint256 distributionsLength = oldStrategy.distributions.length;

        ITokenDitributor.Distribution[]
            memory distributions = new ITokenDitributor.Distribution[](
                distributionsLength
            );

        for (uint256 index = 0; index < distributionsLength; ) {
            distributions[index] = ITokenDitributor.Distribution({
                destination: oldStrategy.distributions[index].destination,
                proportion: uint16(
                    oldStrategy.distributions[index].proportion * 100
                ),
                swapTo: address(0),
                addLiquidity: false
            });
        }

        ITokenDitributor.Strategy memory newStrategy = ITokenDitributor
            .Strategy({
                token: address(oldStrategy.token),
                swapTo: address(0),
                distributions: distributions
            });

        LibTokenDistributor.add(strategyId, newStrategy);
    }
}
