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

interface ITokenLocker {
    struct Lock {
        uint256 amount;
        uint256 reward;
        uint32 duration;
        uint32 lockedAt;
        uint32 expiresAt;
    }

    error UnsupportedDuration();
    error LockNotFound();
    error LockNotExpired();

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

    function deposit(uint256 amount, uint32 duration) external;

    function redeem(uint32 duration) external;

    function getLock(
        address account,
        uint32 duration
    ) external view returns (Lock memory lock);

    /// @notice DEPRECATED
    /// @dev Used in the first version. Was migrated to new logic.
    struct UserInfo {
        uint256 amount;
        uint32 duration;
        uint32 lockedAt;
    }
}
