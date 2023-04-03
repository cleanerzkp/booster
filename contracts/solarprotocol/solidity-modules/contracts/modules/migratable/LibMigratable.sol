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

import {IMigratable} from "./IMigratable.sol";
import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

library LibMigratable {
    using Address for address;

    struct Storage {
        mapping(uint256 => IMigratable.Migration) migrations;
        mapping(string => bool) migrationNames;
        uint256[] migrationIds;
        uint256[] executedMigrationIds;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("solarprotocol.contracts.migrate.LibMigrate");

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

    event MigrationAdded(uint256 id, string name);
    event MigrationExecuted(uint256 id, string name);

    /**
     * @dev Adds a new struct migration to the migrations list.
     */
    function add(IMigratable.Migration memory migration) internal {
        if (_storage().migrationNames[migration.name]) {
            revert IMigratable.MigrationAlreadyAdded(migration.name);
        }

        LibDiamond.enforceHasContractCode(
            migration.contractAddress,
            "LibDiamondCut: _init address has no code"
        );

        uint256 id = _storage().migrationIds.length + 1;
        _storage().migrations[id] = migration;
        _storage().migrationIds.push(id);

        _storage().migrationNames[migration.name] = true;

        emit MigrationAdded(id, migration.name);
    }

    /**
     * @dev Returns the migrartion with `id`.
     */
    function getMigration(uint256 id)
        internal
        view
        returns (IMigratable.Migration memory)
    {
        return _storage().migrations[id];
    }

    /**
     * @dev Returns the length of the migration ids array.
     */
    function getLength() internal view returns (uint256) {
        return _storage().migrationIds.length;
    }

    /**
     * @dev Returns the length of the array with the ids of already executed migrations.
     */
    function getExecutedLength() internal view returns (uint256) {
        return _storage().executedMigrationIds.length;
    }

    /**
     * @dev Returns the array with all migration ids.
     */
    function getMigrationIds() internal view returns (uint256[] memory) {
        return _storage().migrationIds;
    }

    /**
     * @dev Returns the array with the ids of all executed migrations.
     */
    function getExecutedIds() internal view returns (uint256[] memory) {
        return _storage().executedMigrationIds;
    }

    /**
     * @dev Returns the id of the next migration to be executed.
     * If all migrations are already executed, will return 0.
     */
    function getNextMigrationId() internal view returns (uint256) {
        uint256 length = _storage().migrationIds.length;
        uint256 executed = _storage().executedMigrationIds.length;

        if (executed < length) {
            return length++;
        }

        return 0;
    }

    /**
     * @dev Returns an array with pending migration ids.
     */
    function getPendingMigrations()
        internal
        view
        returns (uint256[] memory ids)
    {
        Storage storage s = _storage();

        for (
            uint256 index = s.executedMigrationIds.length;
            index <= s.migrationIds.length;
            ++index
        ) {
            ids[ids.length] = index;
        }
    }

    /**
     * @dev Runs the next migration.
     */
    function runNextMigration() internal {
        runMigration(getNextMigrationId());
    }

    /**
     * @dev Runs all pending migrations.
     */
    function runPendingMigrations() internal {
        Storage storage s = _storage();

        for (
            uint256 index = s.executedMigrationIds.length + 1;
            index <= s.migrationIds.length;
            ++index
        ) {
            runMigration(index);
        }
    }

    /**
     * @dev Runs a migration by id.
     */
    function runMigration(uint256 id) internal {
        IMigratable.Migration memory migration = _storage().migrations[id];

        if (_storage().executedMigrationIds.length >= id) {
            revert IMigratable.MigrationAlreadyExecuted(id, migration.name);
        }

        bytes memory data = migration.data;
        if (data.length == 0) {
            data = abi.encodeWithSignature("migrate()");
        }

        // slither-disable-next-line unused-return
        migration.contractAddress.functionDelegateCall(data);

        _storage().executedMigrationIds.push(id);

        emit MigrationExecuted(id, migration.name);
    }
}
