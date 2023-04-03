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

interface IUniswapFacet {
    /**
     * @dev Returns the configured `factory`.
     *
     * @return factory The configured factory.
     */
    function uniswapGetFactory() external view returns (address factory);

    /**
     * @dev Returns the configured `router`.
     *
     * @return router The configured router.
     */
    function uniswapGetRouter() external view returns (address router);

    /**
     * @dev Returns the configured `tokenB`.
     *
     * @return tokenB The configured tokenB.
     */
    function uniswapGetTokenB() external view returns (address tokenB);

    /**
     * @dev Returns the configured intermediateWallet address.
     * It is used as a temporary place to swap to, if one of the swapped tokens is the current contract.
     *
     * @return intermediateWallet The address of the intermediateWallet.
     */
    function uniswapGetIntermediateWallet()
        external
        view
        returns (address intermediateWallet);
}
