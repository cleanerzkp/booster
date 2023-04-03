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

import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibUniswap {
    using SafeERC20 for IERC20;

    struct Storage {
        IUniswapV2Factory factory;
        IUniswapV2Router02 router;
        address tokenB;
        address intermediateWallet;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.uniswap.LibUniswap");

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
     * @dev Swaps `amountIn` of input tokens for output tokens in the path and sends the amountOut to `amountOutReceiver`
     * using `router`.
     * @notice Uses swapExactTokensForTokensSupportingFeeOnTransferTokens()
     * @notice In case either input token or output token is same as `amountOutReceiver`,
     * The `intermediateWallet` will be used to swap to it and then transfer the `amountOut` back to the `amountOutReceiver`.
     * For this to work, `address(this)` must have an allowance from `intermediateWallet` to spend the output token.
     *
     * @param router The router to use.
     * @param amountIn The amount of `tokenA` to send.
     * @param path An array of token addresses. `path.length` must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param amountOutReceiver Recipient of the amountOut.
     *
     * @return amountOut The amount of last token in the path sent to the `amountOutReceiver`.
     */
    function swap(
        IUniswapV2Router02 router,
        uint256 amountIn,
        address[] memory path,
        address amountOutReceiver,
        bool skipApproval
    ) internal returns (uint256 amountOut) {
        Storage storage s = _storage();

        require(path.length >= 2, "LibUniswap: path too small");

        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        // Approve `tokenIn` if needed
        if (
            !skipApproval &&
            IERC20(tokenIn).allowance(address(this), address(router)) < amountIn
        ) {
            // slither-disable-next-line unused-return
            IERC20(tokenIn).approve(address(router), amountIn);
        }

        address to = amountOutReceiver;

        // Swap to an intermediateWallet, to work around uniswap's limitation.
        // Uniswap does not allow the receiver of the swapped token to be any of the tokens that are swapped.
        if (to == tokenIn || to == tokenOut) {
            to = s.intermediateWallet;
        }

        uint256 initialBalance = IERC20(tokenOut).balanceOf(to);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            to,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        amountOut = IERC20(tokenOut).balanceOf(to) - initialBalance;

        // If we swapped to the intermediateWallet, we need to send the swapped amount back to the amountOutReceiver.
        if (to != amountOutReceiver) {
            IERC20(tokenOut).safeTransferFrom(to, amountOutReceiver, amountOut);
        }
    }

    /**
     * @dev Swaps `amountIn` of `tokenA` for `tokenB` and sends the amountOut to `amountOutReceiver`
     * using `router`.
     * @notice Uses swapExactTokensForTokensSupportingFeeOnTransferTokens()
     * @notice In case either `tokenA` or `tokenB` is same as `amountOutReceiver`,
     * The `intermediateWallet` will be used to swap to it and then transfer the `amountOut` back to the `amountOutReceiver`.
     * For this to work, `address(this)` must have an allowance from `intermediateWallet` to spend `tokenB`.
     *
     * @param router The router to use.
     * @param amountIn The amount of `tokenA` to send.
     * @param tokenA The input token.
     * @param tokenB The output token.
     * @param amountOutReceiver Recipient of the amountOut.
     *
     * @return amountOut The amount of `tokenB` sent to the `amountOutReceiver`.
     */
    function swap(
        IUniswapV2Router02 router,
        uint256 amountIn,
        address tokenA,
        address tokenB,
        address amountOutReceiver,
        bool skipApproval
    ) internal returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        amountOut = swap(
            router,
            amountIn,
            path,
            amountOutReceiver,
            skipApproval
        );
    }

    /**
     * @dev Swaps `amountIn` of `tokenA` for `tokenB` and sends the amountOut to `amountOutReceiver`
     * using `router`.
     * @notice Uses swapExactTokensForTokensSupportingFeeOnTransferTokens()
     *
     * @param amountIn The amount of `tokenA` to send.
     * @param tokenA The input token.
     * @param tokenB The output token.
     * @param amountOutReceiver Recipient of the amountOut.
     *
     * @return amountB The amount of `tokenB` sent to the `amountOutReceiver`.
     */
    function swap(
        uint256 amountIn,
        address tokenA,
        address tokenB,
        address amountOutReceiver
    ) internal returns (uint256 amountB) {
        return
            swap(
                _storage().router,
                amountIn,
                tokenA,
                tokenB,
                amountOutReceiver,
                false
            );
    }

    /**
     * @dev Swaps `amountIn` of input tokens for output tokens in the path and sends the amountOut to `amountOutReceiver`
     * using `router`.
     * @notice Uses swapExactTokensForTokensSupportingFeeOnTransferTokens()
     *
     * @param amountIn The amount of `tokenA` to send.
     * @param path An array of token addresses. `path.length` must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param amountOutReceiver Recipient of the amountOut.
     *
     * @return amountOut The amount of last token in the path sent to the `amountOutReceiver`.
     */
    function swap(
        uint256 amountIn,
        address[] memory path,
        address amountOutReceiver
    ) internal returns (uint256 amountOut) {
        return
            swap(_storage().router, amountIn, path, amountOutReceiver, false);
    }

    struct AddLiquidityParameters {
        IUniswapV2Router02 router;
        address lpTokenReceiver;
        address tokenA;
        address tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        bool skipApproval;
    }

    /**
     * @dev Adds `amountADesired` and `amountBDesired` as liquidity to pair of `tokenA` and `tokenB`
     * using `router` and sends the minted LP token to `lpTokenReceiver`.
     * @notice AddLiquidityParameters struct is used to overcome the "Stack too deep" compilation error.
     *
     * @param parameters.router The router to use.
     * @param parameters.lpTokenReceiver Recipient of the liquidity tokens.
     * @param parameters.tokenA First pool token.
     * @param parameters.tokenB Second pool token.
     * @param parameters.amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
     * @param parameters.amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(AddLiquidityParameters memory parameters)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        // Approve `tokenA` if needed
        if (
            !parameters.skipApproval &&
            IERC20(parameters.tokenA).allowance(
                address(this),
                address(parameters.router)
            ) <
            parameters.amountADesired
        ) {
            // slither-disable-next-line unused-return
            IERC20(parameters.tokenA).approve(
                address(parameters.router),
                parameters.amountADesired
            );
        }

        // Approve `tokenB` if needed
        if (
            !parameters.skipApproval &&
            IERC20(parameters.tokenB).allowance(
                address(this),
                address(parameters.router)
            ) <
            parameters.amountBDesired
        ) {
            // slither-disable-next-line unused-return
            IERC20(parameters.tokenB).approve(
                address(parameters.router),
                parameters.amountBDesired
            );
        }

        return
            parameters.router.addLiquidity(
                parameters.tokenA,
                parameters.tokenB,
                parameters.amountADesired,
                parameters.amountBDesired,
                0,
                0,
                parameters.lpTokenReceiver,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
    }

    /**
     * @dev Adds `amountADesired` and `amountBDesired` as liquidity to pair of `tokenA` and `tokenB`
     * using stored `router` and sends the minted LP token to `lpTokenReceiver`.
     *
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     * @param tokenA First pool token.
     * @param tokenB Second pool token.
     * @param amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
     * @param amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address lpTokenReceiver,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        return
            addLiquidity(
                AddLiquidityParameters({
                    router: _storage().router,
                    lpTokenReceiver: lpTokenReceiver,
                    tokenA: tokenA,
                    tokenB: tokenB,
                    amountADesired: amountADesired,
                    amountBDesired: amountBDesired,
                    skipApproval: false
                })
            );
    }

    /**
     * @dev Adds `amountADesired` and `amountBDesired` as liquidity to pair of `address(this)` (solo-token) and stored `tokenB`
     * using stored `router` and sends the minted LP token to `lpTokenReceiver`.
     *
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     * @param amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
     * @param amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        address lpTokenReceiver
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        Storage storage s = _storage();

        return
            addLiquidity(
                AddLiquidityParameters({
                    router: s.router,
                    lpTokenReceiver: lpTokenReceiver,
                    tokenA: address(this),
                    tokenB: s.tokenB,
                    amountADesired: amountADesired,
                    amountBDesired: amountBDesired,
                    skipApproval: false
                })
            );
    }

    /**
     * @dev Swaps half `amount` of `tokenA` to `tokenB`, adds to their liquidity
     * using `router` and sends the minted LP to `lpTokenReceiver`.
     * @notice The swap will be performed with 100% slipage!
     *
     * @param router The router to use.
     * @param tokenA First pool token.
     * @param tokenB Second pool token.
     * @param amount The amount of `tokenA` to be swaped.
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function zapInLiquidity(
        IUniswapV2Router02 router,
        address tokenA,
        address tokenB,
        uint256 amount,
        address lpTokenReceiver
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        uint256 half = amount / 2;

        // Approve `tokenA` if needed
        if (IERC20(tokenA).allowance(address(this), address(router)) < half) {
            // slither-disable-next-line unused-return
            IERC20(tokenA).approve(address(router), half);
        }

        // Approve `tokenB` if needed
        if (IERC20(tokenB).allowance(address(this), address(router)) < half) {
            // slither-disable-next-line unused-return
            IERC20(tokenB).approve(address(router), half);
        }

        uint256 swapedAmount = swap(
            router,
            half,
            tokenA,
            tokenB,
            address(this),
            true
        );

        return
            addLiquidity(
                AddLiquidityParameters({
                    router: router,
                    lpTokenReceiver: lpTokenReceiver,
                    tokenA: tokenA,
                    tokenB: tokenB,
                    amountADesired: half,
                    amountBDesired: swapedAmount,
                    skipApproval: true
                })
            );
    }

    /**
     * @dev Swaps half `amount` of `tokenA` to `tokenB`, adds to their liquidity
     * using stored `router` and sends the minted LP to `lpTokenReceiver`.
     * @notice The swap will be performed with 100% slipage!
     *
     * @param tokenA First pool token.
     * @param tokenB Second pool token.
     * @param amount The amount of `tokenA` to be swaped.
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     *
     * @return amountA The amount of tokenA sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function zapInLiquidity(
        address tokenA,
        address tokenB,
        uint256 amount,
        address lpTokenReceiver
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        return
            zapInLiquidity(
                _storage().router,
                tokenA,
                tokenB,
                amount,
                lpTokenReceiver
            );
    }

    /**
     * @dev Swaps half `amount` of `address(this)` (solo-token) to `tokenB`, adds to their liquidity
     * using stored `router` and sends the minted LP to `lpTokenReceiver`.
     * @notice The swap will be performed with 100% slipage!
     *
     * @param tokenB Second pool token.
     * @param amount The amount of `address(this)` (solo-token) to be swaped.
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     *
     * @return amountA The amount of `address(this)` (solo-token) sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function zapInLiquidity(
        address tokenB,
        uint256 amount,
        address lpTokenReceiver
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        return
            zapInLiquidity(
                _storage().router,
                address(this),
                tokenB,
                amount,
                lpTokenReceiver
            );
    }

    /**
     * @dev Swaps half `amount` of `address(this)` (solo-token) to stored `tokenB`, adds to their liquidity
     * using stored `router` and sends the minted LP to `lpTokenReceiver`.
     * @notice The swap will be performed with 100% slipage!
     *
     * @param amount The amount of `address(this)` (solo-token) to be swaped.
     * @param lpTokenReceiver Recipient of the liquidity tokens.
     *
     * @return amountA The amount of `address(this)` (solo-token) sent to the pool.
     * @return amountB The amount of tokenB sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function zapInLiquidity(uint256 amount, address lpTokenReceiver)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        Storage storage s = _storage();

        return
            zapInLiquidity(
                s.router,
                address(this),
                s.tokenB,
                amount,
                lpTokenReceiver
            );
    }

    /**
     * @dev Creates a pair of `address(this)` (solo-token) and `tokenB`, using `factory`.
     * Returns the created `pair`.
     *
     * @param factory The factory to use.
     * @param tokenB Second pool token.
     *
     * @return pair Address of the created LP.
     */
    function createPair(IUniswapV2Factory factory, address tokenB)
        internal
        returns (address pair)
    {
        pair = factory.createPair(address(this), tokenB);
    }

    /**
     * @dev Creates a pair of `address(this)` (solo-token) and `tokenB`, using the factory from the storage.
     * Returns the created `pair`.
     *
     * @param tokenB Second pool token.
     *
     * @return pair Address of the created LP.
     */
    function createPair(address tokenB) internal returns (address pair) {
        pair = _storage().factory.createPair(address(this), tokenB);
    }

    /**
     * @dev Creates a pair of `address(this)` (solo-token) and stored `tokenB`, using the factory from the storage.
     * Returns the created `pair`.
     *
     * @return pair Address of the created LP.
     */
    function createPair() internal returns (address pair) {
        Storage storage s = _storage();

        pair = s.factory.createPair(address(this), s.tokenB);
    }

    function setFactory(IUniswapV2Factory factory) internal {
        _storage().factory = factory;
    }

    function getFactory() internal view returns (IUniswapV2Factory factory) {
        factory = _storage().factory;
    }

    function setRouter(IUniswapV2Router02 router) internal {
        _storage().router = router;
    }

    function getRouter() internal view returns (IUniswapV2Router02 router) {
        router = _storage().router;
    }

    function setTokenB(address tokenB) internal {
        _storage().tokenB = tokenB;
    }

    function getTokenB() internal view returns (address tokenB) {
        tokenB = _storage().tokenB;
    }

    function setIntermediateWallet(address intermediateWallet) internal {
        _storage().intermediateWallet = intermediateWallet;
    }

    function getIntermediateWallet()
        internal
        view
        returns (address intermediateWallet)
    {
        intermediateWallet = _storage().intermediateWallet;
    }
}
