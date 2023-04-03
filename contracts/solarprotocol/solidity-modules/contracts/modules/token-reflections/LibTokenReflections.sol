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
import {LibSoloToken} from "../solo-token/LibSoloToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Library for the token-reflection module. It works like a virtual staking contract.
 * On each transaction the solo-token module notifies the `accountBalanceUpdated()` function
 * about the changed balances of each account, which will work like automatic staking/unstaking
 * if the account is not exempt from reflections, to update the account's rewards and the totalSupply.
 *
 * The library is based of Synthetix staking contract's simplified version (by https://twitter.com/ProgrammerSmart)
 * See: https://solidity-by-example.org/defi/staking-rewards/
 */
library LibTokenReflections {
    using SafeERC20 for IERC20;
    using Address for address;

    struct Storage {
        IERC20 rewardsToken;
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
        // Amount of staked tokens by a user
        mapping(address => uint256) balanceOf;
        // User address => rewardsPerTokenStored
        mapping(address => uint256) userRewardsPerTokenPaid; // User address => rewardsPerTokenStored
        // Total amount of rewards claimed by user
        mapping(address => uint256) userRewardsClaimed;
        // User address => rewards to be claimed
        mapping(address => uint256) rewards;
        // Mapping of addresses exempt from reflections.
        mapping(address => bool) exemptFromReflections;
        // Amount of bonus tokens by a user
        mapping(address => uint256) bonusBalanceOf;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.token-taxes.LibTokenReflections");

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
     * @dev Replacement of stake/unstake functions.
     * Called during token transfers to stake or unstake automatically.
     *
     * @param account Address of the account.
     */
    function accountBalanceUpdated(address account) internal {
        Storage storage s = _storage();

        if (!s.enabled) {
            return;
        }

        if (isExemptFromReflections(account)) {
            return;
        }

        uint256 stakedBalance = s.balanceOf[account];
        uint256 tokenBalance = LibSoloToken.balanceOf(account);

        if (tokenBalance > stakedBalance) {
            stake(account, tokenBalance - stakedBalance, false);
        } else if (stakedBalance > tokenBalance) {
            unstake(account, stakedBalance - tokenBalance, false);
        }
    }

    /**
     * @dev Stakes `amount` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to stake
     */
    function stake(address account, uint256 amount) internal {
        stake(account, amount, false);
    }

    /**
     * @dev Stakes `amount` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to stake
     * @param isBonus If true, the `amount` will be staked as bonus
     */
    function stake(
        address account,
        uint256 amount,
        bool isBonus
    ) internal {
        Storage storage s = _storage();

        _updateRewards(account);

        if (!isBonus) {
            s.balanceOf[account] += amount;
        } else {
            s.bonusBalanceOf[account] += amount;
        }

        s.totalSupply += amount;
    }

    /**
     * @dev Unstakes `amount` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to unstake
     */
    function unstake(address account, uint256 amount) internal {
        unstake(account, amount, false);
    }

    /**
     * @dev Unstakes `amount` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to unstake
     * @param isBonus If true, the `amount` will be unstaked as bonus
     */
    function unstake(
        address account,
        uint256 amount,
        bool isBonus
    ) internal {
        Storage storage s = _storage();

        _updateRewards(account);

        if (!isBonus) {
            s.balanceOf[account] -= amount;
        } else {
            s.bonusBalanceOf[account] -= amount;
        }

        s.totalSupply -= amount;
    }

    /**
     * @dev Claims the `account`'s pending rewards from the `rewardsTokenVault` to the `account`.
     *
     * @param account Address of the account.
     */
    function claimRewards(address account) internal {
        Storage storage s = _storage();

        if (!s.enabled) {
            return;
        }

        _updateRewards(account);

        uint256 rewards = s.rewards[account];
        if (rewards > 0) {
            s.rewards[account] = 0;
            s.totalRewardsClaimed += rewards;
            s.userRewardsClaimed[account] += rewards;
            // slither-disable-next-line arbitrary-send-erc20
            s.rewardsToken.safeTransferFrom(
                s.rewardsTokenVault,
                account,
                rewards
            );
        }
    }

    /**
     * @dev Returns the amount of rewards the `account` can claim.
     *
     * @param account Address of the account.
     *
     * @return rewards Amount of rewards the `account` can claim.
     */
    function rewardsOf(address account)
        internal
        view
        returns (uint256 rewards)
    {
        Storage storage s = _storage();

        uint256 accountBalance = s.balanceOf[account] +
            s.bonusBalanceOf[account];

        rewards =
            ((accountBalance *
                (rewardPerToken() - s.userRewardsPerTokenPaid[account])) /
                1e18) +
            s.rewards[account];
    }

    /**
     * @dev Returns the tracked staking balance of a user.
     *
     * @param account The address of the user account.
     *
     * @return balance The tracked staking balance of `account`.
     */
    function balanceOf(address account)
        internal
        view
        returns (uint256 balance)
    {
        balance = _storage().balanceOf[account];
    }

    /**
     * @dev Returns the tracked bonus balance of a user.
     *
     * @param account The address of the user account.
     *
     * @return bonusBalance The tracked bonus balance of `account`.
     */
    function bonusBalanceOf(address account)
        internal
        view
        returns (uint256 bonusBalance)
    {
        bonusBalance = _storage().bonusBalanceOf[account];
    }

    /**
     * @dev Returns the last timestamp when rewards where applicable.
     * Current timestamp if the reward duration is not finished yet, `finishedAt` otherwise.
     *
     * @return timestamp The smaller of the 2 timestamps.
     */
    function lastTimeRewardApplicable()
        internal
        view
        returns (uint32 timestamp)
    {
        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        timestamp = uint32(block.timestamp % 2**32);
        // solhint-enable
        uint32 finishedAt = _storage().finishedAt;

        if (finishedAt < timestamp) {
            timestamp = finishedAt;
        }
    }

    /**
     * @dev Calculates the reward amount per token.
     *
     * @return rewardPerToken The calculated rewardPerToken amount.
     */
    function rewardPerToken() internal view returns (uint256) {
        Storage storage s = _storage();

        if (s.totalSupply == 0) {
            return s.rewardsPerTokenStored;
        }

        return
            s.rewardsPerTokenStored +
            (s.rewardRate * (lastTimeRewardApplicable() - s.updatedAt) * 1e18) /
            s.totalSupply;
    }

    /**
     * @dev Stores the current `rewardsToken` balance of the `rewardsTokenVault` in `rewardsTokenVaultBalance`.
     * Should be called before tokens are sent to the `rewardsTokenVault`.
     */
    function updateRewardsTokenVaultBalance() internal {
        Storage storage s = _storage();

        if (!s.enabled) {
            return;
        }

        s.rewardsTokenVaultBalance = s.rewardsToken.balanceOf(
            s.rewardsTokenVault
        );
    }

    /**
     * @dev Calculates the `rewardsAmountPendingInVault` by subtracting `rewardsTokenVaultBalance`
     * from the current `rewardsToken` balance of the `rewardsTokenVault`.
     * Should be called after tokens are sent to the `rewardsTokenVault`.
     */
    function updateRewardsAmountPendingInVault() internal {
        Storage storage s = _storage();

        if (!s.enabled) {
            return;
        }

        s.rewardsAmountPendingInVault +=
            s.rewardsToken.balanceOf(s.rewardsTokenVault) -
            s.rewardsTokenVaultBalance;

        s.rewardsTokenVaultBalance = 0;
    }

    /**
     * @dev Adds the `rewardsAmountPendingInVault` to the rewards pool.
     * Better to call after `updateRewardsAmountPendingInVault()`, but not mandatory.
     */
    function addRewardsAmountPending() internal {
        Storage storage s = _storage();

        uint256 amount = s.rewardsAmountPendingInVault;
        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        // solhint-enable

        // Ensure that there is an amount to be added and last duration period expired (if configured so).
        if (
            !s.enabled ||
            amount == 0 ||
            (s.enforceDuration && blockTimestamp < s.finishedAt)
        ) {
            return;
        }

        _updateRewards(address(0));

        if (blockTimestamp >= s.finishedAt) {
            s.rewardRate = amount / s.duration;
        } else {
            uint256 remainingRewards = (s.finishedAt - blockTimestamp) *
                s.rewardRate;
            s.rewardRate = (amount + remainingRewards) / s.duration;
        }

        if (s.rewardRate == 0) {
            revert ITokenReflections.TokenReflectionsRewardRewardRateIsZero();
        }

        if (
            s.rewardRate * s.duration >
            s.rewardsToken.balanceOf(s.rewardsTokenVault)
        ) {
            revert ITokenReflections.TokenReflectionsRewardsBalanceTooLow();
        }

        s.totalRewardsAdded += amount;
        s.rewardsAmountPendingInVault = 0;
        s.finishedAt = blockTimestamp + s.duration;
        s.updatedAt = blockTimestamp;

        emit TokenReflectionsRewardsAdded(amount);
    }

    /**
     * @dev Returns true if the token-reflections module is enabled.
     */
    function isEnabled() internal view returns (bool enabled) {
        enabled = _storage().enabled;
    }

    /**
     * @dev Enables the token-reflections module.
     * Emits an {TokenTaxesEnabled} event.
     */
    function enable() internal {
        _storage().enabled = true;

        emit TokenReflectionsEnabled();
    }

    /**
     * @dev Disables the token-reflections module
     * Emits an {TokenTaxesDisabled} event.
     */
    function disable() internal {
        _storage().enabled = false;

        emit TokenReflectionsDisabled();
    }

    /**
     * Updates the duration of rewards distribution.
     * Emits an {TokenReflectionsDurationUpdated} event.
     *
     * @param duration The new duration.
     */
    function setRewardsDuration(uint32 duration) internal {
        Storage storage s = _storage();

        // solhint-disable-next-line not-rely-on-time
        if (s.finishedAt >= block.timestamp) {
            revert ITokenReflections.TokenReflectionsRewardDurationNotFinished();
        }

        s.duration = duration;

        emit TokenReflectionsDurationUpdated(duration);
    }

    /**
     * @dev Checks if `account` is exempt from reflections.
     *
     * @return True if `account` is exempt from reflections.
     */
    function isExemptFromReflections(address account)
        internal
        view
        returns (bool)
    {
        return
            account == address(this) ||
            _storage().exemptFromReflections[account] ||
            account.isContract();
    }

    /**
     * @dev Sets the `account`'s exempt from reflection status to `flag`.
     * Emits an {TokenReflectionsSetExemptFlag} event.
     *
     * @param account The account to set the `flag` for.
     * @param flag The status flag.
     */
    function setExemptFromReflections(address account, bool flag) internal {
        Storage storage s = _storage();

        if (flag) {
            unstake(account, s.balanceOf[account]);
        } else {
            accountBalanceUpdated(account);
        }

        s.exemptFromReflections[account] = flag;

        emit TokenReflectionsSetExemptFlag(account, flag);
    }

    /**
     * @dev Updates the stored `rewardsToken`.
     * Emits an {TokenReflectionsRewardsTokenUpdated} event.
     *
     * @param rewardsToken Address of the rewardsToken.
     */
    function setRewardsToken(address rewardsToken) internal {
        _storage().rewardsToken = IERC20(rewardsToken);

        emit TokenReflectionsRewardsTokenUpdated(rewardsToken);
    }

    /**
     * @dev Returns the current `rewardsToken`.
     *
     * @return rewardsToken Address of the currently stored rewardsToken.
     */
    function getRewardsToken() internal view returns (address rewardsToken) {
        rewardsToken = address(_storage().rewardsToken);
    }

    /**
     * @dev Updates the stored `rewardsTokenVault`.
     * Emits an {TokenReflectionsRewardsTokenVaultUpdated} event.
     *
     * @param rewardsTokenVault Address of the rewardsTokenVault.
     */
    function setRewardsTokenVault(address rewardsTokenVault) internal {
        _storage().rewardsTokenVault = rewardsTokenVault;

        emit TokenReflectionsRewardsTokenVaultUpdated(rewardsTokenVault);
    }

    /**
     * @dev Returns true if `account` is the `rewardsTokenVault`.
     */
    function isRewardsTokenVault(address account) internal view returns (bool) {
        return account == _storage().rewardsTokenVault;
    }

    /**
     * @dev Returns the current `rewardsTokenVault`.
     *
     * @return rewardsTokenVault Address of the currently stored rewardsTokenVault.
     */
    function getRewardsTokenVault()
        internal
        view
        returns (address rewardsTokenVault)
    {
        rewardsTokenVault = _storage().rewardsTokenVault;
    }

    /**
     * @dev Sets the `enforceDuration` status to `flag`.
     * Emits an {TokenReflectionsSetEnforceDuration} event.
     *
     * @param flag The status flag.
     */
    function setEnforceDuration(bool flag) internal {
        _storage().enforceDuration = flag;

        emit TokenReflectionsSetEnforceDuration(flag);
    }

    /**
     * @dev Returns the total amount of tokens added as rewards.
     *
     * @return totalRewardsAdded Total amount of tokens added as rewards.
     */
    function getTotalRewardsAdded()
        internal
        view
        returns (uint256 totalRewardsAdded)
    {
        totalRewardsAdded = _storage().totalRewardsAdded;
    }

    /**
     * @dev Returns the total amount of rewards claimed by all users.
     *
     * @return totalRewardsClaimed Total amount of rewards claimed by all users.
     */
    function getTotalRewardsClaimed()
        internal
        view
        returns (uint256 totalRewardsClaimed)
    {
        totalRewardsClaimed = _storage().totalRewardsClaimed;
    }

    /**
     * @dev Returns the total amount of rewards `account` has claimed.
     *
     * @param account The account to get the claimed amount for.
     *
     * @return userRewardsClaimed Total amount of rewards `account` has ever claimed.
     */
    function getUserRewardsClaimed(address account)
        internal
        view
        returns (uint256 userRewardsClaimed)
    {
        userRewardsClaimed = _storage().userRewardsClaimed[account];
    }

    /**
     * @dev Returns an info response. Mainly for testing and debuggind.
     *
     * @return reflectionsInfoResponse An instance of the ITokenReflections.ReflectionsInfoResponse struct, with data from the storage.
     */
    function getReflectionsInfoResponse()
        internal
        view
        returns (ITokenReflections.ReflectionsInfoResponse memory)
    {
        Storage storage s = _storage();

        return
            ITokenReflections.ReflectionsInfoResponse({
                rewardsTokenVault: s.rewardsTokenVault,
                enabled: s.enabled,
                enforceDuration: s.enforceDuration,
                finishedAt: s.finishedAt,
                updatedAt: s.updatedAt,
                duration: s.duration,
                rewardRate: s.rewardRate,
                rewardsPerTokenStored: s.rewardsPerTokenStored,
                totalSupply: s.totalSupply,
                rewardsTokenVaultBalance: s.rewardsTokenVaultBalance,
                rewardsAmountPendingInVault: s.rewardsAmountPendingInVault,
                totalRewardsAdded: s.totalRewardsAdded,
                totalRewardsClaimed: s.totalRewardsClaimed
            });
    }

    /**
     * Updates the `account`'s rewards and `rewardsPerTokenStored`.
     *
     * @param account Address of the account.
     */
    function _updateRewards(address account) private {
        Storage storage s = _storage();

        s.rewardsPerTokenStored = rewardPerToken();
        s.updatedAt = lastTimeRewardApplicable();

        if (account != address(0)) {
            s.rewards[account] = rewardsOf(account);
            s.userRewardsPerTokenPaid[account] = s.rewardsPerTokenStored;
        }
    }
}
