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
import {LibMigratable} from "./LibMigratable.sol";
import {LibDiamond} from "contracts-starter/contracts/libraries/LibDiamond.sol";

contract MigratableFacet is IMigratable {
    /**
     * @dev Adds a new migration struct to the migrations list
     * and runs pending migrations if `runPending` is true.
     */
    function addMigration(Migration memory migration, bool runPending)
        external
    {
        LibDiamond.enforceIsContractOwner();

        LibMigratable.add(migration);

        if (runPending) {
            LibMigratable.runPendingMigrations();
        }
    }

    /**
     * @dev Adds new migration structs to the migrations list
     * and runs pending migrations if `runPending` is true.
     */
    function addMigrations(Migration[] memory migration, bool runPending)
        external
    {
        LibDiamond.enforceIsContractOwner();

        for (uint256 index = 0; index < migration.length; ++index) {
            LibMigratable.add(migration[index]);
        }

        if (runPending) {
            LibMigratable.runPendingMigrations();
        }
    }

    /**
     * @dev Returns the migrartion with `id`.
     */
    function getMigration(uint256 id) external view returns (Migration memory) {
        return LibMigratable.getMigration(id);
    }

    /**
     * @dev Returns the length of the migration ids array.
     */
    function getMigrationsLength() external view returns (uint256) {
        return LibMigratable.getLength();
    }

    /**
     * @dev Returns the length of the array with the ids of already executed migrations.
     */
    function getExecutedMigrationsLength() external view returns (uint256) {
        return LibMigratable.getExecutedLength();
    }

    /**
     * @dev Returns the array with all migration ids.
     */
    function getMigrationIds() external view returns (uint256[] memory) {
        return LibMigratable.getMigrationIds();
    }

    /**
     * @dev Returns the array with the ids of all executed migrations.
     */
    function getExecutedMigrationIds()
        external
        view
        returns (uint256[] memory)
    {
        return LibMigratable.getExecutedIds();
    }

    /**
     * @dev Returns the id of the next migration to be executed.
     * If all migrations are already executed, will return 0.
     */
    function getNextMigrationId() external view returns (uint256) {
        return LibMigratable.getNextMigrationId();
    }

    /**
     * @dev Returns an array with pending migration ids.
     */
    function getPendingMigrations()
        external
        view
        returns (uint256[] memory ids)
    {
        return LibMigratable.getPendingMigrations();
    }

    /**
     * @dev Runs the next migration.
     */
    function runNextMigration() external {
        LibDiamond.enforceIsContractOwner();

        LibMigratable.runNextMigration();
    }

    /**
     * @dev Runs all pending migrations.
     */
    function runPendingMigrations() external {
        LibDiamond.enforceIsContractOwner();

        LibMigratable.runPendingMigrations();
    }

    /**
     * @dev Runs a migration by id.
     */
    function runMigration(uint256 id) external {
        LibDiamond.enforceIsContractOwner();

        LibMigratable.runMigration(id);
    }
}
