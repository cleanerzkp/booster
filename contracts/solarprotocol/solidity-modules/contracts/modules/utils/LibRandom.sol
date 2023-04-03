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

library LibRandom {
    function getLimitedRandomNumbers(uint256 quantity, uint256 limit)
        internal
        view
        returns (uint256[] memory randomNumbers)
    {
        randomNumbers = new uint256[](quantity);

        uint256 index = 0;
        while (index < quantity) {
            // slither-disable-next-line weak-prng
            randomNumbers[index] =
                getLimitedRandomNumber(
                    keccak256(abi.encodePacked(address(this), index)),
                    limit
                ) %
                limit;

            unchecked {
                ++index;
            }
        }
    }

    function getLimitedRandomNumber(uint256 limit)
        internal
        view
        returns (uint256)
    {
        // slither-disable-next-line weak-prng
        return getRandomNumber() % limit;
    }

    function getLimitedRandomNumber(bytes32 seed, uint256 limit)
        internal
        view
        returns (uint256)
    {
        // slither-disable-next-line weak-prng
        return getRandomNumber(seed) % limit;
    }

    function getRandomNumbers(uint256 quantity)
        internal
        view
        returns (uint256[] memory randomNumbers)
    {
        randomNumbers = new uint256[](quantity);

        uint256 index = 0;
        while (index < quantity) {
            randomNumbers[index] = getRandomNumber(
                keccak256(abi.encodePacked(address(this), index))
            );

            unchecked {
                ++index;
            }
        }
    }

    function getRandomNumber() internal view returns (uint256) {
        return getRandomNumber(keccak256(abi.encodePacked(address(this))));
    }

    function getRandomNumber(bytes32 seed) internal view returns (uint256) {
        return uint256(getEntropy(seed));
    }

    function getEntropy(bytes32 seed) internal view returns (bytes32 entropy) {
        entropy = keccak256(
            abi.encodePacked(
                // solhint-disable not-rely-on-time
                // slither-disable-next-line weak-prng
                block.timestamp,
                // solhint-enable
                block.number,
                blockhash(block.number - 1),
                block.difficulty,
                block.gaslimit,
                tx.gasprice,
                seed
            )
        );
    }
}
