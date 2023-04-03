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

import {LibSoloToken} from "../../solo-token/LibSoloToken.sol";

// solhint-disable-next-line contract-name-camelcase
contract TestSetupSoloTokenMigration {
    function migrate(
        address account1,
        address account2,
        address account3,
        address account4
    ) external {
        require(account1 != address(0), "account1 is zero address");
        require(account2 != address(0), "account2 is zero address");
        require(account3 != address(0), "account3 is zero address");
        require(account4 != address(0), "account4 is zero address");

        address[] memory defaultOperators = new address[](1);
        defaultOperators[0] = address(this);

        LibSoloToken.init("TestToken", "tTKN", defaultOperators, true);

        LibSoloToken.mint(account1, 1e5 * 1e18, "", "", false);
        LibSoloToken.mint(account2, 2e5 * 1e18, "", "", false);
        LibSoloToken.mint(account3, 3e5 * 1e18, "", "", false);
        LibSoloToken.mint(account4, 4e5 * 1e18, "", "", false);

        require(
            LibSoloToken.totalSupply() == 1e6 * 1e18,
            "TotalSupply doesn't match"
        );
    }
}
