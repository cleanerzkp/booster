// SPDX-License-Identifier: None

pragma solidity ^0.8.9;

import "./interfaces/ITokenLocker.sol";

contract MockTokenLocker is ITokenLocker {
    function getLock(address _account, uint32 _duration) external view override returns (Lock memory) {
        // You can return hardcoded values or use a mapping if you need different values for different accounts and durations.
        return Lock({
            amount: 100 * 1e18, // 100 tokens
            duration: _duration,
            expiresAt: uint32(block.timestamp + _duration)
        });
    }
}
