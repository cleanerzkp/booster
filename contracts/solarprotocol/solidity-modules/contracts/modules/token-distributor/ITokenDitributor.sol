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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenDitributor {
    struct Distribution {
        // Receiver of the distribution
        address destination;
        // If set, the distributed token should be swapped to to this token before sending.
        address swapTo;
        // Proportion of the total amount of the strategy.
        // Must be a multiple of 100.
        // Sum from all proportions of a strategy must be equal 100% (10000).
        uint16 proportion;
        // If set, the distributed and `swapTo` tokens should be added to liquidity.
        // The minted LP token will be sent to the `destination`.
        bool addLiquidity;
    }

    struct Strategy {
        // Token to be distributed
        address token;
        // If set, `token` should be swapped to this token before disributing.
        address swapTo;
        Distribution[] distributions;
    }

    error StrategyAlreadyExists(bytes32 id);
    error StrategyHasNoDistributions();
    error StrategyDistributionPortionsNot100();
    error StrategyDistributionsLengthMissmatch();
    error StrategyNotFound(bytes32 id);

    /**
     * @dev Returns the strategy with `strategyId`.
     *
     * @param strategyId Id of the distribution strategy.
     *
     * @return strategy The stored strategy.
     */
    function getTokenDistributionStrategy(bytes32 strategyId)
        external
        view
        returns (Strategy memory);
}
