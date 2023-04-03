// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "./interfaces/IMasterChefAdmin.sol";

contract MasterChefMock is IMasterChef {
    mapping(address => mapping(uint256 => uint256)) public userBoostMultipliers;

    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newMultiplier
    ) external override {
        userBoostMultipliers[_user][_pid] = _newMultiplier;
    }
}