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

import {LibSoloToken} from "../LibSoloToken.sol";
import {LibSimpleBlacklist} from "../../blacklist/LibSimpleBlacklist.sol";
import {LibPausable} from "../../pausable/LibPausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Facet implementing the ERC20 interface using the LibSoloToken.
 * Use it instead of the ERC777Facet if the diamond should have only the ERC20.
 */
contract ERC20Facet is IERC20 {
    /**
     * @dev See {IERC20-name}.
     */
    function name() external view virtual returns (string memory) {
        return LibSoloToken.name();
    }

    /**
     * @dev See {IERC20-symbol}.
     */
    function symbol() external view virtual returns (string memory) {
        return LibSoloToken.symbol();
    }

    /**
     * @dev See {ERC20-decimals}.
     *
     * Always returns 18, as per the
     * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     */
    function decimals() external pure virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply() external view virtual returns (uint256) {
        return LibSoloToken.totalSupply();
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder)
        external
        view
        virtual
        returns (uint256)
    {
        return LibSoloToken.balanceOf(tokenHolder);
    }

    /**
     * @dev See {IERC20-allowance}.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender)
        external
        view
        virtual
        returns (uint256)
    {
        return LibSoloToken.allowance(holder, spender);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(address spender, uint256 value)
        external
        virtual
        returns (bool)
    {
        LibSoloToken.approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
     * interface if it is a contract.
     *
     * Also emits a {Sent} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool)
    {
        LibPausable.enforceNotPaused(recipient, address(0));

        LibSimpleBlacklist.enforceNotBlacklisted();

        if (recipient == LibSoloToken.DEAD_ADDRESS) {
            LibSoloToken.burn(msg.sender, msg.sender, amount, "", "", false);
            return true;
        }

        LibSimpleBlacklist.enforceNotBlacklisted(recipient);

        // solhint-disable-next-line check-send-result
        LibSoloToken.send(msg.sender, recipient, amount, "", "", false);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Note that operator and allowance concepts are orthogonal: operators cannot
     * call `transferFrom` (unless they have allowance), and accounts with
     * allowance cannot call `operatorSend` (unless they are operators).
     *
     * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external virtual returns (bool) {
        LibPausable.enforceNotPaused(holder, recipient);

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(holder);
        LibSimpleBlacklist.enforceNotBlacklisted(recipient);

        LibSoloToken.spendAllowance(holder, msg.sender, amount);
        // solhint-disable-next-line check-send-result
        LibSoloToken.send(holder, recipient, amount, "", "", false);
        return true;
    }
}
