// SPDX-License-Identifier: None

pragma solidity ^0.8.9;

import {PausableFacet, LibPausable} from "@solarprotocol/solidity-modules/contracts/modules/pausable/PausableFacet.sol";
import {Initializer} from "@solarprotocol/solidity-modules/contracts/modules/utils/initializer/Initializer.sol";
import {AccessControlFacet, LibAccessControl} from "@solarprotocol/solidity-modules/contracts/modules/access/AccessControlFacet.sol";
import {LibRoles} from "@solarprotocol/solidity-modules/contracts/modules/access/LibRoles.sol";
import {ITokenLocker} from "./token-locker/ITokenLocker.sol";
import {IMasterChefAdmin} from "./interfaces/IMasterChefAdmin.sol";

contract LockerBooster is AccessControlFacet, PausableFacet, Initializer {
    uint256 internal constant DENOMINATOR = 1e10;
    uint256 public monthlyBoost = 25e2;
    uint256 public yearlyBoost = 3e5;
    ITokenLocker tokenLocker;
    IMasterChefAdmin public masterChefAdmin;

    mapping(address => uint256) public boostedPool;

    error UnsupportedDuration();

    modifier onlyOwner() {
        require(msg.sender == _getOwner(), "NOT_AUTHORIZED");
        _;
    }

    function _getOwner() internal view returns (address ownerAddress) {
        // solhint-disable no-inline-assembly
        // slither-ignore-next-line assembly
        assembly {
            ownerAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }

    //@TODO
    function updateBoost(address _account, uint256 _pid) external onlyOwner {
        uint256 boost = (boostLock(_account) + 100 * 1e6) * 1e4;
        if (_pid == boostedPool[_account]) {
            masterChefAdmin.updateBoostMultiplier(_account, _pid, boost);
        } else {
            masterChefAdmin.updateBoostMultiplier(
                _account,
                boostedPool[_account],
                100 * 1e10
            );
            masterChefAdmin.updateBoostMultiplier(_account, _pid, boost);
            boostedPool[_account] = _pid;
        }
    }

    function boostLock(address _account) public view returns (uint256 boost) {
        LibPausable.enforceNotPaused();
        require(
            address(tokenLocker) != address(0),
            "TokenLocker not initialized."
        );

        ITokenLocker.Lock memory monthLock = tokenLocker.getLock(_account, 30 days);
        ITokenLocker.Lock memory yearLock = tokenLocker.getLock(_account, 365 days);

        boost = 0;

        if (monthLock.duration > 0 && monthLock.amount > 0) {
            // struct validation
            boost += calculateBoost(monthLock.amount, monthLock.duration);
        }

        if (yearLock.duration > 0 && yearLock.amount > 0) {
            // struct validation
            boost += calculateBoost(yearLock.amount, yearLock.duration);
        }

        if (boost >= 15e16) return 15e16 / DENOMINATOR;

        return boost / DENOMINATOR;
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
        ITokenLocker _tokenLocker,
        IMasterChefAdmin _masterChef
    ) external initializer {
        address owner = _getOwner();

        require(address(_tokenLocker) != address(0));
        tokenLocker = _tokenLocker;
        require(address(_masterChef) != address(0));
        masterChefAdmin = _masterChef;

        LibAccessControl.grantRole(LibRoles.DEFAULT_ADMIN_ROLE, owner);
    }

    function changeLockerAddr(ITokenLocker _tokenLocker) onlyOwner external {
        require(address(_tokenLocker) != address(0));
        tokenLocker = _tokenLocker;
    }

    function changeMasterChefAddr(IMasterChefAdmin _masterChefAdmin) onlyOwner external {
        require(address(_masterChefAdmin) != address(0));
        masterChefAdmin = _masterChefAdmin;
    }
}
