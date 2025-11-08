// AutomatedMarketMaker.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Automated Market Maker with Liquidity Token
/// @notice 实现了最基础的AMM（自动做市商）逻辑，支持两种ERC20代币的兑换和流动性管理
contract AutomatedMarketMaker is ERC20 {
    // --- 资金池核心变量 ---
    IERC20 public tokenA;      // 池子中的Token A
    IERC20 public tokenB;      // 池子中的Token B
    uint256 public reserveA;   // 当前池子中Token A的数量
    uint256 public reserveB;   // 当前池子中Token B的数量
    address public owner;      // 合约部署者

    // --- 事件定义 ---
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    /// @notice 构造函数，初始化池子支持的两种代币和LP Token信息
    /// @param _tokenA Token A的合约地址
    /// @param _tokenB Token B的合约地址
    /// @param _name   LP Token的名称
    /// @param _symbol LP Token的符号
    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    /// @notice 添加流动性，获得LP Token
    /// @dev 必须按当前池子A/B比例添加，否则只按较小值计入
    /// @param amountA 用户希望存入的Token A数量
    /// @param amountB 用户希望存入的Token B数量
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        // 1. 用户先approve本合约，合约才能转走用户的Token
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 liquidity;
        if (totalSupply() == 0) {
            // 第一次添加流动性，LP Token数量 = sqrt(amountA * amountB)
            // 这样保证LP Token和池子价值成正比
            liquidity = sqrt(amountA * amountB);
        } else {
            // 后续添加，必须按比例，否则只按较小值计入
            // LP Token数量 = min(amountA * totalSupply / reserveA, amountB * totalSupply / reserveB)
            liquidity = min(
                amountA * totalSupply() / reserveA,
                amountB * totalSupply() / reserveB
            );
        }
        require(liquidity > 0, "Insufficient liquidity minted");

        // 2. 给用户发放LP Token（继承自ERC20）
        _mint(msg.sender, liquidity);

        // 3. 更新池子余额
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice 移除流动性，销毁LP Token，取回A和B
    /// @param liquidityToRemove 用户希望销毁的LP Token数量
    /// @return amountAOut 实际取回的Token A数量
    /// @return amountBOut 实际取回的Token B数量
    function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut) {
        require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
        require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");

        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");

        // 按比例计算应得A、B数量
        // amountAOut = liquidityToRemove * reserveA / totalLiquidity
        // amountBOut = liquidityToRemove * reserveB / totalLiquidity
        amountAOut = liquidityToRemove * reserveA / totalLiquidity;
        amountBOut = liquidityToRemove * reserveB / totalLiquidity;

        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");

        // 更新池子余额
        reserveA -= amountAOut;
        reserveB -= amountBOut;

        // 销毁LP Token
        _burn(msg.sender, liquidityToRemove);

        // 转账A、B给用户
        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
        return (amountAOut, amountBOut);
    }

    /// @notice 用Token A兑换Token B（自动做市，x*y=k）
    /// @param amountAIn 用户输入的Token A数量
    /// @param minBOut 用户期望最少获得的Token B数量（滑点保护）
    function swapAforB(uint256 amountAIn, uint256 minBOut) external {
        require(amountAIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        // 1. 扣除手续费（如0.3%），实际入池A
        // amountAInWithFee = amountAIn * 997 / 1000
        uint256 amountAInWithFee = amountAIn * 997 / 1000;

        // 2. 用常数乘积公式计算能换多少B
        // amountBOut = reserveB * amountAInWithFee / (reserveA + amountAInWithFee)
        uint256 amountBOut = reserveB * amountAInWithFee / (reserveA + amountAInWithFee);

        require(amountBOut >= minBOut, "Slippage too high");

        // 3. 转账A进池，B给用户
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        // 4. 更新池子余额
        reserveA += amountAInWithFee; // 只加实际入池部分，手续费部分归池子所有
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    /// @notice 用Token B兑换Token A（自动做市，x*y=k）
    /// @param amountBIn 用户输入的Token B数量
    /// @param minAOut 用户期望最少获得的Token A数量（滑点保护）
    function swapBforA(uint256 amountBIn, uint256 minAOut) external {
        require(amountBIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        // 1. 扣除手续费
        uint256 amountBInWithFee = amountBIn * 997 / 1000;

        // 2. 用常数乘积公式计算能换多少A
        uint256 amountAOut = reserveA * amountBInWithFee / (reserveB + amountBInWithFee);

        require(amountAOut >= minAOut, "Slippage too high");

        // 3. 转账B进池，A给用户
        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        // 4. 更新池子余额
        reserveB += amountBInWithFee;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }

    /// @notice 查询当前池子的A、B余额
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    // --- 工具函数 ---

    /// @dev 取两数较小值
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Babylonian方法开平方（用于初始LP Token分配）
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
