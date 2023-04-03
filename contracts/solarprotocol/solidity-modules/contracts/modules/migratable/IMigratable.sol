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

interface IMigratable {
    struct Migration {
        string name;
        address contractAddress;
        bytes data;
    }

    error MigrationAlreadyAdded(string name);
    error MigrationAlreadyExecuted(uint256 id, string name);

    event MigrationAdded(uint256 id, string name);
    event MigrationExecuted(uint256 id, string name);

    /**
     * @dev Adds a new migration struct to the migrations list
     * and runs pending migrations if `runPending` is true.
     */
    function addMigration(Migration memory migration, bool runPending) external;

    /**
     * @dev Adds new migration structs to the migrations list
     * and runs pending migrations if `runPending` is true.
     */
    function addMigrations(Migration[] memory migration, bool runPending)
        external;

    /**
     * @dev Returns the migrartion with `id`.
     */
    function getMigration(uint256 id) external view returns (Migration memory);

    /**
     * @dev Returns the length of the migration ids array.
     */
    function getMigrationsLength() external view returns (uint256);

    /**
     * @dev Returns the length of the array with the ids of already executed migrations.
     */
    function getExecutedMigrationsLength() external view returns (uint256);

    /**
     * @dev Returns the array with all migration ids.
     */
    function getMigrationIds() external view returns (uint256[] memory);

    /**
     * @dev Returns the array with the ids of all executed migrations.
     */
    function getExecutedMigrationIds() external view returns (uint256[] memory);

    /**
     * @dev Returns the id of the next migration to be executed.
     * If all migrations are already executed, will return 0.
     */
    function getNextMigrationId() external view returns (uint256);

    /**
     * @dev Returns an array with pending migration ids.
     */
    function getPendingMigrations()
        external
        view
        returns (uint256[] memory ids);

    /**
     * @dev Runs the next migration.
     */
    function runNextMigration() external;

    /**
     * @dev Runs all pending migrations.
     */
    function runPendingMigrations() external;

    /**
     * @dev Runs a migration by id.
     */
    function runMigration(uint256 id) external;
}
