// SPDX-License-Identifier: None

pragma solidity ^0.8.9;

import {PausableFacet, LibPausable} from "@solarprotocol/solidity-modules/contracts/modules/pausable/PausableFacet.sol";
import {Initializer} from "@solarprotocol/solidity-modules/contracts/modules/utils/initializer/Initializer.sol";
import {AccessControlFacet, LibAccessControl} from "@solarprotocol/solidity-modules/contracts/modules/access/AccessControlFacet.sol";
import {LibRoles} from "@solarprotocol/solidity-modules/contracts/modules/access/LibRoles.sol";
import {ITokenLocker} from "./token-locker/ITokenLocker.sol";
import {IMasterChefAdmin} from "./interfaces/IMasterChefAdmin.sol";
import {ILockBooster} from "./interfaces/ILockBooster.sol";

contract LockerBooster is AccessControlFacet, PausableFacet, Initializer, ILockBooster {
    // Internal constant variables
    bytes32 public constant BOOST_MANAGER_ROLE =
        keccak256("BOOST_MANAGER_ROLE");

    uint256 internal constant DENOMINATOR = 1e10;
    uint256 public monthlyBoost = 2500;
    uint256 public yearlyBoost = 300000;
    ITokenLocker public tokenLocker;
    IMasterChefAdmin public masterChefAdmin;
    mapping(address => User) public boostedUser;

    // Struct for each boosted user
   

    // Error handling
    error UnsupportedDuration();

    // Modifier to ensure function is only called by contract owner
    modifier onlyOwner() {
        LibAccessControl.enforceRole(LibRoles.DEFAULT_ADMIN_ROLE);
        _;
    }

    // Modifier to ensure function is only called by boost manager
    modifier onlyBoostManager() {
        LibAccessControl.enforceRole(BOOST_MANAGER_ROLE);
        _;
    }

    // Modifier to ensure function is only called by tokenLocker contract
    modifier onlyTokenLock(address _tokenLocker){
        require(address(tokenLocker) == _tokenLocker);
        _;
    }
    // Modifier to check requirements for modifying roles
    modifier requirementsChecker(
        address _newaddress,
        address _oldaddress,
        bytes32 _role
    ) {
        require(_oldaddress != _newaddress, "Old addr == New Addr.");
        require(
            LibAccessControl.hasRole(_role, _oldaddress),
            "Wrong old addr."
        );
        require(_newaddress != address(0), "New addr role is zero.");
        _;
    }
    /**
    * @dev external function for users
    */
    function updateBoost(uint256 _pid) external {
        _updateBoost(msg.sender, _pid);
    }

     /**
    * @dev external function for boostManager
    */
    function updateBoostManager(address _account, uint256 _pid) external onlyBoostManager {
      _updateBoost(_account, _pid);
    }

     /**
    * @dev external function for tokenLock contract
    */
    function redeemBoost(address _user) external onlyTokenLock(msg.sender) {
        if(boostedUser[_user].init == true){
            _updateBoost(_user, boostedUser[_user].pid);
        }
    }


    /**
     * @notice Updates the boost multiplier for the specified account and pool ID in MasterChef
     * @dev Boost is calculated based on the account's locked tokens in the LockerContract.
     *  If the account is already boosted in the specified pool, the boost multiplier is updated to the new value.
     * @param _account The account to update the boost multiplier for.
     * @param _pid The ID of the pool to update the boost multiplier for.
     */
    function _updateBoost(address _account, uint256 _pid) internal{
        uint256 boost = (calculateUserBoost(_account) + 100 * 1e6) * 1e4;
        User storage user = boostedUser[_account];
        if (_pid == user.pid) {
            masterChefAdmin.updateBoostMultiplier(_account, _pid, boost);
        } else {
            if (user.init) {
                masterChefAdmin.updateBoostMultiplier(_account, user.pid, 100 * 1e10);
            } else {
                user.init = true;
            }
            masterChefAdmin.updateBoostMultiplier(_account, _pid, boost);
            user.pid = _pid;
        }
        user.boost = boost;
    }

    /**
     * @dev Function returns users information
     * @param _users an array of accounts to get information for.
     */
    function getUsersBoost(
        address[] calldata _users
    ) external view returns (User[] memory) {
        User[] memory users = new User[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            users[i] = boostedUser[_users[i]];
        }
        return users;
    }

    /**
     * @notice Check boost changes and updates the boost multiplier for accounts in array
     * @dev Checking boost is based on value saved in user info and actual calculation.
     *  If the boost is different, function updates boost on already boosted pool
     * @param _users The account to update the boost multiplier for.
     */

    function chceckAndUpdateUsersLocks(address[] calldata _users) external {
        for (uint256 i = 0; i < _users.length; i++) {
            if (boostedUser[_users[i]].boost != calculateUserBoost(_users[i])) {
                _updateBoost(_users[i], boostedUser[_users[i]].pid);
            }
        }
    }

    /**
     * @dev Boost is calculated based on the account's locked tokens in the LockerContract.
     * @param _account The account to calculate the boost multiplier for.
     */
    function calculateUserBoost(address _account) public view returns (uint256 boost) {
        LibPausable.enforceNotPaused();
        require(
            address(tokenLocker) != address(0),
            "TokenLocker not initialized."
        );

        ITokenLocker.Lock memory monthLock = tokenLocker.getLock(
            _account,
            30 days
        );
        ITokenLocker.Lock memory yearLock = tokenLocker.getLock(
            _account,
            365 days
        );
        boost = 0;
        if (
            monthLock.duration > 0 &&
            monthLock.amount > 0 &&
            monthLock.expiresAt >= block.timestamp
        ) {
            // struct validation
            boost += _calculateBoost(monthLock.amount, monthLock.duration);
        }
        if (
            yearLock.duration > 0 &&
            yearLock.amount > 0 &&
            yearLock.expiresAt >= block.timestamp
        ) {
            // struct validation
            boost += _calculateBoost(yearLock.amount, yearLock.duration);
        }
        return boost >= 15e16 ? 15e16 / DENOMINATOR : boost / DENOMINATOR;
    }

    /**
     * @dev Calculating boost based on given amount and duration
     * @param duration, time period of token locking
     * @param amount, amount of locked KSWAP tokens
     */
    function _calculateBoost(
        uint256 amount,
        uint32 duration
    ) internal view returns (uint256 rewardAmount) {
        return (amount * getBoostRate(duration)) / DENOMINATOR;
    }

    /**
     * @dev Calculating boost rate based on given duration
     * @param duration, time period of token locking
     */
    function getBoostRate(
        uint32 duration
    ) internal view returns (uint256 boostRate) {
        if (duration == 30 days) return monthlyBoost;
        else if (duration == 365 days) return yearlyBoost;
        else revert UnsupportedDuration();
    }

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
    ) external initializer {
        require(
            address(_tokenLocker) != address(0) &&
                address(_masterChef) != address(0) &&
                _owner != address(0) &&
                _boostManager != address(0)
        );
        tokenLocker = _tokenLocker;
        masterChefAdmin = _masterChef;
        LibAccessControl.grantRole(BOOST_MANAGER_ROLE, _boostManager);
        LibAccessControl.grantRole(LibRoles.DEFAULT_ADMIN_ROLE, _owner);
    }

    /**
     * @dev Changing access address tokenLocker contract
     * @param _tokenLocker new contract address
     */
    function changeLockerAddr(ITokenLocker _tokenLocker) external onlyOwner {
        require(address(_tokenLocker) != address(0));
        tokenLocker = _tokenLocker;
    }

    /**
     * @dev Changing access address MasterChef contract
     * @param _masterChefAdmin new contract address
     */
    function changeMasterChefAddr(
        IMasterChefAdmin _masterChefAdmin
    ) external onlyOwner {
        require(address(_masterChefAdmin) != address(0));
        masterChefAdmin = _masterChefAdmin;
    }

    /**
     * @dev Changing address for BOOST_MANAGER_ROLE
     * @param _oldBoostManager, current address to revoke role
     * @param _newBoostManager, new addres to grant role
     */
    function changeBoostManager(
        address _oldBoostManager,
        address _newBoostManager
    )
        external
        onlyOwner
        requirementsChecker(
            _newBoostManager,
            _oldBoostManager,
            BOOST_MANAGER_ROLE
        )
    {
        LibAccessControl.grantRole(BOOST_MANAGER_ROLE, _newBoostManager);
        LibAccessControl.revokeRole(BOOST_MANAGER_ROLE, _oldBoostManager);
    }
}
