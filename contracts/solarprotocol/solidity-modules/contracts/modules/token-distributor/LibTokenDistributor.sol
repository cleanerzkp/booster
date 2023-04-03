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

import {ITokenDitributor} from "./ITokenDitributor.sol";
import {LibValidator} from "../../utils/LibValidator.sol";
import {LibSoloToken} from "../solo-token/LibSoloToken.sol";
import {LibUniswap} from "../uniswap/LibUniswap.sol";
import {LibTokenReflections} from "../token-reflections/LibTokenReflections.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Library that implements a universally configurable token distributer.
 */
library LibTokenDistributor {
    using SafeERC20 for IERC20;

    struct Storage {
        mapping(bytes32 => ITokenDitributor.Strategy) strategyMap;
    }

    uint16 internal constant DENOMINATOR = 10000;

    bytes32 private constant STORAGE_SLOT =
        keccak256(
            "solarprotocol.contracts.token-distributor.LibTokenDistributor.V2"
        );

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
     * @dev Takes `amount` of `strategy.token` from `from` and distributes it among `strategy.distributions`.
     * Based on configuration, allows for automatic swapping and/or adding LP on Uniswap V2 based DEXes
     * @notice Because of Uniswap limitations, Swaps of `address(this)` (solo-token) will not work during buys.
     * And for swaps of `address(this)` in general the `intermediateWallet` must be configured in LibUniswap.
     *
     * @param strategyId Id of the distribution strategy.
     * @param from Source of tokens for the disribution.
     * @param amount The amount of tokens to distribute.
     */
    function distribute(
        bytes32 strategyId,
        address from,
        uint256 amount
    ) internal {
        ITokenDitributor.Strategy memory strategy = get(strategyId);

        address token = strategy.token;

        // First transfer the amount of token to the contract,
        // to make all other operations easier and comprehensible on the block scanner.
        if (from != address(this)) {
            sendToken(token, from, address(this), amount, address(0), false);
        }

        // Swap the token to `strategy.swapTo` if configured.
        if (strategy.swapTo != address(0)) {
            amount = LibUniswap.swap(
                amount,
                address(token),
                strategy.swapTo,
                address(this)
            );
            token = strategy.swapTo;
        }

        distribute(token, amount, strategy.distributions);
    }

    /**
     * @dev Distributes `amount` of `token` between the `distributions`.
     * Based on configuration, allows for automatic swapping and/or adding LP on Uniswap V2 based DEXes
     * @notice Because of Uniswap limitations, Swaps of `address(this)` (solo-token) will not work during buys.
     * And for swaps of `address(this)` in general the `intermediateWallet` must be configured in LibUniswap.
     * Requires the sum of all proportions to be equal to 100%.
     *
     * @param token The token to be distributed
     * @param amount The amount of tokens to distribute.
     * @param distributions Array of distribution setings.
     */
    function distribute(
        address token,
        uint256 amount,
        ITokenDitributor.Distribution[] memory distributions
    ) internal {
        uint256 sum = 0;
        uint256 strategyDistributionsLength = distributions.length;
        for (uint256 index = 0; index < strategyDistributionsLength; ) {
            ITokenDitributor.Distribution memory distribution = distributions[
                index
            ];

            sum += distribution.proportion;

            // TODO: Get rid of the hardcoded calls to LibTokenReflections, in favor of the hook system.

            bool isReflectionVault = LibTokenReflections.isRewardsTokenVault(
                distribution.destination
            );

            if (isReflectionVault) {
                // Snapshot the current token balance in the reflections vault for later calculation of added amount.
                LibTokenReflections.updateRewardsTokenVaultBalance();
            }

            sendToken(
                token,
                address(this),
                distribution.destination,
                (amount * distribution.proportion) / DENOMINATOR,
                distribution.swapTo,
                distribution.addLiquidity
            );

            if (isReflectionVault) {
                // Calculate the amount of rewards tokens added to the reflection vault and can be added to the pool.
                LibTokenReflections.updateRewardsAmountPendingInVault();

                // Add pending amount of new reward tokens in vault, to the pool if needed.
                LibTokenReflections.addRewardsAmountPending();
            }

            unchecked {
                ++index;
            }
        }

        if (sum != DENOMINATOR) {
            revert ITokenDitributor.StrategyDistributionPortionsNot100();
        }
    }

    /**
     * @dev Sends the provided `amount` of `token` from `from` to `to`.
     * Integrates with LibUniswap to allow for swapping to another token before sending.
     * Additionally it can zapIn liquidity to the token/swapTo pair. In this case it will send the LP token to the destination.
     * If the provided token is `address(this)` and `swapTo` is not set, it will use LibSoloToken for sending.
     *
     * @param token Token to be transfered.
     * @param from Address to transfer `token` from.
     * @param to Recepient of the tokens.
     * @param amount The amount to transfer.
     * @param swapTo If set, will be used as tokenB to swap `token` directly to `to`.
     * @param addLiquidity If set, will zapIn to `token`/`swapTo` pair and mint LP token to `to`.
     *
     * @return amountOut Amount of tokens sent to `to`.
     */
    function sendToken(
        address token,
        address from,
        address to,
        uint256 amount,
        address swapTo,
        bool addLiquidity
    ) internal returns (uint256 amountOut) {
        if (swapTo == address(0)) {
            amountOut = amount;

            if (address(token) == address(this)) {
                // solhint-disable-next-line check-send-result
                LibSoloToken.send(from, to, amount, "", "", false);
            } else {
                IERC20(token).safeTransferFrom(from, to, amount);
            }
        } else {
            if (addLiquidity) {
                (, , amountOut) = LibUniswap.zapInLiquidity(
                    token,
                    swapTo,
                    amount,
                    to
                );
            } else {
                amountOut = LibUniswap.swap(amount, token, swapTo, to);
            }
        }
    }

    /**
     * @dev Returns the strategy with `strategyId`.
     *
     * @param strategyId Id of the distribution strategy.
     *
     * @return strategy The stored strategy.
     */
    function get(bytes32 strategyId)
        internal
        view
        returns (ITokenDitributor.Strategy memory strategy)
    {
        strategy = _storage().strategyMap[strategyId];

        if (strategy.distributions.length == 0) {
            revert ITokenDitributor.StrategyNotFound(strategyId);
        }
    }

    /**
     * @dev Adds new `strategy`with `strategyId`.
     *
     * @param strategyId Id of the distribution strategy.
     * @param strategy The strategy struct to be stored.
     */
    function add(bytes32 strategyId, ITokenDitributor.Strategy memory strategy)
        internal
    {
        Storage storage s = _storage();

        if (address(s.strategyMap[strategyId].token) != address(0)) {
            revert ITokenDitributor.StrategyAlreadyExists(strategyId);
        }

        if (strategy.distributions.length == 0) {
            revert ITokenDitributor.StrategyHasNoDistributions();
        }

        setStrategyToken(strategyId, strategy.token);
        setStrategySwapTo(strategyId, strategy.swapTo);

        uint256 sum = 0;
        for (
            uint256 index = 0;
            index < strategy.distributions.length;
            ++index
        ) {
            ITokenDitributor.Distribution memory distribution = strategy
                .distributions[index];

            if (
                distribution.swapTo != address(0) &&
                distribution.swapTo != address(this)
            ) {
                LibValidator.validateIsERC20(distribution.swapTo);
            }

            sum += distribution.proportion;
            s.strategyMap[strategyId].distributions.push(distribution);
        }

        if (sum != DENOMINATOR) {
            revert ITokenDitributor.StrategyDistributionPortionsNot100();
        }
    }

    function setStrategyToken(bytes32 strategyId, address token) internal {
        if (token != address(this)) {
            LibValidator.validateIsERC20(token);
        }

        _storage().strategyMap[strategyId].token = token;
    }

    function setStrategySwapTo(bytes32 strategyId, address swapTo) internal {
        if (swapTo != address(0) && swapTo != address(this)) {
            LibValidator.validateIsERC20(swapTo);
        }

        _storage().strategyMap[strategyId].swapTo = swapTo;
    }

    /**
     * @dev Update the distributions of the existing strategy with `strategyId`.
     *
     * @param strategyId Id of the distribution strategy.
     * @param distributions The destinations struct to be stored.
     */
    function updateDistributions(
        bytes32 strategyId,
        ITokenDitributor.Distribution[] memory distributions
    ) internal {
        ITokenDitributor.Strategy memory strategy = _storage().strategyMap[
            strategyId
        ];

        if (address(strategy.token) == address(0)) {
            revert ITokenDitributor.StrategyNotFound(strategyId);
        }

        if (distributions.length == 0) {
            revert ITokenDitributor.StrategyHasNoDistributions();
        }

        if (strategy.distributions.length != distributions.length) {
            revert ITokenDitributor.StrategyDistributionsLengthMissmatch();
        }

        uint256 sum = 0;
        for (uint256 index = 0; index < distributions.length; ++index) {
            ITokenDitributor.Distribution memory distribution = strategy
                .distributions[index];

            if (
                distribution.swapTo != address(0) &&
                distribution.swapTo != address(this)
            ) {
                LibValidator.validateIsERC20(distribution.swapTo);
            }

            sum += distribution.proportion;
            _storage().strategyMap[strategyId].distributions[
                index
            ] = distribution;
        }

        if (sum != DENOMINATOR) {
            revert ITokenDitributor.StrategyDistributionPortionsNot100();
        }
    }
}
