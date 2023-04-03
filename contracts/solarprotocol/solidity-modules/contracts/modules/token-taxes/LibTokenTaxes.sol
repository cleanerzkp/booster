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
import {LibTokenDistributor} from "../token-distributor/LibTokenDistributor.sol";
import {LibSoloToken} from "../solo-token/LibSoloToken.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Library to manage and apply token taxes.
 * Multiple Tax groups can be defined and multiple of them can be assigned to multiple addresses (pairs).
 * All taxes are distributed by token distributor strategies.
 */
library LibTokenTaxes {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Storage {
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
        // Mapping of tax names to tax structs.
        mapping(bytes32 => ITokenTaxes.Tax) taxes;
        // Mapping of addresses (lp pairs) to a set of applicable tax structs.
        mapping(address => EnumerableSet.Bytes32Set) addressTaxes;
        // Mapping of addresses exempt from taxes.
        // All transfers from or to those addresses will be tax exempt.
        mapping(address => bool) exemptFromTaxes;
        // Amounts of taxes collected for each tax so far.
        mapping(bytes32 => uint256) collectedTaxes;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.token-taxes.LibTokenTaxes");

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
    event TokenTaxAddedToAddress(address taxedAddress, bytes32 taxName);

    /**
     * @dev Emitted when token tax with `taxName` is removed from a `taxedAddress`.
     */
    event TokenTaxRemovedFromAddress(address taxedAddress, bytes32 taxName);

    /**
     * @dev Emitted when the exempt from taxes flag of `account` is set.
     */
    event TokenTaxSetExemptFlag(address account, bool flag);

    /**
     * @dev Does pay any taxes applicable to the `bruttoAmount` transferred `from` to `to`.
     * Returns the nettoAmount after all paid taxes.
     *
     * @param from The sender of the transfer.
     * @param to The recepient of the transfer.
     * @param bruttoAmount The transfered amount.
     *
     * @return nettoAmount The amount after applied taxes.
     */
    function payTaxes(
        address from,
        address to,
        uint256 bruttoAmount
    ) internal returns (uint256 nettoAmount) {
        Storage storage s = _storage();

        if (!s.enabled) {
            return bruttoAmount;
        }

        nettoAmount = bruttoAmount;

        if (isExemptFromTaxes(from) || isExemptFromTaxes(to)) {
            return nettoAmount;
        }

        EnumerableSet.Bytes32Set storage fromTaxNames = s.addressTaxes[from];
        EnumerableSet.Bytes32Set storage toTaxNames = s.addressTaxes[to];

        if (fromTaxNames.length() > 0) {
            nettoAmount = preccessTaxes(
                from,
                nettoAmount,
                fromTaxNames,
                ITokenTaxes.TaxType.Buy
            );
        } else if (toTaxNames.length() > 0) {
            nettoAmount = preccessTaxes(
                from,
                nettoAmount,
                toTaxNames,
                ITokenTaxes.TaxType.Sell
            );

            if (s.distributeOnSell) {
                distributeCollectedTaxes();
            }
        } else {
            distributeCollectedTaxes();
        }
    }

    /**
     * @dev Processes specific list of `taxNames` of type `taxType` and applies them to `bruttoAmount`.
     * The taxes are paid by `from`.
     *
     * @param from Tax payer.
     * @param bruttoAmount The taxed amount.
     * @param taxNames List of tax names that should be applied.
     * @param taxType The type of the aplied tax.
     *
     * @return nettoAmount The amount after applied taxes.
     */
    function preccessTaxes(
        address from,
        uint256 bruttoAmount,
        EnumerableSet.Bytes32Set storage taxNames,
        ITokenTaxes.TaxType taxType
    ) internal returns (uint256 nettoAmount) {
        Storage storage s = _storage();

        nettoAmount = bruttoAmount;

        uint256 length = taxNames.length();

        for (uint256 index = 0; index < length; ) {
            ITokenTaxes.Tax memory tax = getTax(taxNames.at(index));

            uint256 taxAmount = getTaxAmount(bruttoAmount, tax, taxType);

            if (taxAmount == 0) {
                unchecked {
                    ++index;
                }
                continue;
            }

            nettoAmount -= taxAmount;

            s.collectedTaxes[
                keccak256(abi.encodePacked(tax.name))
            ] += taxAmount;

            // solhint-disable-next-line multiple-sends, check-send-result
            LibSoloToken.send(from, address(this), taxAmount, "", "", false);

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev Calculates the `taxAmount` from the `bruttoAmount` for provided `tax`of type `taxType`.
     *
     * @param bruttoAmount The taxed amount.
     * @param tax The struct of the tax.
     * @param taxType The type of the tax.
     *
     * @return taxAmount The calculated amount of tax to take from the user.
     */
    function getTaxAmount(
        uint256 bruttoAmount,
        ITokenTaxes.Tax memory tax,
        ITokenTaxes.TaxType taxType
    ) internal pure returns (uint256 taxAmount) {
        if (taxType == ITokenTaxes.TaxType.Buy && tax.buy > 0) {
            taxAmount = (bruttoAmount * tax.buy) / 10000;
        } else if (taxType == ITokenTaxes.TaxType.Sell && tax.sell > 0) {
            taxAmount = (bruttoAmount * tax.sell) / 10000;
        }
    }

    /**
     * @dev Distributes previously collected taxes.
     * If `distributionPeriod` is configured, will ensure it's time to distribute.
     */
    function distributeCollectedTaxes() internal {
        Storage storage s = _storage();

        if (
            s.distributionPeriod > 0 &&
            // solhint-disable-next-line not-rely-on-time
            s.distributedAt + s.distributionPeriod >= block.timestamp
        ) {
            return;
        }

        bytes32[] memory taxNames = s.taxNames;

        for (uint256 index = 0; index < taxNames.length; ) {
            distributeCollectedTax(taxNames[index], getTax(taxNames[index]));

            unchecked {
                ++index;
            }
        }

        // solhint-disable not-rely-on-time
        // slither-disable-next-line weak-prng
        s.distributedAt = uint32(block.timestamp % 2**32);
        // solhint-enable
    }

    /**
     * @dev Distributes collected taxes for `taxName`.
     *
     * @param taxName Name of the tax.
     * @param tax Struct with the tax.
     */
    function distributeCollectedTax(bytes32 taxName, ITokenTaxes.Tax memory tax)
        internal
    {
        Storage storage s = _storage();

        uint256 taxAmount = s.collectedTaxes[taxName];

        if (taxAmount == 0) {
            return;
        }

        s.collectedTaxes[taxName] = 0;

        LibTokenDistributor.distribute(
            tax.tokenDitributorStrategyId,
            address(this),
            taxAmount
        );
    }

    /**
     * @dev Returns the current enabled state.
     */
    function isEnabled() internal view returns (bool enabled) {
        enabled = _storage().enabled;
    }

    /**
     * @dev Enables the token-taxes module.
     * Emits an {TokenTaxesEnabled} event.
     */
    function enable() internal {
        _storage().enabled = true;

        emit TokenTaxesEnabled();
    }

    /**
     * @dev Disables the token-taxes module
     * Emits an {TokenTaxesDisabled} event.
     */
    function disable() internal {
        _storage().enabled = false;

        emit TokenTaxesDisabled();
    }

    /**
     * @dev Adds a new token Tax.
     * Emits an {TokenTaxAdded} event.
     *
     * @param tax The Tax to be added.
     */
    function addTax(ITokenTaxes.Tax memory tax) internal {
        Storage storage s = _storage();

        bytes32 taxName = keccak256(abi.encodePacked(tax.name));

        if (
            keccak256(abi.encodePacked(s.taxes[taxName].name)) !=
            keccak256(abi.encodePacked(""))
        ) {
            revert ITokenTaxes.TokenTaxAlreadyExists(taxName);
        }

        s.taxes[taxName] = tax;
        s.taxNames.push(taxName);

        emit TokenTaxSet(tax.name);
    }

    /**
     * @dev Update a token Tax.
     * Emits an {TokenTaxUpdated} event.
     *
     * @param tax The Tax to be updated.
     */
    function updateTax(ITokenTaxes.Tax memory tax) internal {
        Storage storage s = _storage();

        bytes32 taxName = keccak256(abi.encodePacked(tax.name));

        if (
            keccak256(abi.encodePacked(s.taxes[taxName].name)) ==
            keccak256(abi.encodePacked(""))
        ) {
            revert ITokenTaxes.TokenTaxNotFound(taxName);
        }

        s.taxes[taxName] = tax;

        emit TokenTaxSet(tax.name);
    }

    /**
     * @dev Returns a tax by it's string name.
     *
     * @dev name Tax name as a string.
     *
     * @return tax The found tax.
     */
    function getTax(string memory name)
        internal
        view
        returns (ITokenTaxes.Tax memory tax)
    {
        tax = _storage().taxes[keccak256(abi.encodePacked(name))];
    }

    /**
     * @dev Returns a tax by it's bytes32 name.
     *
     * @dev name Tax name as bytes32.
     *
     * @return tax The found tax.
     */
    function getTax(bytes32 name)
        internal
        view
        returns (ITokenTaxes.Tax memory tax)
    {
        tax = _storage().taxes[name];
    }

    /**
     * @dev Adds `taxName` to `taxedAddress`.
     * Emits an {TokenTaxAddedToAddress} event.
     *
     * @param taxedAddress The taxed address.
     * @param taxName Bytes32 name of the tax.
     */
    function addAddressTax(address taxedAddress, bytes32 taxName) internal {
        // slither-disable-next-line unused-return
        _storage().addressTaxes[taxedAddress].add(taxName);

        emit TokenTaxAddedToAddress(taxedAddress, taxName);
    }

    /**
     * @dev Removes `taxName` from `taxedAddress`.
     * Emits an {TokenTaxRemovedFromAddress} event.
     *
     * @param taxedAddress The taxed address.
     * @param taxName Bytes32 name of the tax.
     */
    function removeAddressTax(address taxedAddress, bytes32 taxName) internal {
        // slither-disable-next-line unused-return
        _storage().addressTaxes[taxedAddress].remove(taxName);

        emit TokenTaxRemovedFromAddress(taxedAddress, taxName);
    }

    /**
     * @dev Returns the `taxNames` stored for `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     *
     * @return taxNames Array with tax names stored for `taxedAddress`.
     */
    function getAddressTaxNames(address taxedAddress)
        internal
        view
        returns (bytes32[] memory taxNames)
    {
        taxNames = _storage().addressTaxes[taxedAddress].values();
    }

    /**
     * @dev Checks if `taxName` (string) is assigned to `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     * @param taxName String name of the tax.
     */
    function doesAddressHaveTax(address taxedAddress, string memory taxName)
        internal
        view
        returns (bool)
    {
        return
            doesAddressHaveTax(
                taxedAddress,
                keccak256(abi.encodePacked(taxName))
            );
    }

    /**
     * @dev Checks if `taxName` (bytes32) is assigned to `taxedAddress`.
     *
     * @param taxedAddress The taxed address.
     * @param taxName Bytes32 name of the tax.
     */
    function doesAddressHaveTax(address taxedAddress, bytes32 taxName)
        internal
        view
        returns (bool)
    {
        return _storage().addressTaxes[taxedAddress].contains(taxName);
    }

    /**
     * @dev Sets the `account`'s exempt from tax status to `flag`.
     * Emits an {TokenTaxSetExemptFlag} event.
     *
     * @param account The account to set the `flag` for.
     * @param flag The status flag.
     */
    function setExemptFromTaxes(address account, bool flag) internal {
        _storage().exemptFromTaxes[account] = flag;

        emit TokenTaxSetExemptFlag(account, flag);
    }

    /**
     * @dev Checks if `account` is exempt from taxes.
     *
     * @return True if `account` is exempt from taxes.
     */
    function isExemptFromTaxes(address account) internal view returns (bool) {
        return account == address(this) || _storage().exemptFromTaxes[account];
    }

    /**
     * @dev Sets the `distributionPeriod`.
     *
     * @param distributionPeriod The period to set.
     */
    function setDistributionPeriod(uint32 distributionPeriod) internal {
        _storage().distributionPeriod = distributionPeriod;
    }

    /**
     * @dev Returns the `distributionPeriod`.
     *
     * @return distributionPeriod The configured period.
     */
    function getDistributionPeriod() internal view returns (uint32) {
        return _storage().distributionPeriod;
    }

    /**
     * @dev Returns the timestamp of the last token tax distribution.
     *
     * @return distributedAt The timestamp of the last tax distribution.
     */
    function getDistributedAt() internal view returns (uint32) {
        return _storage().distributedAt;
    }

    /**
     * @dev Sets the `distributeOnSell`.
     */
    function setDistributeOnSell(bool distributeOnSell) internal {
        _storage().distributeOnSell = distributeOnSell;
    }

    /**
     * @dev Sets the `distributeOnSell`.
     */
    function getDistributeOnSell()
        internal
        view
        returns (bool distributeOnSell)
    {
        distributeOnSell = _storage().distributeOnSell;
    }

    /**
     * @dev Returns an info response. Mainly for testing and debuggind.
     *
     * @return taxesInfoResponse An instance of the ITokenTaxes.TaxesInfoResponse struct, with data from the storage.
     */
    function getTaxesInfoResponse()
        internal
        view
        returns (ITokenTaxes.TaxesInfoResponse memory)
    {
        Storage storage s = _storage();

        return
            ITokenTaxes.TaxesInfoResponse({
                enabled: s.enabled,
                distributeOnSell: s.distributeOnSell,
                distributedAt: s.distributedAt,
                distributionPeriod: s.distributionPeriod,
                taxNames: s.taxNames
            });
    }
}
