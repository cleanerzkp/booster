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

import {LibDiamondExtras} from "./LibDiamondExtras.sol";
import {IDiamondCut} from "contracts-starter/contracts/interfaces/IDiamondCut.sol";
import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";

/**
 * @notice This contract is based on the diamond-3-hardhat original contract
 *  with the constructor from hardhat-deploy's version
 *  and some customization of the fallback functions.
 * See: https://eips.ethereum.org/EIPS/eip-2535
 */
contract Diamond {
    struct Initialization {
        address initContract;
        bytes initData;
    }

    constructor(
        address _contractOwner,
        IDiamondCut.FacetCut[] memory _diamondCut,
        Initialization[] memory _initializations
    ) payable {
        if (_contractOwner != address(0)) {
            LibDiamond.setContractOwner(_contractOwner);
        }

        LibDiamond.diamondCut(_diamondCut, address(0), "");

        for (uint256 i = 0; i < _initializations.length; i++) {
            LibDiamond.initializeDiamondCut(
                _initializations[i].initContract,
                _initializations[i].initData
            );
        }
    }

    /**
     * @dev Default fallback function that delegates all calls to the facets with the implementation
     */
    fallback() external payable {
        LibDiamondExtras.delegate(msg.sig);
    }

    /**
     * @dev Fallback function for calles with value and no calldata
     * that delegates the call to the receive function of a facet.
     *
     * How it works:
     *  The selector `receiveFallback()` is used to find a facet and then
     *  the call will be delegated to that facet.
     *  In the facet we define a `receive()` fallback function that will be called.
     */
    receive() external payable {
        LibDiamondExtras.delegate(bytes4(keccak256("receiveFallback()")));
    }
}
