 // SPDX-License-Identifier: None

pragma solidity ^0.8.9;

import {PausableFacet, LibPausable} from "./solarprotocol/solidity-modules/contracts/modules/pausable/PausableFacet.sol";
import {Initializer} from "./solarprotocol/solidity-modules/contracts/modules/utils/initializer/Initializer.sol";
import {AccessControlFacet, LibAccessControl} from "./solarprotocol/solidity-modules/contracts/modules/access/AccessControlFacet.sol";
import {LibRoles} from "./solarprotocol/solidity-modules/contracts/modules/access/LibRoles.sol";
import {ITokenLocker} from "./token-locker/ITokenLocker.sol";
import {IMasterChefAdmin} from "./interfaces/IMasterChefAdmin.sol";

contract LockerBooster is AccessControlFacet, PausableFacet, Initializer {
    // Internal constant variables
    bytes32 public constant BOOST_MANAGER_ROLE =  keccak256("BOOST_MANAGER_ROLE");

    uint256 internal constant DENOMINATOR = 1e10;
    uint256 public monthlyBoost;
    uint256 public yearlyBoost;
    ITokenLocker public tokenLocker;
    IMasterChefAdmin public masterChefAdmin;
    mapping(address => User) public boostedUser;  

    // Struct for each boosted user
    struct User {
          uint256 boost;
          uint256 pid;
      		bool init;
    }

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

    /// @notice gas optimization by assigning the boosters in constructor
      constructor() {
        monthlyBoost = 2500; // 25e2
        yearlyBoost = 300000; // 3e5
    }
      /**
        * @notice Updates the boost multiplier for the specified account and pool ID in MasterChef
        * @dev Boost is calculated based on the account's locked tokens in the LockerContract.
        *  If the account is already boosted in the specified pool, the boost multiplier is updated to the new value.
        * @param _account The account to update the boost multiplier for.
        * @param _pid The ID of the pool to update the boost multiplier for.
        */
    function updateBoost(address _account, uint256 _pid) external onlyOwner {
        uint256 boost = (boostLock(_account) + 100 * 1e6) * 1e4;
        if (_pid == boostedUser[_account].pid) {
            masterChefAdmin.updateBoostMultiplier(_account, _pid, boost);
        } else {
          if(boostedUser[_account].init){
              masterChefAdmin.updateBoostMultiplier(
                _account,
                boostedUser[_account].pid,
                100 * 1e10
            );
          }else{
            boostedUser[_account].init = true;
          }
            masterChefAdmin.updateBoostMultiplier(_account, _pid, boost);
            boostedUser[_account].pid = _pid;
        }
    }

   function getUsersBoost(address[] memory _users) public view returns (User[] memory) {
        User[] memory users = new User[](_users.length); 
        for (uint256 i = 0; i < _users.length; i++) {
        users[i] = boostedUser[_users[i]];
        }
        return users;
    }
     
	/*
    function getUsersBoost(address[] memory _users) public view returns (address[] memory addressArray, uint256[] memory boostArray, uint256[] memory pidArray, bool[] memory initArray) {
        addressArray = new address[](_users.length);
        boostArray = new uint256[](_users.length);
        pidArray = new uint256[](_users.length);
        initArray = new bool[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            addressArray[i] = _users[i];
            boostArray[i] = boostedUser[_users[i]].boost;
            pidArray[i] = boostedUser[_users[i]].pid;
            initArray[i] = boostedUser[_users[i]].init;
        }
    }
    */
  
    function boostLock(address _account) public view returns (uint256 boost) {
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
        if (monthLock.duration > 0 && monthLock.amount > 0) {
            // struct validation
            boost += calculateBoost(monthLock.amount, monthLock.duration);
        }
        if (yearLock.duration > 0 && yearLock.amount > 0) {
            // struct validation
            boost += calculateBoost(yearLock.amount, yearLock.duration);
        }
        return boost >= 15e16 ? 15e16 / DENOMINATOR : boost / DENOMINATOR;
    }

    function calculateBoost(
        uint256 amount,
        uint32 duration
    ) internal view returns (uint256 rewardAmount) {
        return (amount * getBoostRate(duration)) / DENOMINATOR;
    }

    function getBoostRate(
        uint32 duration
    ) internal view returns (uint256 boostRate) {
        if (duration == 30 days) return monthlyBoost;
        else if (duration == 365 days) return yearlyBoost;
        else revert UnsupportedDuration();
    }

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

    function changeLockerAddr(ITokenLocker _tokenLocker) external onlyOwner {
        require(address(_tokenLocker) != address(0));
        tokenLocker = _tokenLocker;
    }

    function changeMasterChefAddr(
        IMasterChefAdmin _masterChefAdmin
    ) external onlyOwner {
        require(address(_masterChefAdmin) != address(0));
        masterChefAdmin = _masterChefAdmin;
    }

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
