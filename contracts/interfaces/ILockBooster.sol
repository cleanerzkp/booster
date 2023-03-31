// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import {ITokenLocker} from "../token-locker/ITokenLocker.sol";
import {IMasterChefAdmin} from "./IMasterChefAdmin.sol";

interface ILockBooster {
    struct User {
        uint256 boost;
        uint256 pid;
        bool init;
    }

    event BoostManagerChanged(
        address oldBoostManager,
        address indexed newBoostManager
    );

    event MasterChefAddrChanged(address indexed masterChef);

    event UsersBoostUpdated(
        address indexed _account,
        uint256 indexed _pid,
        uint256 calculatedBoost
    );

    function updateBoost(uint256 _pid) external;

    /**
     * @dev external function for boostManager
     */
    function updateBoostManager(address _account, uint256 _pid) external;

    /**
     * @dev external function for tokenLock contract
     */
    function redeemBoost(address _user) external;

    /**
     * @dev Function returns users information
     * @param _users an array of accounts to get information for.
     */
    function getUsersBoost(
        address[] calldata _users
    ) external view returns (User[] memory);

    /**
     * @notice Check boost changes and updates the boost multiplier for accounts in array
     * @dev Checking boost is based on value saved in user info and actual calculation.
     *  If the boost is different, function updates boost on already boosted pool
     * @param _users The account to update the boost multiplier for.
     */

    function checkAndUpdateUsersLocks(address[] calldata _users) external;

    /**
     * @dev Boost is calculated based on the account's locked tokens in the LockerContract.
     * @param _account The account to calculate the boost multiplier for.
     */
    function calculateUserBoost(
        address _account
    ) external view returns (uint256 boost);

    /**
     * @dev Initialization of the contract
     * @param _owner, address of contract owner
     * @param _boostManager, address of boost manager
     * @param _tokenLocker, address of tokenLocker contract
     * @param _masterChef, address of masterChef contract
     */
    function initialize(
        address _owner,
        address _boostManager,
        ITokenLocker _tokenLocker,
        IMasterChefAdmin _masterChef
    ) external;

    /**
     * @dev Changing access address tokenLocker contract
     * @param _tokenLocker new contract address
     */
    function changeLockerAddr(ITokenLocker _tokenLocker) external;

    /**
     * @dev Changing access address MasterChef contract
     * @param _masterChefAdmin new contract address
     */
    function changeMasterChefAddr(IMasterChefAdmin _masterChefAdmin) external;

    /**
     * @dev Changing address for BOOST_MANAGER_ROLE
     * @param _oldBoostManager, current address to revoke role
     * @param _newBoostManager, new addres to grant role
     */
    function changeBoostManager(
        address _oldBoostManager,
        address _newBoostManager
    ) external;
}
