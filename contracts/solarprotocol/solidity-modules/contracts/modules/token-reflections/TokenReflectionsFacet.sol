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

import {ITokenReflections} from "./ITokenReflections.sol";
import {LibTokenReflections} from "./LibTokenReflections.sol";
import {LibAccessControl} from "../access/LibAccessControl.sol";
import {LibRoles} from "../access/LibRoles.sol";
import {LibPausable} from "../pausable/LibPausable.sol";
import {LibSimpleBlacklist} from "../blacklist/LibSimpleBlacklist.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenReflectionsFacet is ITokenReflections {
    using SafeERC20 for IERC20;

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsClaimRewards() external {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted();

        LibTokenReflections.claimRewards(msg.sender);
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsRewardsOf(address account)
        external
        view
        returns (uint256 rewards)
    {
        rewards = LibTokenReflections.rewardsOf(account);
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsGetTotalRewardsAdded()
        external
        view
        returns (uint256 totalRewardsAdded)
    {
        totalRewardsAdded = LibTokenReflections.getTotalRewardsAdded();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsGetTotalRewardsClaimed()
        external
        view
        returns (uint256 totalRewardsClaimed)
    {
        totalRewardsClaimed = LibTokenReflections.getTotalRewardsClaimed();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsGetUserRewardsClaimed(address account)
        external
        view
        returns (uint256 userRewardsClaimed)
    {
        userRewardsClaimed = LibTokenReflections.getUserRewardsClaimed(account);
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsIsEnabled() external view returns (bool enabled) {
        enabled = LibTokenReflections.isEnabled();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsEnable() external {
        LibAccessControl.enforceRole(LibRoles.TOKEN_REFLECTION_MANAGER);

        LibTokenReflections.enable();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsDisable() external {
        LibAccessControl.enforceRole(LibRoles.TOKEN_REFLECTION_MANAGER);

        LibTokenReflections.disable();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsIsExemptFromReflections(address account)
        external
        view
        returns (bool)
    {
        return LibTokenReflections.isExemptFromReflections(account);
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsSetExemptFromReflections(
        address account,
        bool flag
    ) external {
        LibAccessControl.enforceRole(LibRoles.TOKEN_REFLECTION_MANAGER);

        LibTokenReflections.setExemptFromReflections(account, flag);
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsGetRewardsToken()
        external
        view
        returns (address rewardsToken)
    {
        rewardsToken = LibTokenReflections.getRewardsToken();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsGetRewardsTokenVault()
        external
        view
        returns (address rewardsTokenVault)
    {
        rewardsTokenVault = LibTokenReflections.getRewardsTokenVault();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsGetInfoResponse()
        external
        view
        returns (
            ITokenReflections.ReflectionsInfoResponse
                memory tokenReflectionsInfoResponse
        )
    {
        tokenReflectionsInfoResponse = LibTokenReflections
            .getReflectionsInfoResponse();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsAddRewards(uint256 amount) external {
        LibAccessControl.enforceRole(LibRoles.TOKEN_REFLECTION_MANAGER);

        IERC20 rewardsToken = IERC20(LibTokenReflections.getRewardsToken());
        address rewardsTokenVault = LibTokenReflections.getRewardsTokenVault();

        LibTokenReflections.updateRewardsTokenVaultBalance();
        rewardsToken.safeTransferFrom(msg.sender, rewardsTokenVault, amount);
        LibTokenReflections.updateRewardsAmountPendingInVault();
        LibTokenReflections.addRewardsAmountPending();
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsBalanceOf(address account)
        external
        view
        returns (uint256 balance)
    {
        balance = LibTokenReflections.balanceOf(account);
    }

    /**
     * @inheritdoc ITokenReflections
     */
    function tokenReflectionsBonusBalanceOf(address account)
        external
        view
        returns (uint256 bonusBalance)
    {
        bonusBalance = LibTokenReflections.bonusBalanceOf(account);
    }
}
