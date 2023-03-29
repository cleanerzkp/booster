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

import {LibTokenLocker, ITokenLocker, IERC20Mintable, SafeERC20} from "./LibTokenLocker.sol";
import {Initializer} from "@solarprotocol/solidity-modules/contracts/modules/utils/initializer/Initializer.sol";
import {PausableFacet, LibPausable} from "@solarprotocol/solidity-modules/contracts/modules/pausable/PausableFacet.sol";
import {SimpleBlacklistFacet, LibSimpleBlacklist} from "@solarprotocol/solidity-modules/contracts/modules/blacklist/SimpleBlacklistFacet.sol";
import {AccessControlFacet, LibAccessControl} from "@solarprotocol/solidity-modules/contracts/modules/access/AccessControlFacet.sol";
import {LibRoles} from "@solarprotocol/solidity-modules/contracts/modules/access/LibRoles.sol";
import {ERC20Facet, LibERC20, IERC20} from "@solarprotocol/solidity-modules/contracts/modules/token/ERC20/facets/ERC20Facet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ILockBooster} from "../interfaces/ILockBooster.sol";

contract TokenLocker is
    ITokenLocker,
    Initializer,
    PausableFacet,
    SimpleBlacklistFacet,
    AccessControlFacet,
    ERC20Facet
{
    using SafeERC20 for IERC20;

    ILockBooster public boosterContract;

    /// @notice DEPRECATED
    IERC20 public deprecatedToken;

    /// @notice DEPRECATED
    mapping(address => UserInfo[]) public deprecatedUserInfo;
    /// @notice DEPRECATED
    mapping(address => mapping(uint256 => bool))
        public deprecatedUserInfoMigrated;

    uint256 public constant MIN_DEPOSIT_AMOUNT = 1e18;
    uint256 public constant MAX_DEPOSIT_AMOUNT = 5000e18;

    modifier onlyOwner() {
        LibAccessControl.enforceRole(LibRoles.DEFAULT_ADMIN_ROLE);
        _;
    }

    function deposit(uint256 amount, uint32 duration) external {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted(msg.sender);

        require(amount > MIN_DEPOSIT_AMOUNT, "Amount < MIN_DEPOSIT_AMOUNT");
        require(amount < MAX_DEPOSIT_AMOUNT, "Amount > MAX_DEPOSIT_AMOUNT");

        assert(LibTokenLocker.getApr(duration) > 0);

        LibTokenLocker.deposit(msg.sender, amount, duration);
    }

    function redeem(uint32 duration) external {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted(msg.sender);

        LibTokenLocker.enforceLockExistsAndExpired(msg.sender, duration);

        LibTokenLocker.redeem(msg.sender, duration);

        if(address(boosterContract) != address(0)){
            boosterContract.redeemBoost(msg.sender);
        }
        
    }

    function getLock(
        address account,
        uint32 duration
    ) external view returns (Lock memory lock) {
        return LibTokenLocker.getLock(account, duration);
    }

    function getLocks(
        address[] calldata accounts,
        uint32[] calldata durations
    ) external view returns (Lock[] memory locks) {
        uint256 length = accounts.length;

        require(length == durations.length, "Length missmatch");

        locks = new Lock[](accounts.length);

        uint256 index = 0;

        while (index < length) {
            locks[index] = LibTokenLocker.getLock(
                accounts[index],
                durations[index]
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @inheritdoc IERC20
     */
    // solhint-disable no-unused-vars
    function transfer(
        // solc-ignore-next-line unused-param
        address to,
        // solc-ignore-next-line unused-param
        uint256 amount
    ) external virtual override returns (bool) {
        revert("ERC20: Not transferrable");
    }

    // solhint-enable

    /**
     * @inheritdoc IERC20
     */
    // solhint-disable no-unused-vars
    function transferFrom(
        // solc-ignore-next-line unused-param
        address from,
        // solc-ignore-next-line unused-param
        address to,
        // solc-ignore-next-line unused-param
        uint256 amount
    ) external virtual override returns (bool) {
        revert("ERC20: Not transferrable");
    }

    // solhint-enable

    function initialize(IERC20 token_, address owner) external initializer {
        deprecatedToken = token_;

        LibAccessControl.grantRole(LibRoles.DEFAULT_ADMIN_ROLE, owner);
        LibAccessControl.grantRole(LibRoles.MANAGER_ROLE, owner);
        LibAccessControl.grantRole(LibRoles.TESTER_ROLE, owner);
    }

    function reinitialize(
        address[] calldata migrationManagers
    ) external reinitializer(2) {
        LibAccessControl.enforceRole(LibRoles.MANAGER_ROLE);

        LibERC20.setName("KyotoSwap Governance Token");
        LibERC20.setSymbol("voKSWAP");

        LibTokenLocker.setLockedToken(IERC20Mintable(address(deprecatedToken)));

        LibPausable.pause();

        for (uint256 index = 0; index < migrationManagers.length; ++index) {
            LibAccessControl.grantRole(
                keccak256("MIGRATION_MANAGER_ROLE"),
                migrationManagers[index]
            );
        }
    }
    /// @notice no chceck for address 0 due to booster off and on switch
    function changeLockBosterAddr(ILockBooster _newAddr) external onlyOwner {
        boosterContract = _newAddr;
    }
}
