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

import {IStakingRewards, IERC20, SafeERC20} from "./IStakingRewards.sol";
import {IStakingRewardsAdmin} from "./IStakingRewardsAdmin.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Main library for the staking-rewards module. It works like a virtual staking contract.
 *
 * ATTENTION: This library does only store staked balance and total supply.
 * It does not handle transfers of the staked tokens!
 * All transfers of the staked tokens (regardless of ERC) must be handled by the consumer of this library!
 *
 * The library is based of Synthetix staking contract's simplified version (by https://twitter.com/ProgrammerSmart)
 * See: https://solidity-by-example.org/defi/staking-rewards/
 */
library LibStakingRewards {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RewardsTokenStorage {
        IERC20 token;
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
        // User address => rewardsPerTokenStored
        mapping(address => uint256) userRewardsPerTokenPaid;
        // User address => rewards to be claimed
        mapping(address => uint256) rewards;
    }

    struct Storage {
        uint256 totalSupply;
        uint32 defaultDuration;
        mapping(uint8 => EnumerableSet.AddressSet) rewardTokens;
        mapping(address => uint256) balanceOf;
        mapping(IERC20 => RewardsTokenStorage) rewardsTokenStorage;
    }

    uint8 private constant INNER_STRUCT = 0;

    bytes32 private constant STORAGE_SLOT =
        keccak256("solar-labs.contracts.staking-rewards.LibStakingRewards");

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

    // slither-disable-start naming-convention
    event StakingRewards__RewardsAdded(address token, uint256 amount);
    event StakingRewards__DefaultDurationUpdated(uint256 duration);
    event StakingRewards__DurationUpdated(address token, uint256 duration);
    event StakingRewards__Staked(address account, uint256 amount);
    event StakingRewards__Unstaked(address account, uint256 amount);
    event StakingRewards__RewardsClaimed(
        address account,
        address token,
        uint256 amount
    );

    // slither-disable-end naming-convention

    /**
     * @dev Stakes `amount` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to stake
     */
    function stake(address account, uint256 amount) internal {
        if (amount == 0) {
            // slither-disable-next-line naming-convention
            revert IStakingRewards.StakingRewards__AmountTooSmall(amount);
        }

        _updateRewards(account);

        Storage storage s = _storage();
        s.balanceOf[account] += amount;
        s.totalSupply += amount;

        // slither-disable-next-line naming-convention
        emit StakingRewards__Staked(account, amount);
    }

    /**
     * @dev Unstakes `amount` for `account`.
     *
     * @param account Address of the user account
     * @param amount The amount to unstake
     */
    function unstake(address account, uint256 amount) internal {
        if (amount == 0) {
            // slither-disable-next-line naming-convention
            revert IStakingRewards.StakingRewards__AmountTooSmall(amount);
        }

        _updateRewards(account);

        Storage storage s = _storage();
        s.balanceOf[account] -= amount;
        s.totalSupply -= amount;

        // slither-disable-next-line naming-convention
        emit StakingRewards__Unstaked(account, amount);
    }

    /**
     * @dev Claims the `account`'s pending `rewardsToken` rewards.
     *
     * @param rewardsToken The rewards token context.
     * @param account Address of the account.
     */
    function claimRewards(IERC20 rewardsToken, address account)
        internal
        returns (uint256 rewards)
    {
        RewardsTokenStorage storage rts = getRewardsTokenStorage(rewardsToken);

        _updateRewards(rewardsToken, account);

        rewards = rts.rewards[account];
        if (rewards > 0) {
            rts.rewards[account] = 0;
            rewardsToken.safeTransfer(account, rewards);

            // slither-disable-next-line naming-convention
            emit StakingRewards__RewardsClaimed(
                account,
                address(rewardsToken),
                rewards
            );
        }
    }

    /**
     * @dev Returns the amount of `rewardsToken` the `account` can claim.
     *
     * @param rewardsToken The rewards token context.
     * @param account Address of the account.
     *
     * @return rewards Amount of rewards the `account` can claim.
     */
    function rewardsOf(IERC20 rewardsToken, address account)
        internal
        view
        returns (uint256 rewards)
    {
        RewardsTokenStorage storage rts = getRewardsTokenStorage(rewardsToken);

        rewards =
            ((_storage().balanceOf[account] *
                (rewardPerToken(rewardsToken) -
                    rts.userRewardsPerTokenPaid[account])) / 1e18) +
            rts.rewards[account];
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
     * @dev Returns the last timestamp when rewards where applicable for `rewardsToken`.
     * Current timestamp if the reward duration is not finished yet, `finishedAt` otherwise.
     *
     * @param rewardsToken The rewards token context.
     *
     * @return timestamp The smaller of the 2 timestamps.
     */
    function lastTimeRewardApplicable(IERC20 rewardsToken)
        internal
        view
        returns (uint32 timestamp)
    {
        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        timestamp = uint32(block.timestamp % 2**32);
        // solhint-enable
        uint32 finishedAt = getRewardsTokenStorage(rewardsToken).finishedAt;

        if (finishedAt < timestamp) {
            timestamp = finishedAt;
        }
    }

    /**
     * @dev Calculates the reward amount per token.
     *
     * @param rewardsToken The rewards token context.
     *
     * @return rewardPerToken The calculated rewardPerToken amount.
     */
    function rewardPerToken(IERC20 rewardsToken)
        internal
        view
        returns (uint256)
    {
        RewardsTokenStorage storage rts = getRewardsTokenStorage(rewardsToken);

        uint256 totalSupply = _storage().totalSupply;

        if (totalSupply == 0) {
            return rts.rewardsPerTokenStored;
        }

        return
            rts.rewardsPerTokenStored +
            (rts.rewardRate *
                (lastTimeRewardApplicable(rewardsToken) - rts.updatedAt) *
                1e18) /
            totalSupply;
    }

    function getTotalSupply() internal view returns (uint256 totalSupply) {
        totalSupply = _storage().totalSupply;
    }

    function addRewards(IERC20 rewardsToken, uint256 amount) internal {
        Storage storage s = _storage();
        RewardsTokenStorage storage rts = s.rewardsTokenStorage[rewardsToken];

        if (rts.token != rewardsToken) {
            rts.token = rewardsToken;
            rts.duration = s.defaultDuration;
            // slither-disable-next-line unused-return
            _rewardTokensSet().add(address(rewardsToken));
        }

        _updateRewards(rewardsToken, address(0));

        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        // solhint-enable

        if (blockTimestamp >= rts.finishedAt) {
            rts.rewardRate = amount / rts.duration;
        } else {
            uint256 remainingRewards = (rts.finishedAt - blockTimestamp) *
                rts.rewardRate;
            rts.rewardRate = (amount + remainingRewards) / rts.duration;
        }

        if (rts.rewardRate == 0) {
            // slither-disable-next-line naming-convention
            revert IStakingRewards.StakingRewards__RewardRateIsZero();
        }

        if (
            rts.rewardRate * rts.duration >
            rewardsToken.balanceOf(address(this))
        ) {
            // slither-disable-next-line naming-convention
            revert IStakingRewards.StakingRewards__RewardsBalanceTooLow();
        }

        rts.finishedAt = blockTimestamp + rts.duration;
        rts.updatedAt = blockTimestamp;

        // slither-disable-next-line naming-convention
        emit StakingRewards__RewardsAdded(address(rewardsToken), amount);
    }

    /**
     * @dev Returns the storage struct with data contextualized for the `rewardsToken`.
     *
     * @param rewardsToken The rewards token context.
     *
     * @return rts The storage struct with the `rewardsToken` related data.
     */
    function getRewardsTokenStorage(IERC20 rewardsToken)
        internal
        view
        returns (RewardsTokenStorage storage rts)
    {
        rts = _storage().rewardsTokenStorage[rewardsToken];

        if (rts.token != rewardsToken) {
            // slither-disable-next-line naming-convention
            revert IStakingRewards.StakingRewards__RewardsTokenStorageNotFound(
                address(rewardsToken)
            );
        }
    }

    /**
     * Updates the duration of rewards distribution.
     * If the provided `rewardsTokenAddress` is the zero address the `defaultDuration` will be updated.
     * Emits an {StakingRewards__DurationUpdated} event.
     *
     * @param rewardsTokenAddress The rewards token context.
     * @param duration The new duration.
     */
    function setRewardsDuration(address rewardsTokenAddress, uint32 duration)
        internal
    {
        if (duration == 0) {
            // slither-disable-next-line naming-convention
            revert IStakingRewards.StakingRewards__DurationTooSmall();
        }

        if (rewardsTokenAddress == address(0)) {
            _storage().defaultDuration = duration;
            // slither-disable-next-line naming-convention
            emit StakingRewards__DurationUpdated(rewardsTokenAddress, duration);
            return;
        }

        RewardsTokenStorage storage rts = getRewardsTokenStorage(
            IERC20(rewardsTokenAddress)
        );

        // solhint-disable-next-line not-rely-on-time
        if (rts.finishedAt >= block.timestamp) {
            // slither-disable-next-line naming-convention
            revert IStakingRewards.StakingRewards__DurationNotFinished();
        }

        rts.duration = duration;

        // slither-disable-next-line naming-convention
        emit StakingRewards__DurationUpdated(rewardsTokenAddress, duration);
    }

    function getRewardsDuration(address rewardsTokenAddress)
        internal
        view
        returns (uint32 duration)
    {
        if (rewardsTokenAddress == address(0)) {
            return _storage().defaultDuration;
        }

        return getRewardsTokenStorage(IERC20(rewardsTokenAddress)).duration;
    }

    function getRewarsTokens() internal view returns (address[] memory) {
        return _rewardTokensSet().values();
    }

    /**
     * Updates the `account`'s rewards and `rewardsPerTokenStored`.
     *
     * @param account Address of the account.
     */
    function _updateRewards(address account) private {
        EnumerableSet.AddressSet storage rewardTokens = _rewardTokensSet();

        uint256 length = rewardTokens.length();
        uint256 index = 0;

        while (index < length) {
            _updateRewards(IERC20(rewardTokens.at(index)), account);

            unchecked {
                ++index;
            }
        }
    }

    /**
     * Updates the `account`'s rewards and `rewardsPerTokenStored`.
     *
     * @param rewardsToken The rewards token context.
     * @param account Address of the account.
     */
    function _updateRewards(IERC20 rewardsToken, address account) private {
        RewardsTokenStorage storage rts = getRewardsTokenStorage(rewardsToken);

        rts.rewardsPerTokenStored = rewardPerToken(rewardsToken);
        rts.updatedAt = lastTimeRewardApplicable(rewardsToken);

        if (account != address(0)) {
            rts.rewards[account] = rewardsOf(rewardsToken, account);
            rts.userRewardsPerTokenPaid[account] = rts.rewardsPerTokenStored;
        }
    }

    function _rewardTokensSet()
        private
        view
        returns (EnumerableSet.AddressSet storage rewardTokens)
    {
        rewardTokens = _storage().rewardTokens[INNER_STRUCT];
    }
}
