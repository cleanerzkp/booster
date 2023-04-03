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
import {LibAccessControl} from "../../access/LibAccessControl.sol";
import {LibRoles} from "../../access/LibRoles.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC777} from "@openzeppelin/contracts/token/ERC777/IERC777.sol";

/**
 * @dev Facet implementing the ERC777 interface using the LibSoloToken.
 */
contract ERC777Facet is IERC777, IERC20 {
    /**
     * @dev See {IERC777-name}.
     */
    function name() external view returns (string memory) {
        return LibSoloToken.name();
    }

    /**
     * @dev See {IERC777-symbol}.
     */
    function symbol() external view returns (string memory) {
        return LibSoloToken.symbol();
    }

    /**
     * @dev See {ERC20-decimals}.
     *
     * Always returns 18, as per the
     * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC777-granularity}.
     *
     * This implementation always returns `1`.
     */
    function granularity() external pure returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply()
        external
        view
        override(IERC20, IERC777)
        returns (uint256)
    {
        return LibSoloToken.totalSupply();
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder)
        external
        view
        virtual
        override(IERC20, IERC777)
        returns (uint256)
    {
        return LibSoloToken.balanceOf(tokenHolder);
    }

    /**
     * @dev See {IERC777-send}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) external {
        LibPausable.enforceNotPaused();

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(recipient);

        // solhint-disable-next-line check-send-result
        LibSoloToken.send(msg.sender, recipient, amount, data, "", true);
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
        returns (bool)
    {
        LibPausable.enforceNotPaused();

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(recipient);

        // solhint-disable-next-line check-send-result
        LibSoloToken.send(msg.sender, recipient, amount, "", "", false);
        return true;
    }

    /**
     * @dev See {IERC777-burn}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) external {
        LibPausable.enforceNotPaused();

        LibSimpleBlacklist.enforceNotBlacklisted();

        LibSoloToken.burn(msg.sender, msg.sender, amount, data, "", true);
    }

    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder)
        external
        view
        returns (bool)
    {
        return LibSoloToken.isOperatorFor(operator, tokenHolder);
    }

    /**
     * @dev See {IERC777-authorizeOperator}.
     */
    function authorizeOperator(address operator) external {
        LibPausable.enforceNotPaused();

        LibSoloToken.authorizeOperator(operator);
    }

    /**
     * @dev See {IERC777-revokeOperator}.
     */
    function revokeOperator(address operator) external {
        LibPausable.enforceNotPaused();

        LibSoloToken.revokeOperator(operator);
    }

    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators() external view returns (address[] memory) {
        return LibSoloToken.defaultOperators();
    }

    /**
     * @dev See {IERC777-operatorSend}.
     *
     * Emits {Sent} and {IERC20-Transfer} events.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) external {
        LibPausable.enforceNotPaused();

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(sender);
        LibSimpleBlacklist.enforceNotBlacklisted(recipient);

        // solhint-disable-next-line reason-string
        require(
            LibSoloToken.isOperatorFor(msg.sender, sender),
            "ERC777: caller is not an operator for holder"
        );
        // solhint-disable-next-line check-send-result
        LibSoloToken.send(sender, recipient, amount, data, operatorData, true);
    }

    /**
     * @dev See {IERC777-operatorBurn}.
     *
     * Emits {Burned} and {IERC20-Transfer} events.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) external {
        LibPausable.enforceNotPaused();

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(account);

        // solhint-disable-next-line reason-string
        require(
            LibSoloToken.isOperatorFor(msg.sender, account),
            "ERC777: caller is not an operator for holder"
        );
        LibSoloToken.burn(
            msg.sender,
            account,
            amount,
            data,
            operatorData,
            true
        );
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
    function approve(address spender, uint256 value) external returns (bool) {
        LibPausable.enforceNotPaused();

        LibSoloToken.approve(msg.sender, spender, value);
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
    ) external returns (bool) {
        LibPausable.enforceNotPaused();

        LibSimpleBlacklist.enforceNotBlacklisted();
        LibSimpleBlacklist.enforceNotBlacklisted(holder);
        LibSimpleBlacklist.enforceNotBlacklisted(recipient);

        LibSoloToken.spendAllowance(holder, msg.sender, amount);
        // solhint-disable-next-line check-send-result
        LibSoloToken.send(holder, recipient, amount, "", "", false);
        return true;
    }
}
