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

import {IMasterChef} from "./interfaces/IMasterChef.sol";
import {IERC20Mintable} from "./interfaces/IERC20Mintable.sol";
import {Initializer} from "@solarprotocol/solidity-modules/contracts/modules/utils/initializer/Initializer.sol";
import {ReentrancyGuard} from "@solarprotocol/solidity-modules/contracts/modules/security/reentrancy-guard/ReentrancyGuard.sol";
import {PausableFacet, LibPausable} from "@solarprotocol/solidity-modules/contracts/modules/pausable/PausableFacet.sol";
import {SimpleBlacklistFacet, LibSimpleBlacklist} from "@solarprotocol/solidity-modules/contracts/modules/blacklist/SimpleBlacklistFacet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MasterChef is IMasterChef, Initializer, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Mintable;

    IERC20Mintable public kswap;

    // Dev address.
    address public treasury;

    /// @notice The only address can withdraw all the burn KSWAP.
    address public burnAdmin;
    /// @notice The contract handles the share boosts.
    address public boostContract;

    /// @notice Info of each MCV2 pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each MCV2 pool.
    IERC20[] public lpToken;

    /// @notice Info of each pool user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @notice The whitelist of addresses allowed to deposit in special pools.
    mapping(address => bool) public whiteList;

    /// @notice Total regular allocation points. Must be the sum of all regular pools' allocation points.
    uint256 public totalRegularAllocPoint;
    /// @notice Total special allocation points. Must be the sum of all special pools' allocation points.
    uint256 public totalSpecialAllocPoint;
    ///  @notice 40 KSWAP per block in MC
    uint256 public constant MASTERCHEF_KSWAP_PER_BLOCK = 40 * 1e18;
    uint256 public constant ACC_KSWAP_PRECISION = 1e18;

    /// @notice Basic boost factor, none boosted user's boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;
    /// @notice Hard limit for maxmium boost factor, it must greater than BOOST_PRECISION
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;
    /// @notice total kswap rate = toBurn + toRegular + toSpecial
    uint256 public constant KSWAP_RATE_TOTAL_PRECISION = 1e12;
    /// @notice The last block number of KSWAP burn action being executed.
    /// @notice KSWAP distribute % for burn
    uint256 public kswapRateToBurn = 989202815829;
    /// @notice KSWAP distribute % for regular farm pool
    uint256 public kswapRateToRegularFarm = 10797184170;
    /// @notice KSWAP distribute % for special pools
    uint256 public kswapRateToSpecialFarm = 1;

    uint256 public lastBurnedBlock;

    /// @notice Returns the number of MC pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /**
     * @notice Add a new pool. Can only be called by the owner.
     * DO NOT add the same LP token more than once. Rewards will be messed up if you do.
     * @param _allocPoint Number of allocation points for the new pool.
     * @param _lpToken Address of the LP BEP-20 token.
     * @param _isRegular Whether the pool is regular or special. LP farms are always "regular". "Special" pools are
     * @param _withUpdate Whether call "massUpdatePools" operation.
     * only for KSWAP distributions within Kyoto Swap products.
     */
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _isRegular,
        uint256 _startBlockNumber,
        bool _withUpdate
    ) external onlyOwner {
        _add(_allocPoint, _lpToken, _isRegular, _startBlockNumber, _withUpdate);
    }

    /// @notice Update the given pool's KSWAP allocation point. Can only be called by the owner.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _allocPoint New number of allocation points for the pool.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        // No matter _withUpdate is true or false, we need to execute updatePool once before set the pool parameters.
        updatePool(_pid);

        if (_withUpdate) {
            massUpdatePools();
        }

        if (poolInfo[_pid].isRegular) {
            totalRegularAllocPoint = totalRegularAllocPoint
                .sub(poolInfo[_pid].allocPoint)
                .add(_allocPoint);
        } else {
            totalSpecialAllocPoint = totalSpecialAllocPoint
                .sub(poolInfo[_pid].allocPoint)
                .add(_allocPoint);
        }
        poolInfo[_pid].allocPoint = _allocPoint;
        emit SetPool(_pid, _allocPoint);
    }

    /// @notice View function for checking pending KSWAP rewards.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _user Address of the user.
    function pendingKswap(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accKswapPerShare = pool.accKswapPerShare;
        uint256 lpSupply = pool.totalBoostedShare;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);

            uint256 kswapReward = multiplier
                .mul(kswapPerBlock(pool.isRegular))
                .mul(pool.allocPoint)
                .div(
                    (
                        pool.isRegular
                            ? totalRegularAllocPoint
                            : totalSpecialAllocPoint
                    )
                );
            accKswapPerShare = accKswapPerShare.add(
                kswapReward.mul(ACC_KSWAP_PRECISION).div(lpSupply)
            );
        }

        uint256 boostedAmount = user
            .amount
            .mul(getBoostMultiplier(_user, _pid))
            .div(BOOST_PRECISION);
        return
            boostedAmount.mul(accKswapPerShare).div(ACC_KSWAP_PRECISION).sub(
                user.rewardDebt
            );
    }

    /// @notice Update kswap reward for all the active pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo memory pool = poolInfo[pid];
            if (pool.allocPoint != 0) {
                updatePool(pid);
            }
        }
    }

    /// @notice Calculates and returns the `amount` of KSWAP per block.
    /// @param _isRegular If the pool belongs to regular or special.
    function kswapPerBlock(
        bool _isRegular
    ) public view returns (uint256 amount) {
        if (_isRegular) {
            amount = MASTERCHEF_KSWAP_PER_BLOCK.mul(kswapRateToRegularFarm).div(
                KSWAP_RATE_TOTAL_PRECISION
            );
        } else {
            amount = MASTERCHEF_KSWAP_PER_BLOCK.mul(kswapRateToSpecialFarm).div(
                KSWAP_RATE_TOTAL_PRECISION
            );
        }
    }

    /// @notice Calculates and returns the `amount` of KSWAP per block to burn.
    function kswapPerBlockToBurn() public view returns (uint256 amount) {
        amount = MASTERCHEF_KSWAP_PER_BLOCK.mul(kswapRateToBurn).div(
            KSWAP_RATE_TOTAL_PRECISION
        );
    }

    /// @notice Update reward variables for the given pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 _pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[_pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = pool.totalBoostedShare;
            uint256 totalAllocPoint = (
                pool.isRegular ? totalRegularAllocPoint : totalSpecialAllocPoint
            );

            if (lpSupply > 0 && totalAllocPoint > 0) {
                uint256 multiplier = block.number.sub(pool.lastRewardBlock);
                uint256 kswapReward = multiplier
                    .mul(kswapPerBlock(pool.isRegular))
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);
                pool.accKswapPerShare = pool.accKswapPerShare.add(
                    (kswapReward.mul(ACC_KSWAP_PRECISION).div(lpSupply))
                );
                kswap.mint(treasury, kswapReward.div(10));
                kswap.mint(address(this), kswapReward);
            }
            pool.lastRewardBlock = block.number;
            poolInfo[_pid] = pool;
            emit UpdatePool(
                _pid,
                pool.lastRewardBlock,
                lpSupply,
                pool.accKswapPerShare
            );
        }
    }

    /// @notice Deposit LP tokens to pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _amount Amount of LP tokens to deposit.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted(msg.sender);

        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        // solhint-disable-next-line reason-string
        require(
            pool.isRegular || whiteList[msg.sender],
            "MasterChef: The address is not available to deposit in this pool"
        );

        uint256 multiplier = getBoostMultiplier(msg.sender, _pid);

        if (user.amount > 0) {
            settlePendingKswap(msg.sender, _pid, multiplier);
        }

        if (_amount > 0) {
            uint256 before = lpToken[_pid].balanceOf(address(this));
            lpToken[_pid].safeTransferFrom(msg.sender, address(this), _amount);
            _amount = lpToken[_pid].balanceOf(address(this)).sub(before);
            user.amount = user.amount.add(_amount);

            // Update total boosted share.
            pool.totalBoostedShare = pool.totalBoostedShare.add(
                _amount.mul(multiplier).div(BOOST_PRECISION)
            );
        }

        user.rewardDebt = user
            .amount
            .mul(multiplier)
            .div(BOOST_PRECISION)
            .mul(pool.accKswapPerShare)
            .div(ACC_KSWAP_PRECISION);
        poolInfo[_pid] = pool;

        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw LP tokens from pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _amount Amount of LP tokens to withdraw.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted(msg.sender);

        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: Insufficient");

        uint256 multiplier = getBoostMultiplier(msg.sender, _pid);

        settlePendingKswap(msg.sender, _pid, multiplier);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            lpToken[_pid].safeTransfer(msg.sender, _amount);
        }

        user.rewardDebt = user
            .amount
            .mul(multiplier)
            .div(BOOST_PRECISION)
            .mul(pool.accKswapPerShare)
            .div(ACC_KSWAP_PRECISION);
        poolInfo[_pid].totalBoostedShare = poolInfo[_pid].totalBoostedShare.sub(
            _amount.mul(multiplier).div(BOOST_PRECISION)
        );

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw without caring about the rewards. EMERGENCY ONLY.
    /// @param _pid The id of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        LibPausable.enforceNotPaused();
        LibSimpleBlacklist.enforceNotBlacklisted(msg.sender);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        uint256 boostedAmount = amount
            .mul(getBoostMultiplier(msg.sender, _pid))
            .div(BOOST_PRECISION);
        pool.totalBoostedShare = pool.totalBoostedShare > boostedAmount
            ? pool.totalBoostedShare.sub(boostedAmount)
            : 0;

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[_pid].safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice Send KSWAP pending for burn to `burnAdmin`.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function burnKswap(bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 multiplier = block.number.sub(lastBurnedBlock);
        uint256 pendingKswapToBurn = multiplier.mul(kswapPerBlockToBurn());

        // SafeTransfer KSWAP
        _safeTransfer(burnAdmin, pendingKswapToBurn);
        lastBurnedBlock = block.number;
    }

    /// @notice Update the % of KSWAP distributions for burn, regular pools and special pools.
    /// @param _burnRate The % of KSWAP to burn each block.
    /// @param _regularFarmRate The % of KSWAP to regular pools each block.
    /// @param _specialFarmRate The % of KSWAP to special pools each block.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function updateKswapRate(
        uint256 _burnRate,
        uint256 _regularFarmRate,
        uint256 _specialFarmRate,
        bool _withUpdate
    ) external onlyOwner {
        // solhint-disable-next-line reason-string
        require(
            _burnRate > 0 && _regularFarmRate > 0 && _specialFarmRate > 0,
            "MasterChef: Kswap rate must be greater than 0"
        );
        // solhint-disable-next-line reason-string
        require(
            _burnRate.add(_regularFarmRate).add(_specialFarmRate) ==
                KSWAP_RATE_TOTAL_PRECISION,
            "MasterChef: Total rate must be 1e12"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        // burn kswap base on old burn kswap rate
        burnKswap(false);

        kswapRateToBurn = _burnRate;
        kswapRateToRegularFarm = _regularFarmRate;
        kswapRateToSpecialFarm = _specialFarmRate;

        emit UpdateCakeRate(_burnRate, _regularFarmRate, _specialFarmRate);
    }

    /// @notice Update burn admin address.
    /// @param _newAdmin The new burn admin address.
    function updateBurnAdmin(address _newAdmin) external onlyOwner {
        // solhint-disable-next-line reason-string
        require(
            _newAdmin != address(0),
            "MasterChef: Burn admin address must be valid"
        );
        // solhint-disable-next-line reason-string
        require(
            _newAdmin != burnAdmin,
            "MasterChef: Burn admin address is the same with current address"
        );
        address _oldAdmin = burnAdmin;
        burnAdmin = _newAdmin;
        emit UpdateBurnAdmin(_oldAdmin, _newAdmin);
    }

    /// @notice Update whitelisted addresses for special pools.
    /// @param _user The address to be updated.
    /// @param _isValid The flag for valid or invalid.
    function updateWhiteList(address _user, bool _isValid) external onlyOwner {
        // solhint-disable-next-line reason-string
        require(
            _user != address(0),
            "MasterChef: The white list address must be valid"
        );

        whiteList[_user] = _isValid;
        emit UpdateWhiteList(_user, _isValid);
    }

    /// @notice Update boost contract address and max boost factor.
    /// @param _newBoostContract The new address for handling all the share boosts.
    function updateBoostContract(address _newBoostContract) external onlyOwner {
        // solhint-disable-next-line reason-string
        require(
            _newBoostContract != address(0) &&
                _newBoostContract != boostContract,
            "MasterChef: New boost contract address must be valid"
        );

        boostContract = _newBoostContract;
        emit UpdateBoostContract(_newBoostContract);
    }

    /// @notice Update user boost factor.
    /// @param _user The user address for boost factor updates.
    /// @param _pid The pool id for the boost factor updates.
    /// @param _newMultiplier New boost multiplier.
    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newMultiplier
    ) external nonReentrant {
        // solhint-disable-next-line reason-string
        require(
            boostContract == msg.sender,
            "Ownable: caller is not the boost contract"
        );
        // solhint-disable-next-line reason-string
        require(
            _user != address(0),
            "MasterChef: The user address must be valid"
        );
        // solhint-disable-next-line reason-string
        require(
            poolInfo[_pid].isRegular,
            "MasterChef: Only regular farm could be boosted"
        );
        // solhint-disable-next-line reason-string
        require(
            _newMultiplier >= BOOST_PRECISION &&
                _newMultiplier <= MAX_BOOST_PRECISION,
            "MasterChef: Invalid new boost multiplier"
        );

        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_user];

        uint256 prevMultiplier = getBoostMultiplier(_user, _pid);
        settlePendingKswap(_user, _pid, prevMultiplier);

        user.rewardDebt = user
            .amount
            .mul(_newMultiplier)
            .div(BOOST_PRECISION)
            .mul(pool.accKswapPerShare)
            .div(ACC_KSWAP_PRECISION);
        pool.totalBoostedShare = pool
            .totalBoostedShare
            .sub(user.amount.mul(prevMultiplier).div(BOOST_PRECISION))
            .add(user.amount.mul(_newMultiplier).div(BOOST_PRECISION));
        poolInfo[_pid] = pool;
        userInfo[_pid][_user].boostMultiplier = _newMultiplier;

        emit UpdateBoostMultiplier(_user, _pid, prevMultiplier, _newMultiplier);
    }

    /// @notice Get user boost multiplier for specific pool id.
    /// @param _user The user address.
    /// @param _pid The pool id.
    function getBoostMultiplier(
        address _user,
        uint256 _pid
    ) public view returns (uint256) {
        uint256 multiplier = userInfo[_pid][_user].boostMultiplier;
        return multiplier > BOOST_PRECISION ? multiplier : BOOST_PRECISION;
    }

    /// @notice Settles, distribute the pending KSWAP rewards for given user.
    /// @param _user The user address for settling rewards.
    /// @param _pid The pool id.
    /// @param _boostMultiplier The user boost multiplier in specific pool id.
    function settlePendingKswap(
        address _user,
        uint256 _pid,
        uint256 _boostMultiplier
    ) internal {
        UserInfo memory user = userInfo[_pid][_user];

        uint256 boostedAmount = user.amount.mul(_boostMultiplier).div(
            BOOST_PRECISION
        );
        uint256 accKswap = boostedAmount
            .mul(poolInfo[_pid].accKswapPerShare)
            .div(ACC_KSWAP_PRECISION);
        uint256 pending = accKswap.sub(user.rewardDebt);
        // SafeTransfer KSWAP
        _safeTransfer(_user, pending);
    }

    function setTreasuryAddress(address _treasury) external {
        require(msg.sender == treasury, "dev: wut?");
        treasury = _treasury;
        emit SetTreasuryAddress(msg.sender, _treasury);
    }

    function setPoolLastRewardBlock(
        uint256 _pid,
        uint256 newLastRewardBlock
    ) public onlyOwner {
        uint256 oldLastRewardBlock = poolInfo[_pid].lastRewardBlock;
        require(
            oldLastRewardBlock > block.number &&
                newLastRewardBlock >= block.number,
            "Can't modify history"
        );
        poolInfo[_pid].lastRewardBlock = newLastRewardBlock;
    }

    function setPoolLastRewardBlock(
        uint256[] memory _pids,
        uint256 newLastRewardBlock
    ) public onlyOwner {
        if (newLastRewardBlock == 0) {
            newLastRewardBlock = block.number + 200;
        }

        for (uint256 index = 0; index < _pids.length; ++index) {
            setPoolLastRewardBlock(_pids[index], newLastRewardBlock);
        }
    }

    function initialize(
        IERC20Mintable kswap_,
        address treasury_,
        address burnAdmin_,
        AddNewPoolInfo[] calldata newPools
    ) external initializer {
        kswap = kswap_;
        treasury = treasury_;
        burnAdmin = burnAdmin_;

        uint256 index = 0;
        uint256 newPoolsLength = newPools.length;

        while (index < newPoolsLength) {
            _add(
                newPools[index].allocPoint,
                newPools[index].lpToken,
                newPools[index].isRegular,
                newPools[index].startBlockNumber,
                false
            );

            unchecked {
                ++index;
            }
        }

        LibPausable.unpause();
    }

    /**
     * @notice Add a new pool. Can only be called by the owner.
     * DO NOT add the same LP token more than once. Rewards will be messed up if you do.
     * @param _allocPoint Number of allocation points for the new pool.
     * @param _lpToken Address of the LP BEP-20 token.
     * @param _isRegular Whether the pool is regular or special. LP farms are always "regular". "Special" pools are
     * @param _withUpdate Whether call "massUpdatePools" operation.
     * only for KSWAP distributions within Kyoto Swap products.
     */
    function _add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _isRegular,
        uint256 _startBlockNumber,
        bool _withUpdate
    ) internal {
        require(_lpToken.balanceOf(address(this)) >= 0, "None BEP20 tokens");
        // stake KSWAP token will cause staked token and reward token mixed up,
        // may cause staked tokens withdraw as reward token,never do it.
        // solhint-disable-next-line reason-string
        require(_lpToken != kswap, "KSWAP token can't be added to farm pools");

        if (_withUpdate) {
            massUpdatePools();
        }

        if (_isRegular) {
            totalRegularAllocPoint = totalRegularAllocPoint.add(_allocPoint);
        } else {
            totalSpecialAllocPoint = totalSpecialAllocPoint.add(_allocPoint);
        }
        lpToken.push(_lpToken);

        poolInfo.push(
            PoolInfo({
                allocPoint: _allocPoint,
                lastRewardBlock: _startBlockNumber > block.number
                    ? _startBlockNumber
                    : (block.number + 200),
                accKswapPerShare: 0,
                isRegular: _isRegular,
                totalBoostedShare: 0
            })
        );
        emit AddPool(lpToken.length.sub(1), _allocPoint, _lpToken, _isRegular);
    }

    /// @notice Safe Transfer KSWAP.
    /// @param _to The KSWAP receiver address.
    /// @param _amount transfer KSWAP amounts.
    function _safeTransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            uint256 balance = kswap.balanceOf(address(this));
            if (balance < _amount) {
                _amount = balance;
            }
            kswap.safeTransfer(_to, _amount);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == _getOwner(), "NOT_AUTHORIZED");
        _;
    }

    function _getOwner() internal view returns (address ownerAddress) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ownerAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}
