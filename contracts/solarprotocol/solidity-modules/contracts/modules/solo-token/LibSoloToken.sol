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

import {LibDiamondExtras} from "../diamond/LibDiamondExtras.sol";
import {LibTokenTaxes} from "../token-taxes/LibTokenTaxes.sol";
import {LibTokenReflections} from "../token-reflections/LibTokenReflections.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC777} from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {IERC777Sender} from "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";

/**
 * @dev Library based on the OpenZeppelin ERC777.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP.
 * If the token should be only a ERC20, then the ERC20Facet should be used
 * instead of the ERC777Facet.
 *
 * See: https://docs.openzeppelin.com/contracts/4.x/api/token/erc777
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC777/ERC777.sol
 */
library LibSoloToken {
    using Address for address;

    // slither-disable-next-line unused-state
    address internal constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    IERC1820Registry internal constant ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 private constant TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    struct Storage {
        mapping(address => uint256) balances;
        uint256 totalSupply;
        string name;
        string symbol;
        // This isn't ever read from - it's only used to respond to the defaultOperators query.
        address[] defaultOperatorsArray;
        // Immutable, but accounts may revoke them (tracked in revokedDefaultOperators).
        mapping(address => bool) defaultOperators;
        // For each account, a mapping of its operators and revoked default operators.
        mapping(address => mapping(address => bool)) operators;
        mapping(address => mapping(address => bool)) revokedDefaultOperators;
        // ERC20-allowances
        mapping(address => mapping(address => uint256)) allowances;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.solo-token.LibSoloToken");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            s.slot := slot
        }
        // solhint-enable
    }

    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(
        address indexed operator,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(
        address indexed operator,
        address indexed from,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(
        address indexed operator,
        address indexed tokenHolder
    );

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(
        address indexed operator,
        address indexed tokenHolder
    );

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    function init(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_,
        bool onlyERC20
    ) internal {
        _storage().name = name_;
        _storage().symbol = symbol_;

        if (defaultOperators_.length > 0) {
            setDefaultOperators(defaultOperators_);
        }

        LibDiamondExtras.setERC165(type(IERC20).interfaceId);

        if (!onlyERC20) {
            LibDiamondExtras.setERC165(type(IERC777).interfaceId);
            register1820();
        }
    }

    function setDefaultOperators(address[] memory defaultOperators_) internal {
        _storage().defaultOperatorsArray = defaultOperators_;

        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _storage().defaultOperators[defaultOperators_[i]] = true;
        }
    }

    function register1820() internal {
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC777Token"),
            address(this)
        );
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC20Token"),
            address(this)
        );
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() internal view returns (string memory) {
        return _storage().name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() internal view returns (string memory) {
        return _storage().symbol;
    }

    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply() internal view returns (uint256) {
        return _storage().totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an `account`.
     */
    function balanceOf(address account) internal view returns (uint256) {
        return _storage().balances[account];
    }

    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder)
        internal
        view
        returns (bool)
    {
        return
            operator == tokenHolder ||
            (_storage().defaultOperators[operator] &&
                !_storage().revokedDefaultOperators[tokenHolder][operator]) ||
            _storage().operators[tokenHolder][operator];
    }

    /**
     * @dev See {IERC777-authorizeOperator}.
     */
    function authorizeOperator(address operator) internal {
        // solhint-disable-next-line reason-string
        require(msg.sender != operator, "ERC777: authorizing self as operator");

        if (_storage().defaultOperators[operator]) {
            delete _storage().revokedDefaultOperators[msg.sender][operator];
        } else {
            _storage().operators[msg.sender][operator] = true;
        }

        emit AuthorizedOperator(operator, msg.sender);
    }

    /**
     * @dev See {IERC777-revokeOperator}.
     */
    function revokeOperator(address operator) internal {
        // solhint-disable-next-line reason-string
        require(operator != msg.sender, "ERC777: revoking self as operator");

        if (_storage().defaultOperators[operator]) {
            _storage().revokedDefaultOperators[msg.sender][operator] = true;
        } else {
            delete _storage().operators[msg.sender][operator];
        }

        emit RevokedOperator(operator, msg.sender);
    }

    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators() internal view returns (address[] memory) {
        return _storage().defaultOperatorsArray;
    }

    /**
     * @dev See {IERC20-allowance}.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender)
        internal
        view
        returns (uint256)
    {
        if (holder == spender) {
            return type(uint256).max;
        }

        return _storage().allowances[holder][spender];
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If `requireReceptionAck` is set to true, and if a send hook is
     * registered for `account`, the corresponding function will be called with
     * `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = msg.sender;

        beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _storage().totalSupply += amount;
        _storage().balances[account] += amount;

        // Notify token-reflections module abou the increased balance.
        LibTokenReflections.accountBalanceUpdated(account);

        _callTokensReceived(
            operator,
            address(0),
            account,
            amount,
            userData,
            operatorData,
            requireReceptionAck
        );

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Send tokens
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal {
        // solhint-disable-next-line reason-string
        require(from != address(0), "ERC777: transfer from the zero address");
        // solhint-disable-next-line reason-string
        require(to != address(0), "ERC777: transfer to the zero address");

        address operator = msg.sender;

        // TODO: Get rid of the hardcoded calls to LibTokenReflections, in favor of the hook system.
        // Pay token taxes if needed.
        amount = LibTokenTaxes.payTaxes(from, to, amount);

        _callTokensToSend(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            requireReceptionAck
        );

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            requireReceptionAck
        );
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function burn(
        address operator,
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal {
        // solhint-disable-next-line reason-string
        require(from != address(0), "ERC777: burn from the zero address");

        _callTokensToSend(
            operator,
            from,
            address(0),
            amount,
            data,
            operatorData,
            requireReceptionAck
        );

        beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _storage().balances[from];
        // solhint-disable-next-line reason-string
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _storage().balances[from] = fromBalance - amount;
        }
        _storage().totalSupply -= amount;

        // Notify token-reflections module abou the decreased balance.
        LibTokenReflections.accountBalanceUpdated(from);

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _storage().balances[from];
        // solhint-disable-next-line reason-string
        require(
            fromBalance >= amount,
            "ERC777: transfer amount exceeds balance"
        );
        unchecked {
            _storage().balances[from] = fromBalance - amount;
        }
        _storage().balances[to] += amount;

        // TODO: Get rid of the hardcoded calls to LibTokenReflections, in favor of the hook system.

        // Notify token-reflections module about the decreased balance.
        LibTokenReflections.accountBalanceUpdated(from);
        // Notify token-reflections module about the increased balance.
        LibTokenReflections.accountBalanceUpdated(to);

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev See {ERC20-_approve}.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(
        address holder,
        address spender,
        uint256 value
    ) internal {
        // solhint-disable-next-line reason-string
        require(holder != address(0), "ERC777: approve from the zero address");
        // solhint-disable-next-line reason-string
        require(spender != address(0), "ERC777: approve to the zero address");

        _storage().allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        if (!requireReceptionAck) {
            return;
        }
        address implementer = ERC1820_REGISTRY.getInterfaceImplementer(
            from,
            TOKENS_SENDER_INTERFACE_HASH
        );
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(
                operator,
                from,
                to,
                amount,
                userData,
                operatorData
            );
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        if (!requireReceptionAck) {
            return;
        }

        address implementer = ERC1820_REGISTRY.getInterfaceImplementer(
            to,
            TOKENS_RECIPIENT_INTERFACE_HASH
        );
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(
                operator,
                from,
                to,
                amount,
                userData,
                operatorData
            );
        } else if (requireReceptionAck) {
            // solhint-disable-next-line reason-string
            require(
                !to.isContract(),
                "ERC777: token recipient contract has no implementer for ERC777TokensRecipient"
            );
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC777: insufficient allowance"
            );
            unchecked {
                approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount // solhint-disable-next-line no-empty-blocks
    ) internal {
        // TODO: Call tax module
    }
}
