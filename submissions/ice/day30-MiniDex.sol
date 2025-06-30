/**
 * @title MiniDex
 * @dev 一个简单的代币交易交易所
 * 功能点：重点是将许多 DeFi 概念结合到实际应用中。
 * 
 * 【设计思路与核心概念解释】
 * 
 * 1. 最小的去中心化交易所（DEX）：
 *    - 无需中央机构，直接在区块链上进行代币交换
 *    - 通过智能合约自动执行交易，无需第三方参与
 *    - 任何人都可以创建交易对、提供流动性或进行交易
 * 
 * 2. 代币交换：
 *    - 基于"恒定乘积"公式（x * y = k）实现自动定价
 *    - 用户可以在不同代币之间进行兑换，价格由市场供需决定
 *    - 例如：用户可以用USDC换取ETH，或用ETH换取其他代币
 * 
 * 3. 流动性池：
 *    - 用户提供两种代币作为交易对的流动性
 *    - 流动性提供者获得LP代币作为凭证，可随时赎回
 *    - 流动性提供者从交易费用中获得收益
 * 
 * 4. 数字市场的创建：
 *    - 任何ERC20代币都可以在平台上创建交易对
 *    - 通过流动性池和自动做市商机制形成价格发现
 *    - 形成一个开放、无需许可的代币交易生态系统
 * 
 * 5. 迷你版证券交易所：
 *    - 类似传统证券交易所，但完全去中心化运行
 *    - 无需经纪人、结算所或中央交易系统
 *    - 所有交易在链上透明执行，任何人都可以验证
 * 
 * 【使用流程】
 * 
 * 1. 创建交易对：
 *    - 调用createPair()创建两种代币的交易对
 *    - 系统自动生成唯一的交易对ID
 * 
 * 2. 添加流动性：
 *    - 调用addLiquidity()向交易对提供两种代币
 *    - 首次添加时设定初始价格比例
 *    - 获得LP代币作为提供流动性的凭证
 * 
 * 3. 交换代币：
 *    - 调用swap()用一种代币换取另一种代币
 *    - 价格由池中代币储备比例自动决定
 *    - 交易收取0.3%手续费，留在池中奖励流动性提供者
 * 
 * 4. 移除流动性：
 *    - 调用removeLiquidity()销毁LP代币
 *    - 按比例取回两种代币
 *    - 包含提供流动性期间产生的手续费收益
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract MiniDex is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // 常量
    uint256 public constant MINIMUM_LIQUIDITY = 1000;  // 最小流动性
    uint256 public constant FEE_DENOMINATOR = 1000;    // 费用分母
    uint256 public constant TRADING_FEE = 3;           // 交易费率 0.3%

    // 交易对结构体
    struct Pair {
        IERC20 token0;         // 代币0
        IERC20 token1;         // 代币1
        uint256 reserve0;      // 储备量0
        uint256 reserve1;      // 储备量1
        uint256 totalSupply;   // LP代币总供应量
        mapping(address => uint256) balances;  // LP代币余额
    }

    // 状态变量
    mapping(bytes32 => Pair) public pairs;  // 交易对映射
    mapping(address => mapping(address => bytes32)) public getPairId;  // 代币对到ID的映射

    // 事件
    event PairCreated(
        bytes32 indexed pairId,
        address indexed token0,
        address indexed token1
    );

    event LiquidityAdded(
        bytes32 indexed pairId,
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );

    event LiquidityRemoved(
        bytes32 indexed pairId,
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );

    event Swap(
        bytes32 indexed pairId,
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );

    constructor() Ownable(msg.sender) {}

    /**
     * @dev 创建交易对
     */
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (bytes32 pairId) {
        require(tokenA != tokenB, "Identical addresses");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");
        require(getPairId[tokenA][tokenB] == bytes32(0), "Pair exists");

        // 确保代币地址排序
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // 生成交易对ID
        pairId = keccak256(abi.encodePacked(token0, token1));

        // 创建交易对
        Pair storage pair = pairs[pairId];
        pair.token0 = IERC20(token0);
        pair.token1 = IERC20(token1);

        // 更新映射
        getPairId[token0][token1] = pairId;
        getPairId[token1][token0] = pairId;

        emit PairCreated(pairId, token0, token1);
    }

    /**
     * @dev 添加流动性
     */
    function addLiquidity(
        bytes32 pairId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    ) external nonReentrant returns (uint256 liquidity) {
        Pair storage pair = pairs[pairId];
        require(address(pair.token0) != address(0), "Pair not exists");

        uint256 amount0;
        uint256 amount1;

        // 计算添加数量
        if (pair.reserve0 == 0 && pair.reserve1 == 0) {
            // 首次添加流动性
            amount0 = amount0Desired;
            amount1 = amount1Desired;
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            pair.balances[address(0)] = MINIMUM_LIQUIDITY;  // 永久锁定最小流动性
        } else {
            // 按比例计算
            uint256 amount1Optimal = (amount0Desired * pair.reserve1) / pair.reserve0;
            if (amount1Optimal <= amount1Desired) {
                require(amount1Optimal >= amount1Min, "Insufficient amount1");
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                uint256 amount0Optimal = (amount1Desired * pair.reserve0) / pair.reserve1;
                require(amount0Optimal <= amount0Desired, "Excessive amount0");
                require(amount0Optimal >= amount0Min, "Insufficient amount0");
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }

            // 计算流动性代币数量
            liquidity = Math.min(
                (amount0 * pair.totalSupply) / pair.reserve0,
                (amount1 * pair.totalSupply) / pair.reserve1
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        // 转入代币
        pair.token0.safeTransferFrom(msg.sender, address(this), amount0);
        pair.token1.safeTransferFrom(msg.sender, address(this), amount1);

        // 更新储备量
        pair.reserve0 += amount0;
        pair.reserve1 += amount1;

        // 更新LP代币余额
        pair.balances[msg.sender] += liquidity;
        pair.totalSupply += liquidity;

        emit LiquidityAdded(pairId, msg.sender, amount0, amount1, liquidity);
    }

    /**
     * @dev 移除流动性
     */
    function removeLiquidity(
        bytes32 pairId,
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        Pair storage pair = pairs[pairId];
        require(pair.balances[msg.sender] >= liquidity, "Insufficient liquidity");

        // 计算返还数量
        amount0 = (liquidity * pair.reserve0) / pair.totalSupply;
        amount1 = (liquidity * pair.reserve1) / pair.totalSupply;
        require(amount0 >= amount0Min, "Insufficient amount0");
        require(amount1 >= amount1Min, "Insufficient amount1");

        // 更新LP代币余额
        pair.balances[msg.sender] -= liquidity;
        pair.totalSupply -= liquidity;

        // 更新储备量
        pair.reserve0 -= amount0;
        pair.reserve1 -= amount1;

        // 转出代币
        pair.token0.safeTransfer(msg.sender, amount0);
        pair.token1.safeTransfer(msg.sender, amount1);

        emit LiquidityRemoved(pairId, msg.sender, amount0, amount1, liquidity);
    }

    /**
     * @dev 交换代币
     */
    function swap(
        bytes32 pairId,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external nonReentrant {
        Pair storage pair = pairs[pairId];
        require(amount0Out > 0 || amount1Out > 0, "Insufficient output");
        require(amount0In > 0 || amount1In > 0, "Insufficient input");

        // 检查储备量
        require(amount0Out < pair.reserve0 && amount1Out < pair.reserve1, "Insufficient liquidity");

        // 转入代币
        if (amount0In > 0) {
            pair.token0.safeTransferFrom(msg.sender, address(this), amount0In);
        }
        if (amount1In > 0) {
            pair.token1.safeTransferFrom(msg.sender, address(this), amount1In);
        }

        // 计算新的储备量
        uint256 balance0 = pair.reserve0 + amount0In - amount0Out;
        uint256 balance1 = pair.reserve1 + amount1In - amount1Out;

        // 验证常积公式 (k = x * y)
        uint256 adjustedAmount0In = amount0In > 0 ? 
            (amount0In * (FEE_DENOMINATOR - TRADING_FEE)) / FEE_DENOMINATOR : 0;
        uint256 adjustedAmount1In = amount1In > 0 ? 
            (amount1In * (FEE_DENOMINATOR - TRADING_FEE)) / FEE_DENOMINATOR : 0;

        uint256 balance0Adjusted = balance0 - adjustedAmount0In;
        uint256 balance1Adjusted = balance1 - adjustedAmount1In;

        require(
            balance0Adjusted * balance1Adjusted >= pair.reserve0 * pair.reserve1,
            "K constant check failed"
        );

        // 更新储备量
        pair.reserve0 = balance0;
        pair.reserve1 = balance1;

        // 转出代币
        if (amount0Out > 0) {
            pair.token0.safeTransfer(to, amount0Out);
        }
        if (amount1Out > 0) {
            pair.token1.safeTransfer(to, amount1Out);
        }

        emit Swap(pairId, msg.sender, amount0In, amount1In, amount0Out, amount1Out);
    }

    /**
     * @dev 获取交易对信息
     */
    function getPairInfo(bytes32 pairId) external view returns (
        address token0,
        address token1,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalSupply
    ) {
        Pair storage pair = pairs[pairId];
        return (
            address(pair.token0),
            address(pair.token1),
            pair.reserve0,
            pair.reserve1,
            pair.totalSupply
        );
    }

    /**
     * @dev 获取用户LP代币余额
     */
    function balanceOf(address user, bytes32 pairId) external view returns (uint256) {
        return pairs[pairId].balances[user];
    }

    /**
     * @dev 计算交换输出金额
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(amountIn > 0, "Insufficient input");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - TRADING_FEE);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        return numerator / denominator;
    }

    /**
     * @dev 计算交换输入金额
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(amountOut > 0, "Insufficient output");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 numerator = reserveIn * amountOut * FEE_DENOMINATOR;
        uint256 denominator = (reserveOut - amountOut) * (FEE_DENOMINATOR - TRADING_FEE);
        return (numerator / denominator) + 1;
    }
}