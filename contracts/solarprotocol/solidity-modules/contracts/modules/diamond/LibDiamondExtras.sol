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

import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

library LibDiamondExtras {
    function setERC165(bytes4 interfaceId) internal {
        bytes4[] memory interfaceIds = new bytes4[](1);

        interfaceIds[0] = interfaceId;
        setERC165(interfaceIds, new bytes4[](0));
    }

    function setERC165(bytes4[] memory interfaceIds) internal {
        setERC165(interfaceIds, new bytes4[](0));
    }

    function setERC165(
        bytes4[] memory interfaceIds,
        bytes4[] memory interfaceIdsToRemove
    ) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.supportedInterfaces[type(IERC165).interfaceId] = true;

        for (uint256 i = 0; i < interfaceIds.length; i++) {
            ds.supportedInterfaces[interfaceIds[i]] = true;
        }

        for (uint256 i = 0; i < interfaceIdsToRemove.length; i++) {
            ds.supportedInterfaces[interfaceIdsToRemove[i]] = false;
        }
    }

    /**
     * @dev Returns the address of the facet that implements `selector`.
     */
    function getFacetBySelector(bytes4 selector)
        internal
        view
        returns (address facet)
    {
        // get diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // get facet from function selector
        facet = ds.selectorToFacetAndPosition[selector].facetAddress;
    }

    /**
     * @dev Delegates the call to the facet implementing `selector`.
     */
    function delegate(bytes4 selector) internal {
        address facet = getFacetBySelector(selector);

        require(facet != address(0), "Diamond: Function does not exist");

        delegate(facet);
    }

    /**
     * @dev Delegates the call to the `facet`.
     */
    function delegate(address facet) internal {
        // Execute external function from facet using delegatecall and return any value.
        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
