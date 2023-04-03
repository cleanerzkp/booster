// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

interface ITokenLocker {
    struct Lock {
        uint256 amount;
        uint32 duration;
        uint64 expiresAt;
    }

    function getLock(address _user, uint32 _duration) external view returns (Lock memory);
}
