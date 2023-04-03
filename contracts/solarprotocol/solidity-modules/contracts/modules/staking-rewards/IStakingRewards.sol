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
interface IStakingRewards {
    error StakingRewards__AmountTooSmall(uint256 amount);
    error StakingRewards__RewardsTokenStorageNotFound(address token);
    error StakingRewards__RewardsTokenStorageAlreadyInitialized(address token);
    error StakingRewards__EnforcedDurationNotFinished();
    error StakingRewards__RewardRateIsZero();
    error StakingRewards__RewardsBalanceTooLow();
    error StakingRewards__DurationTooSmall();
    error StakingRewards__DurationNotFinished();

    event StakingRewards__Staked(address account, uint256 amount);
    event StakingRewards__Unstaked(address account, uint256 amount);
    event StakingRewards__RewardsClaimed(
        address account,
        address token,
        uint256 amount
    );
    event StakingRewards__RewardsAdded(address token, uint256 amount);
    event StakingRewards__DurationUpdated(address token, uint256 duration);

    function StakingRewards__claimRewards(IERC20 rewardsToken)
        external
        returns (uint256 rewards);

    function StakingRewards__rewardsOf(IERC20 rewardsToken, address account)
        external
        view
        returns (uint256 rewards);

    function StakingRewards__balanceOf(address account)
        external
        view
        returns (uint256 balance);
}
// slither-disable-end naming-convention
