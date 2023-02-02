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

import {ITokenLocker} from "./ITokenLocker.sol";
import {IERC20Mintable} from "../interfaces/IERC20Mintable.sol";
import {LibERC20} from "@solarprotocol/solidity-modules/contracts/modules/token/ERC20/LibERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibTokenLocker {
    using SafeERC20 for IERC20Mintable;

    struct Storage {
        IERC20Mintable lockedToken;
        mapping(address => mapping(uint32 => ITokenLocker.Lock)) accountDurationLock;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarlabs.contracts.token-locker.LibTokenLocker");

    uint256 internal constant DENOMINATOR = 1e10;

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

    event Deposit(
        address account,
        uint256 amount,
        uint256 reward,
        uint32 duration,
        uint32 lockedAt,
        uint32 expiresAt
    );

    event Redeem(
        address account,
        uint256 amount,
        uint256 reward,
        uint32 duration,
        uint32 lockedAt
    );

    function enforceLockExistsAndExpired(
        address account,
        uint32 duration
    ) internal view {
        ITokenLocker.Lock storage lock = _storage().accountDurationLock[
            account
        ][duration];

        if (lock.expiresAt == 0) {
            revert ITokenLocker.LockNotFound();
        }

        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        if (block.timestamp < lock.expiresAt) {
            revert ITokenLocker.LockNotExpired();
        }
        // solhint-enable
    }

    function deposit(
        address account,
        uint256 amount,
        uint32 duration
    ) internal {
        Storage storage s = _storage();

        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        // solhint-enable

        if (s.accountDurationLock[account][duration].amount > 0) {
            amount += redeem(account, duration);
        }

        // slither-disable-next-line arbitrary-send-erc20
        s.lockedToken.safeTransferFrom(account, address(this), amount);

        ITokenLocker.Lock memory lock = ITokenLocker.Lock({
            amount: amount,
            reward: calculateReward(amount, duration),
            duration: duration,
            lockedAt: blockTimestamp,
            expiresAt: blockTimestamp + duration
        });

        s.accountDurationLock[account][duration] = lock;

        LibERC20.mint(account, lock.amount + lock.reward);

        emit Deposit(
            account,
            lock.amount,
            lock.reward,
            lock.duration,
            lock.lockedAt,
            lock.expiresAt
        );
    }

    function redeem(
        address account,
        uint32 duration
    ) internal returns (uint256 redeemedAmount) {
        Storage storage s = _storage();

        ITokenLocker.Lock memory lock = s.accountDurationLock[account][
            duration
        ];

        if (lock.amount == 0) {
            revert ITokenLocker.LockNotFound();
        }

        LibERC20.burn(account, lock.amount + lock.reward);

        uint256 reward = lock.reward;

        if (block.timestamp < lock.expiresAt) {
            reward = calculateRewardDiff(
                reward,
                lock.duration,
                (block.timestamp - lock.lockedAt)
            );
        }

        redeemedAmount = lock.amount + reward;

        IERC20Mintable lockedToken = s.lockedToken;

        lockedToken.mint(address(this), reward);

        lockedToken.safeTransfer(account, redeemedAmount);

        emit Redeem(
            account,
            redeemedAmount,
            lock.reward,
            duration,
            lock.lockedAt
        );

        delete s.accountDurationLock[account][duration];
    }

    function getLock(
        address account,
        uint32 duration
    ) internal view returns (ITokenLocker.Lock memory lock) {
        return _storage().accountDurationLock[account][duration];
    }

    function migrate(
        address account,
        uint256 amount,
        uint32 duration,
        uint32 timestamp
    ) internal {
        Storage storage s = _storage();

        if (s.accountDurationLock[account][duration].amount == 0) {
            ITokenLocker.Lock memory lock = ITokenLocker.Lock({
                amount: amount,
                reward: calculateReward(amount, duration),
                duration: duration,
                lockedAt: timestamp,
                expiresAt: timestamp + duration
            });

            s.accountDurationLock[account][duration] = lock;

            LibERC20.mint(account, lock.amount + lock.reward);

            emit Deposit(
                account,
                lock.amount,
                lock.reward,
                lock.duration,
                lock.lockedAt,
                lock.expiresAt
            );
        } else {
            ITokenLocker.Lock storage lock = s.accountDurationLock[account][
                duration
            ];

            LibERC20.burn(account, lock.amount + lock.reward);

            uint256 reward = lock.reward;

            if (timestamp < lock.expiresAt) {
                reward = calculateRewardDiff(
                    reward,
                    lock.duration,
                    (timestamp - lock.lockedAt)
                );
            }

            emit Redeem(account, lock.amount, reward, duration, lock.lockedAt);

            s.lockedToken.mint(address(this), reward);

            lock.amount += reward + amount;
            lock.reward = calculateReward(lock.amount, duration);
            lock.lockedAt = timestamp;
            lock.expiresAt = timestamp + duration;

            uint256 balance = LibERC20.balanceOf(account);
            uint256 expectedBalance = lock.amount + lock.reward;

            if (balance > expectedBalance) {
                LibERC20.burn(account, balance - expectedBalance);
            } else if (expectedBalance > balance) {
                LibERC20.mint(account, expectedBalance - balance);
            }

            emit Deposit(
                account,
                lock.amount,
                lock.reward,
                lock.duration,
                lock.lockedAt,
                lock.expiresAt
            );
        }
    }

    function calculateRewardDiff(
        uint256 reward,
        uint32 duration,
        uint256 newDuration
    ) internal pure returns (uint256 rewardAmount) {
        return
            (((reward * DENOMINATOR) / duration) * newDuration) / DENOMINATOR;
    }

    function calculateReward(
        uint256 amount,
        uint32 duration
    ) internal pure returns (uint256 rewardAmount) {
        return (amount * getApr(duration)) / DENOMINATOR;
    }

    function getApr(uint32 duration) internal pure returns (uint256 apr) {
        if (duration == 30 days) {
            return 83e6; // 0.83 / 100 * 1e10
        } else if (duration == 365 days) {
            return 65e8; // 65 / 100 * 1e10
        } else {
            revert ITokenLocker.UnsupportedDuration();
        }
    }

    function setLockedToken(IERC20Mintable lockedToken) internal {
        _storage().lockedToken = lockedToken;
    }
}
