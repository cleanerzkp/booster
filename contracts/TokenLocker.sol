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

import {ITokenLocker} from "./interfaces/ITokenLocker.sol";
import {Initializer} from "@solarprotocol/solidity-modules/contracts/modules/utils/initializer/Initializer.sol";
import {PausableFacet, LibPausable} from "@solarprotocol/solidity-modules/contracts/modules/pausable/PausableFacet.sol";
import {SimpleBlacklistFacet, LibSimpleBlacklist} from "@solarprotocol/solidity-modules/contracts/modules/blacklist/SimpleBlacklistFacet.sol";
import {AccessControlFacet, LibAccessControl} from "@solarprotocol/solidity-modules/contracts/modules/access/AccessControlFacet.sol";
import {LibRoles} from "@solarprotocol/solidity-modules/contracts/modules/access/LibRoles.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenLocker is
    ITokenLocker,
    Initializer,
    PausableFacet,
    SimpleBlacklistFacet,
    AccessControlFacet
{
    using SafeERC20 for IERC20;

    IERC20 public token;

    mapping(address => UserInfo[]) public userInfo;

    uint256 public constant MIN_DEPOSIT_AMOUNT = 1e18;
    uint256 public constant MAX_DEPOSIT_AMOUNT = 5000e18;

    function deposit(uint256 amount, uint32 duration) external {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted(msg.sender);

        require(amount > MIN_DEPOSIT_AMOUNT, "Amount < MIN_DEPOSIT_AMOUNT");
        require(amount < MAX_DEPOSIT_AMOUNT, "Amount > MAX_DEPOSIT_AMOUNT");
        require(
            duration == 30 days || duration == 365 days,
            "Unsupported duration"
        );

        token.safeTransferFrom(msg.sender, address(this), amount);

        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        uint32 lockedAt = uint32(block.timestamp % 2 ** 32);
        // solhint-enable

        userInfo[msg.sender].push(
            UserInfo({amount: amount, duration: duration, lockedAt: lockedAt})
        );

        emit Deposit(msg.sender, amount, duration, lockedAt);
    }

    function getUserInfoLength(
        address account
    ) external view returns (uint256) {
        return userInfo[account].length;
    }

    function getUserInfo(
        address account,
        uint256 id
    ) external view returns (UserInfo memory) {
        return userInfo[account][id];
    }

    function getUserInfo(
        address account
    ) external view returns (UserInfo[] memory userLockInfo) {
        UserInfo[] storage userLocks = userInfo[account];

        uint256 length = userLocks.length;
        uint256 index = 0;

        userLockInfo = new UserInfo[](length);

        while (index < length) {
            userLockInfo[index] = userLocks[index];

            unchecked {
                ++index;
            }
        }
    }

    function initialize(IERC20 token_, address owner) external initializer {
        token = token_;

        LibAccessControl.grantRole(LibRoles.DEFAULT_ADMIN_ROLE, owner);
        LibAccessControl.grantRole(LibRoles.MANAGER_ROLE, owner);
        LibAccessControl.grantRole(LibRoles.TESTER_ROLE, owner);
    }
}
