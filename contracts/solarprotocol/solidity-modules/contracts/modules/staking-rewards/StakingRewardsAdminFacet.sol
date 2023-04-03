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

import {LibStakingRewards, IStakingRewards, IStakingRewardsAdmin, IERC20, SafeERC20} from "./LibStakingRewards.sol";
import {LibPausable} from "../pausable/LibPausable.sol";
import {LibSimpleBlacklist} from "../blacklist/SimpleBlacklistFacet.sol";
import {LibAccessControl} from "../access/AccessControlFacet.sol";
import {LibRoles} from "../access/LibRoles.sol";

// solhint-disable func-name-mixedcase
// slither-disable-start naming-convention
contract StakingRewardsAdminFacet is IStakingRewardsAdmin {
    using SafeERC20 for IERC20;

    function StakingRewards__notifyRewards(IERC20 rewardsToken, uint256 amount)
        external
        virtual
    {
        LibAccessControl.enforceRole(LibRoles.STAKING_REWARDS_MANAGER);

        LibStakingRewards.addRewards(rewardsToken, amount);
    }

    function StakingRewards__addRewards(IERC20 rewardsToken, uint256 amount)
        external
        virtual
    {
        LibAccessControl.enforceRole(LibRoles.STAKING_REWARDS_MANAGER);

        rewardsToken.safeTransferFrom(msg.sender, address(this), amount);

        LibStakingRewards.addRewards(rewardsToken, amount);
    }

    function StakingRewards__setRewardsDuration(
        address rewardsTokenAddress,
        uint32 duration
    ) external virtual {
        LibAccessControl.enforceRole(LibRoles.STAKING_REWARDS_MANAGER);

        LibStakingRewards.setRewardsDuration(rewardsTokenAddress, duration);
    }

    function StakingRewards__getRewardsDuration(address rewardsTokenAddress)
        external
        view
        virtual
        returns (uint32 duration)
    {
        duration = LibStakingRewards.getRewardsDuration(rewardsTokenAddress);
    }

    function StakingRewards__getRewardsTokenInfo(IERC20 rewardsTokenAddress)
        external
        view
        virtual
        returns (RewardsTokenInfo memory)
    {
        LibStakingRewards.RewardsTokenStorage storage rts = LibStakingRewards
            .getRewardsTokenStorage(rewardsTokenAddress);

        return
            RewardsTokenInfo({
                token: address(rts.token),
                rewardRate: rts.rewardRate,
                rewardsPerTokenStored: rts.rewardsPerTokenStored,
                finishedAt: rts.finishedAt,
                updatedAt: rts.updatedAt,
                duration: rts.duration
            });
    }

    function StakingRewards__getRewardsTokenInfos()
        external
        view
        virtual
        returns (RewardsTokenInfo[] memory rewardTokenInfos)
    {
        address[] memory rewardTokens = LibStakingRewards.getRewarsTokens();

        rewardTokenInfos = new RewardsTokenInfo[](rewardTokens.length);

        for (uint256 index = 0; index < rewardTokens.length; ++index) {
            LibStakingRewards.RewardsTokenStorage
                storage rts = LibStakingRewards.getRewardsTokenStorage(
                    IERC20(rewardTokens[index])
                );

            rewardTokenInfos[index] = RewardsTokenInfo({
                token: address(rts.token),
                rewardRate: rts.rewardRate,
                rewardsPerTokenStored: rts.rewardsPerTokenStored,
                finishedAt: rts.finishedAt,
                updatedAt: rts.updatedAt,
                duration: rts.duration
            });
        }
    }
}
// slither-disable-end naming-convention
