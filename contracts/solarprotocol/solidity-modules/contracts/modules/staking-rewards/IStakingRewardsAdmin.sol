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

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// solhint-disable func-name-mixedcase
// slither-disable-start naming-convention
interface IStakingRewardsAdmin {
    struct RewardsTokenInfo {
        address token;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardsPerTokenStored;
        // Timestamp of when the rewards finish
        uint32 finishedAt;
        // Minimum of last updated time and reward finish time
        uint32 updatedAt;
        // Duration of rewards to be paid out (in seconds)
        uint32 duration;
    }

    function StakingRewards__notifyRewards(IERC20 rewardsToken, uint256 amount)
        external;

    function StakingRewards__addRewards(IERC20 rewardsToken, uint256 amount)
        external;

    function StakingRewards__setRewardsDuration(
        address rewardsTokenAddress,
        uint32 duration
    ) external;
}
// slither-disable-end naming-convention
