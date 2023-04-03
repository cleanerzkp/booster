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

interface ITokenReflections {
    struct ReflectionsInfoResponse {
        address rewardsTokenVault;
        // Kill switch to enable/disable the module
        bool enabled;
        // If set, will prevent the rewards from being added more often than the set duration
        bool enforceDuration;
        // Timestamp of when the rewards finish
        uint32 finishedAt;
        // Minimum of last updated time and reward finish time
        uint32 updatedAt;
        // Duration of rewards to be paid out (in seconds)
        uint32 duration;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardsPerTokenStored;
        // Total staked
        uint256 totalSupply;
        // Temporary storage for the `rewardsToken` balance of the `rewardsTokenVault`
        uint256 rewardsTokenVaultBalance;
        // Amount of rewards pending in the `rewardsTokenVault` to be added to distribution
        uint256 rewardsAmountPendingInVault;
        // Total amount of rewards ever added
        uint256 totalRewardsAdded;
        // Total amount of rewards ever claimed
        uint256 totalRewardsClaimed;
    }

    error TokenReflectionsRewardDurationNotFinished();
    error TokenReflectionsRewardRewardRateIsZero();
    error TokenReflectionsRewardsBalanceTooLow();

    /**
     * @dev Emitted when the token-taxes module is enabled.
     */
    event TokenReflectionsEnabled();

    /**
     * @dev Emitted when the token-taxes module is disabled.
     */
    event TokenReflectionsDisabled();

    /**
     * @dev Emitted when the `rewardsToken` is updated.
     */
    event TokenReflectionsRewardsTokenUpdated(address rewardsToken);

    /**
     * @dev Emitted when the `rewardsTokenVault` is updated.
     */
    event TokenReflectionsRewardsTokenVaultUpdated(address rewardsTokenVault);

    /**
     * @dev Emitted when new rewards are added to the rewards pool.
     */
    event TokenReflectionsRewardsAdded(uint256 amount);

    /**
     * @dev Emitted when the duration is updated.
     */
    event TokenReflectionsDurationUpdated(uint256 duration);

    /**
     * @dev Emitted when the exempt from reflection flag of `account` is set.
     */
    event TokenReflectionsSetExemptFlag(address account, bool flag);

    /**
     * @dev Emitted when the `enforceDuration` flag is set.
     */
    event TokenReflectionsSetEnforceDuration(bool flag);

    /**
     * @dev Claims the caller's pending rewards from the `rewardsTokenVault`.
     */
    function tokenReflectionsClaimRewards() external;

    /**
     * @dev Returns the amount of rewards the `account` can claim.
     *
     * @param account Address of the account.
     *
     * @return rewards Amount of rewards the `account` can claim.
     */
    function tokenReflectionsRewardsOf(address account)
        external
        view
        returns (uint256 rewards);

    /**
     * @dev Returns the total amount of tokens added as rewards.
     *
     * @return totalRewardsAdded Total amount of tokens added as rewards.
     */
    function tokenReflectionsGetTotalRewardsAdded()
        external
        view
        returns (uint256 totalRewardsAdded);

    /**
     * @dev Returns the total amount of rewards claimed by all users.
     *
     * @return totalRewardsClaimed Total amount of rewards claimed by all users.
     */
    function tokenReflectionsGetTotalRewardsClaimed()
        external
        view
        returns (uint256 totalRewardsClaimed);

    /**
     * @dev Returns the total amount of rewards `account` has claimed.
     *
     * @param account The account to get the claimed amount for.
     *
     * @return userRewardsClaimed Total amount of rewards `account` has ever claimed.
     */
    function tokenReflectionsGetUserRewardsClaimed(address account)
        external
        view
        returns (uint256 userRewardsClaimed);

    /**
     * @dev Returns true if the token-reflections module is enabled.
     */
    function tokenReflectionsIsEnabled() external view returns (bool enabled);

    /**
     * @dev Enables the token-reflections module.
     * Emits an {TokenTaxesEnabled} event.
     */
    function tokenReflectionsEnable() external;

    /**
     * @dev Disables the token-reflections module
     * Emits an {TokenTaxesDisabled} event.
     */
    function tokenReflectionsDisable() external;

    /**
     * @dev Checks if `account` is exempt from reflections.
     *
     * @return True if `account` is exempt from reflections.
     */
    function tokenReflectionsIsExemptFromReflections(address account)
        external
        view
        returns (bool);

    /**
     * @dev Sets the `account`'s exempt from reflection status to `flag`.
     * Emits an {TokenReflectionsSetExemptFlag} event.
     *
     * @param account The account to set the `flag` for.
     * @param flag The status flag.
     */
    function tokenReflectionsSetExemptFromReflections(
        address account,
        bool flag
    ) external;

    /**
     * @dev Returns the current `rewardsToken`.
     *
     * @return rewardsToken Address of the currently stored rewardsToken.
     */
    function tokenReflectionsGetRewardsToken()
        external
        view
        returns (address rewardsToken);

    /**
     * @dev Returns the current `rewardsTokenVault`.
     *
     * @return rewardsTokenVault Address of the currently stored rewardsTokenVault.
     */
    function tokenReflectionsGetRewardsTokenVault()
        external
        view
        returns (address rewardsTokenVault);

    /**
     * @dev Returns an info response. Mainly for testing and debuggind.
     *
     * @return reflectionsInfoResponse An instance of the ITokenReflections.ReflectionsInfoResponse struct, with data from the storage.
     */
    function tokenReflectionsGetInfoResponse()
        external
        view
        returns (ITokenReflections.ReflectionsInfoResponse memory);

    /**
     * @dev Used by the manager to add rewards to the staking contract manualy.
     *
     * @param amount THe amount of reward token to add from the msg.sender balance to the rewards vault.
     */
    function tokenReflectionsAddRewards(uint256 amount) external;

    /**
     * @dev Returns the tracked staking balance of a user.
     *
     * @param account The address of the user account.
     *
     * @return balance The tracked staking balance of `account`.
     */
    function tokenReflectionsBalanceOf(address account)
        external
        view
        returns (uint256 balance);

    /**
     * @dev Returns the tracked bonus balance of a user.
     *
     * @param account The address of the user account.
     *
     * @return bonusBalance The tracked bonus balance of `account`.
     */
    function tokenReflectionsBonusBalanceOf(address account)
        external
        view
        returns (uint256 bonusBalance);
}
