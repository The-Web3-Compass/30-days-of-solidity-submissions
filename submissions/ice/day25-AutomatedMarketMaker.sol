// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title AutomatedMarketMaker
 * @dev 自动做市商（AMM）合约实现
 * 
 * 核心机制：
 * 1. 数据结构：
 *    Pool {
 *      token0, token1    - 交易对代币地址
 *      reserve0, reserve1 - 代币储备量
 *      totalSupply       - LP代币总量
 *      balances         - LP代币余额映射
 *    }
 * 
 * 2. 关键公式：
 *    - 常数乘积: reserve0 * reserve1 = k
 *    - 交易计算: (x + Δx * 0.997) * (y - Δy) = x * y
 *    - 手续费率: 0.3%
 * 
 * 3. 安全措施：
 *    - ReentrancyGuard: 防重入
 *    - SafeERC20: 安全转账
 *    - 最小流动性锁定: 防止池子清空
 */
contract AutomatedMarketMaker is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // 常量
    uint256 public constant MINIMUM_LIQUIDITY = 1000; // 最小流动性代币数量
    uint256 public constant FEE_DENOMINATOR = 1000;   // 费用分母
    uint256 public constant SWAP_FEE = 3;             // 交易费率 0.3%

    // 流动性池结构体
    struct Pool {
        address token0;           // 代币0地址
        address token1;           // 代币1地址
        uint256 reserve0;         // 代币0储备量
        uint256 reserve1;         // 代币1储备量
        uint256 totalSupply;      // LP代币总供应量
        mapping(address => uint256) balances; // LP代币余额映射
    }

    // 状态变量
    mapping(bytes32 => Pool) public pools;     // 池子映射
    mapping(address => mapping(address => bytes32)) public getPoolId;  // 代币对到池子ID的映射

    // 事件
    event PoolCreated(bytes32 indexed poolId, address indexed token0, address indexed token1);
    event LiquidityAdded(
        bytes32 indexed poolId,
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    event LiquidityRemoved(
        bytes32 indexed poolId,
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    event Swap(
        bytes32 indexed poolId,
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev 创建新的流动性池
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @return poolId 池子唯一标识符
     * 
     * 注意：
     * - 代币地址按大小排序确保唯一性
     * - 生成的poolId用于后续操作
     */
    function createPool(address tokenA, address tokenB) external returns (bytes32 poolId) {
        require(tokenA != tokenB, "Identical addresses");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");
        require(getPoolId[tokenA][tokenB] == bytes32(0), "Pool exists");

        // 确保代币地址排序，保证池子ID的唯一性
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // 生成池子ID
        poolId = keccak256(abi.encodePacked(token0, token1));
        
        // 创建新池子
        Pool storage pool = pools[poolId];
        pool.token0 = token0;
        pool.token1 = token1;

        // 更新映射
        getPoolId[token0][token1] = poolId;
        getPoolId[token1][token0] = poolId;

        emit PoolCreated(poolId, token0, token1);
    }

    /**
     * @dev 添加流动性
     * @param poolId 池子ID
     * @param amount0Desired token0期望数量
     * @param amount1Desired token1期望数量
     * @param amount0Min token0最小数量
     * @param amount1Min token1最小数量
     * @param to 接收LP代币的地址
     * @return liquidity 铸造的LP代币数量
     * 
     * 注意：
     * - 首次添加：接受用户定价，锁定最小流动性
     * - 后续添加：必须按当前比例，计算最优数量
     */
    function addLiquidity(
        bytes32 poolId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant returns (uint256 liquidity) {
        Pool storage pool = pools[poolId];
        require(pool.token0 != address(0), "Pool does not exist");

        uint256 amount0;
        uint256 amount1;

        // 计算实际添加的代币数量
        if (pool.reserve0 == 0 && pool.reserve1 == 0) {
            // 首次添加流动性
            amount0 = amount0Desired;
            amount1 = amount1Desired;
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY, poolId); // 永久锁定最小流动性
        } else {
            // 根据当前比例计算添加数量
            uint256 amount1Optimal = (amount0Desired * pool.reserve1) / pool.reserve0;
            if (amount1Optimal <= amount1Desired) {
                require(amount1Optimal >= amount1Min, "Insufficient amount1");
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                uint256 amount0Optimal = (amount1Desired * pool.reserve0) / pool.reserve1;
                require(amount0Optimal <= amount0Desired, "Excessive amount0");
                require(amount0Optimal >= amount0Min, "Insufficient amount0");
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }

            // 计算流动性代币数量
            liquidity = Math.min(
                (amount0 * pool.totalSupply) / pool.reserve0,
                (amount1 * pool.totalSupply) / pool.reserve1
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        // 转入代币
        IERC20(pool.token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(pool.token1).safeTransferFrom(msg.sender, address(this), amount1);

        // 更新储备量
        pool.reserve0 += amount0;
        pool.reserve1 += amount1;

        // 铸造LP代币
        _mint(to, liquidity, poolId);

        emit LiquidityAdded(poolId, to, amount0, amount1, liquidity);
    }

    /**
     * @dev 内部函数：铸造LP代币
     */
    function _mint(address to, uint256 amount, bytes32 poolId) internal {
        Pool storage pool = pools[poolId];
        pool.balances[to] += amount;
        pool.totalSupply += amount;
    }

    /**
     * @dev 内部函数：销毁LP代币
     */
    function _burn(address from, uint256 amount, bytes32 poolId) internal {
        Pool storage pool = pools[poolId];
        pool.balances[from] -= amount;
        pool.totalSupply -= amount;
    }

    /**
     * @dev 移除流动性
     */
    function removeLiquidity(
        bytes32 poolId,
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        Pool storage pool = pools[poolId];
        require(pool.balances[msg.sender] >= liquidity, "Insufficient liquidity");

        // 计算应返还的代币数量
        amount0 = (liquidity * pool.reserve0) / pool.totalSupply;
        amount1 = (liquidity * pool.reserve1) / pool.totalSupply;
        require(amount0 >= amount0Min, "Insufficient amount0");
        require(amount1 >= amount1Min, "Insufficient amount1");

        // 销毁LP代币
        _burn(msg.sender, liquidity, poolId);

        // 更新储备量
        pool.reserve0 -= amount0;
        pool.reserve1 -= amount1;

        // 转出代币
        IERC20(pool.token0).safeTransfer(to, amount0);
        IERC20(pool.token1).safeTransfer(to, amount1);

        emit LiquidityRemoved(poolId, to, amount0, amount1, liquidity);
    }

    /**
     * @dev 交易代币
     * @param poolId 池子ID
     * @param amount0In token0输入数量
     * @param amount1In token1输入数量
     * @param amount0Out token0输出数量
     * @param amount1Out token1输出数量
     * @param to 接收代币的地址
     * 
     * 注意：
     * - 使用(x + Δx * 0.997) * (y - Δy) = x * y计算
     * - 收取0.3%手续费
     * - 验证K值保持不变
     */
    function swap(
        bytes32 poolId,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external nonReentrant {
        Pool storage pool = pools[poolId];
        require(amount0Out > 0 || amount1Out > 0, "Insufficient output amount");
        require(amount0In > 0 || amount1In > 0, "Insufficient input amount");

        // 检查储备量
        require(amount0Out < pool.reserve0 && amount1Out < pool.reserve1, "Insufficient liquidity");

        // 转入代币
        if (amount0In > 0) {
            IERC20(pool.token0).safeTransferFrom(msg.sender, address(this), amount0In);
        }
        if (amount1In > 0) {
            IERC20(pool.token1).safeTransferFrom(msg.sender, address(this), amount1In);
        }

        // 计算新的储备量
        uint256 balance0 = pool.reserve0 + amount0In - amount0Out;
        uint256 balance1 = pool.reserve1 + amount1In - amount1Out;

        // 验证常积公式 (k = x * y)
        // 考虑手续费：实际输入金额 = 输入金额 * (1 - 费率)
        uint256 adjustedAmount0In = amount0In > 0 ? 
            (amount0In * (FEE_DENOMINATOR - SWAP_FEE)) / FEE_DENOMINATOR : 0;
        uint256 adjustedAmount1In = amount1In > 0 ? 
            (amount1In * (FEE_DENOMINATOR - SWAP_FEE)) / FEE_DENOMINATOR : 0;

        uint256 balance0Adjusted = balance0 - adjustedAmount0In;
        uint256 balance1Adjusted = balance1 - adjustedAmount1In;

        require(
            balance0Adjusted * balance1Adjusted >= pool.reserve0 * pool.reserve1,
            "K constant check failed"
        );

        // 更新储备量
        pool.reserve0 = balance0;
        pool.reserve1 = balance1;

        // 转出代币
        if (amount0Out > 0) {
            IERC20(pool.token0).safeTransfer(to, amount0Out);
        }
        if (amount1Out > 0) {
            IERC20(pool.token1).safeTransfer(to, amount1Out);
        }

        emit Swap(poolId, msg.sender, amount0In, amount1In, amount0Out, amount1Out);
    }

    /**
     * @dev 获取交易输出金额
     * @param amountIn 输入金额
     * @param reserveIn 输入代币储备量
     * @param reserveOut 输出代币储备量
     * @return amountOut 预计输出金额
     * 
     * 注意：实际交易结果可能因滑点有偏差
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        // 计算扣除手续费后的实际输入金额
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - SWAP_FEE);
        
        // 使用常积公式计算输出金额
        // (x + Δx * 0.997) * (y - Δy) = x * y
        // 其中 x 是输入储备量，y 是输出储备量，Δx 是输入金额，Δy 是输出金额
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);
    }

    /**
     * @dev 获取交易输入金额
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountIn) {
        require(amountOut > 0, "Insufficient output amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        // 使用常积公式计算输入金额
        // (x + Δx) * (y - Δy) = x * y
        // 考虑手续费后：(x + Δx * 0.997) * (y - Δy) = x * y
        amountIn = (reserveIn * amountOut * FEE_DENOMINATOR) / 
            ((reserveOut - amountOut) * (FEE_DENOMINATOR - SWAP_FEE));
    }

    /**
     * @dev 获取池子信息
     */
    function getPoolInfo(bytes32 poolId) external view returns (
        address token0,
        address token1,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalSupply
    ) {
        Pool storage pool = pools[poolId];
        return (
            pool.token0,
            pool.token1,
            pool.reserve0,
            pool.reserve1,
            pool.totalSupply
        );
    }

    /**
     * @dev 获取用户LP代币余额
     */
    function balanceOf(address user, bytes32 poolId) external view returns (uint256) {
        return pools[poolId].balances[user];
    }
}