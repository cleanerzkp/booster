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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChef {
    /**
     * @notice Info of each MC user.
     * `amount` LP token amount the user has provided.
     * `rewardDebt` Used to calculate the correct amount of rewards. See explanation below.
     *
     * We do some fancy math here. Basically, any point in time, the amount of KSWAP
     * entitled to a user but is pending to be distributed is:
     *
     *   pending reward = (user share * pool.accKswapPerShare) - user.rewardDebt
     *
     *   Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
     *   1. The pool's `accKswapPerShare` (and `lastRewardBlock`) gets updated.
     *   2. User receives the pending reward sent to his/her address.
     *   3. User's `amount` gets updated. Pool's `totalBoostedShare` gets updated.
     *   4. User's `rewardDebt` gets updated.
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 boostMultiplier;
    }

    /**
     * @notice Info of each MC pool.
     * `allocPoint` The amount of allocation points assigned to the pool.
     *     Also known as the amount of "multipliers". Combined with `totalXAllocPoint`, it defines the % of
     *     KSWAP rewards each pool gets.
     * `accKswapPerShare` Accumulated KSWAPs per share, times 1e12.
     * `lastRewardBlock` Last block number that pool update action is executed.
     * `isRegular` The flag to set pool is regular or special. See below:
     *     In MasterChef farms are "regular pools". "special pools", which use a different sets of
     *     `allocPoint` and their own `totalSpecialAllocPoint` are designed to handle the distribution of
     *     the KSWAP rewards to all the Kyoto Swap products.
     * `totalBoostedShare` The total amount of user shares in each pool. After considering the share boosts.
     */
    struct PoolInfo {
        uint256 accKswapPerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
        bool isRegular;
    }

    struct AddNewPoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 startBlockNumber;
        bool isRegular;
    }

    event AddPool(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken,
        bool isRegular
    );
    event SetPool(uint256 indexed pid, uint256 allocPoint);
    event UpdatePool(
        uint256 indexed pid,
        uint256 lastRewardBlock,
        uint256 lpSupply,
        uint256 accKswapPerShare
    );
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event UpdateCakeRate(
        uint256 burnRate,
        uint256 regularFarmRate,
        uint256 specialFarmRate
    );
    event UpdateBurnAdmin(address indexed oldAdmin, address indexed newAdmin);
    event UpdateWhiteList(address indexed user, bool isValid);
    event UpdateBoostContract(address indexed boostContract);
    event UpdateBoostMultiplier(
        address indexed user,
        uint256 pid,
        uint256 oldMultiplier,
        uint256 newMultiplier
    );
    event SetTreasuryAddress(address indexed user, address treasury);
}
