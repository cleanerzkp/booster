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

import {ITokenTaxes} from "./ITokenTaxes.sol";
import {LibTokenTaxes} from "./LibTokenTaxes.sol";
import {LibAccessControl} from "../access/LibAccessControl.sol";
import {LibRoles} from "../access/LibRoles.sol";

contract TokenTaxesFacet is ITokenTaxes {
    /**
     * @inheritdoc ITokenTaxes
     */
    function getTokenTax(string memory name)
        external
        view
        returns (ITokenTaxes.Tax memory tax)
    {
        tax = LibTokenTaxes.getTax(name);
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function getTokenTax(bytes32 name)
        external
        view
        returns (ITokenTaxes.Tax memory tax)
    {
        tax = LibTokenTaxes.getTax(name);
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function getAddressTokenTaxNames(address taxedAddress)
        external
        view
        returns (bytes32[] memory taxNames)
    {
        taxNames = LibTokenTaxes.getAddressTaxNames(taxedAddress);
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function doesAddressHaveTokenTax(address taxedAddress, bytes32 taxName)
        external
        view
        returns (bool)
    {
        return LibTokenTaxes.doesAddressHaveTax(taxedAddress, taxName);
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function isExemptFromTokenTaxes(address account)
        external
        view
        returns (bool)
    {
        return LibTokenTaxes.isExemptFromTaxes(account);
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function setExemptFromTokenTaxes(address account, bool flag) external {
        LibAccessControl.enforceRole(LibRoles.TOKEN_TAXES_MANAGER);

        LibTokenTaxes.setExemptFromTaxes(account, flag);
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function tokenTaxesIsEnabled() external view returns (bool enabled) {
        enabled = LibTokenTaxes.isEnabled();
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function tokenTaxesEnable() external {
        LibAccessControl.enforceRole(LibRoles.TOKEN_TAXES_MANAGER);

        LibTokenTaxes.enable();
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function tokenTaxesDisable() external {
        LibAccessControl.enforceRole(LibRoles.TOKEN_TAXES_MANAGER);

        LibTokenTaxes.disable();
    }

    /**
     * @dev Sets the `distributionPeriod`.
     *
     * @param distributionPeriod The period to set.
     */
    function tokenTaxesSetDistributionPeriod(uint32 distributionPeriod)
        external
    {
        LibAccessControl.enforceRole(LibRoles.TOKEN_TAXES_MANAGER);

        LibTokenTaxes.setDistributionPeriod(distributionPeriod);
    }

    /**
     * @dev Returns the `distributionPeriod`.
     *
     * @return distributionPeriod The configured period.
     */
    function tokenTaxesGetDistributionPeriod() external view returns (uint32) {
        return LibTokenTaxes.getDistributionPeriod();
    }

    /**
     * @dev Returns the timestamp of the last token tax distribution.
     *
     * @return distributedAt The timestamp of the last tax distribution.
     */
    function tokenTaxesGetDistributedAt() external view returns (uint32) {
        return LibTokenTaxes.getDistributedAt();
    }

    /**
     * @inheritdoc ITokenTaxes
     */
    function tokenTaxesGetInfoResponse()
        external
        view
        returns (ITokenTaxes.TaxesInfoResponse memory)
    {
        return LibTokenTaxes.getTaxesInfoResponse();
    }
}
