// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

interface IMasterChef {
    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newMultiplier
    ) external;
}
