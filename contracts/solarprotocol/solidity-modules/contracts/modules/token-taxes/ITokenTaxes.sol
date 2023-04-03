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

interface ITokenTaxes {
    enum TaxType {
        Buy,
        Sell
    }

    // The taxes must be a multiple of 100
    struct Tax {
        string name;
        bytes32 tokenDitributorStrategyId;
        uint16 buy;
        uint16 sell;
    }

    struct TaxesInfoResponse {
        // Kill switch to enable/disable the token-tax module.
        bool enabled;
        // If enabled, the tax distribution will be triggered during sell transactions.
        bool distributeOnSell;
        // Last time the collected taxes have been distributed.
        uint32 distributedAt;
        // Amount of seconds between distributions.
        uint32 distributionPeriod;
        // Array with all tax names, to allow iteration.
        bytes32[] taxNames;
    }

    error TokenTaxNotFound(bytes32 taxName);
    error TokenTaxAlreadyExists(bytes32 taxName);

    /**
     * @dev Emitted when the token-taxes module is enabled.
     */
    event TokenTaxesEnabled();

    /**
     * @dev Emitted when the token-taxes module is disabled.
     */
    event TokenTaxesDisabled();

    /**
     * @dev Emitted when a token tax with `name` is set.
     */
    event TokenTaxSet(string name);

    /**
     * @dev Emitted when token tax with `taxName` is added to a `taxedAddress`.
     */
    event TokenTaxAdded(address taxedAddress, bytes32 taxName);

    /**
     * @dev Emitted when token tax with `taxName` is removed from a `taxedAddress`.
     */
    event TokenTaxRemoved(address taxedAddress, bytes32 taxName);

    /**
     * @dev Emitted when the exempt from taxes flag of `account` is set.
     */
    event TokenTaxSetExemptFlag(address account, bool flag);

    /**
     * @dev Returns a tax by it's string name.
     *
     * @dev name Tax name as a string.
     *
     * @return tax The found tax.
     */
    function getTokenTax(string memory name)
        external
        view
        returns (Tax memory tax);

    /**
     * @dev Returns a tax by it's bytes32 name.
     *
     * @dev name Tax name as bytes32.
     *
     * @return tax The found tax.
     */
    function getTokenTax(bytes32 name)
        external
        view
        returns (ITokenTaxes.Tax memory tax);

    /**
     * @dev Returns the `taxNames` stored for `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     *
     * @return taxNames Array with tax names stored for `taxedAddress`.
     */
    function getAddressTokenTaxNames(address taxedAddress)
        external
        view
        returns (bytes32[] memory taxNames);

    /**
     * @dev Checks if `taxName` (string) is assigned to `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     * @param taxName String name of the tax.
     */
    function doesAddressHaveTokenTax(address taxedAddress, bytes32 taxName)
        external
        view
        returns (bool);

    /**
     * @dev Checks if `account` is exempt from taxes.
     *
     * @return True if `account` is exempt from taxes.
     */
    function isExemptFromTokenTaxes(address account)
        external
        view
        returns (bool);

    /**
     * @dev Sets the `account`'s exempt from tax status to `flag`.
     * Emits an {TokenTaxSetExemptFlag} event.
     *
     * @param account The account to set the `flag` for.
     * @param flag The status flag.
     */
    function setExemptFromTokenTaxes(address account, bool flag) external;

    /**
     * @dev Returns the current enabled state.
     */
    function tokenTaxesIsEnabled() external view returns (bool enabled);

    /**
     * @dev Enables the token-taxes module.
     * Emits an {TokenTaxesEnabled} event.
     */
    function tokenTaxesEnable() external;

    /**
     * @dev Disables the token-taxes module
     * Emits an {TokenTaxesDisabled} event.
     */
    function tokenTaxesDisable() external;

    /**
     * @dev Sets the `distributionPeriod`.
     *
     * @param distributionPeriod The period to set.
     */
    function tokenTaxesSetDistributionPeriod(uint32 distributionPeriod)
        external;

    /**
     * @dev Returns the `distributionPeriod`.
     *
     * @return distributionPeriod The configured period.
     */
    function tokenTaxesGetDistributionPeriod() external view returns (uint32);

    /**
     * @dev Returns the timestamp of the last token tax distribution.
     *
     * @return distributedAt The timestamp of the last tax distribution.
     */
    function tokenTaxesGetDistributedAt() external view returns (uint32);

    /**
     * @dev Returns an info response. Mainly for testing and debuggind.
     *
     * @return taxesInfoResponse An instance of the ITokenTaxes.TaxesInfoResponse struct, with data from the storage.
     */
    function tokenTaxesGetInfoResponse()
        external
        view
        returns (ITokenTaxes.TaxesInfoResponse memory);
}
