// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @dev 一个用于测试的简单ERC20代币。
 */
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * (10**decimals()));
    }
}

/**
 * @title MiniDex
 * @dev 一个迷你的、基于恒定乘积公式的去中心化交易所。
 * 这个合约本身也是一个ERC20代币，用于代表流动性提供者的份额（LP代币）。
 */
contract MiniDex is ERC20 {
    // --- 状态变量 ---
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveA; // 池中TokenA的储备量
    uint256 public reserveB; // 池中TokenB的储备量
    
    // --- 事件 ---
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event Swapped(address indexed user, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    constructor(
        address _tokenA,
        address _tokenB
    ) ERC20("MiniDex-LP", "MDLP") {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // --- 核心功能 ---

    /**
     * @dev 添加流动性。
     */
    function addLiquidity(uint256 _amountA, uint256 _amountB) external returns (uint256 lpAmount) {
        require(_amountA > 0 && _amountB > 0, "Amounts must be positive");

        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        // 如果是第一个流动性提供者
        if (totalSupply() == 0) {
            lpAmount = sqrt(_amountA * _amountB);
            _mint(msg.sender, lpAmount);
        } else {
            // 确保维持现有的代币比例
            require(reserveA * _amountB == reserveB * _amountA, "Incorrect ratio");
            lpAmount = (_amountA * totalSupply()) / reserveA;
            _mint(msg.sender, lpAmount);
        }

        reserveA += _amountA;
        reserveB += _amountB;

        emit LiquidityAdded(msg.sender, _amountA, _amountB, lpAmount);
    }

    /**
     * @dev 移除流动性。
     */
    function removeLiquidity(uint256 _lpAmount) external returns (uint256 amountA, uint256 amountB) {
        require(_lpAmount > 0, "LP amount must be positive");
        
        uint256 totalLP = totalSupply();
        amountA = (_lpAmount * reserveA) / totalLP;
        amountB = (_lpAmount * reserveB) / totalLP;

        require(amountA > 0 && amountB > 0, "Insufficient liquidity");

        reserveA -= amountA;
        reserveB -= amountB;
        
        _burn(msg.sender, _lpAmount);
        
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, _lpAmount);
    }

    /**
     * @dev 交换代币。
     */
    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut) {
        require(_tokenIn == address(tokenA) || _tokenIn == address(tokenB), "Invalid token");
        require(_amountIn > 0, "Amount must be positive");

        IERC20 tokenIn_ = IERC20(_tokenIn);
        IERC20 tokenOut_;
        uint256 reserveIn;
        uint256 reserveOut;

        if (_tokenIn == address(tokenA)) {
            tokenOut_ = tokenB;
            reserveIn = reserveA;
            reserveOut = reserveB;
        } else {
            tokenOut_ = tokenA;
            reserveIn = reserveB;
            reserveOut = reserveA;
        }

        tokenIn_.transferFrom(msg.sender, address(this), _amountIn);

        // 根据 x * y = k 公式计算输出量，并扣除0.3%的手续费
        uint256 amountInWithFee = _amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
        
        require(amountOut > 0, "Insufficient output");

        // 更新储备量
        if (_tokenIn == address(tokenA)) {
            reserveA += _amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += _amountIn;
            reserveA -= amountOut;
        }

        tokenOut_.transfer(msg.sender, amountOut);

        emit Swapped(msg.sender, _tokenIn, _amountIn, address(tokenOut_), amountOut);
    }
    
    // --- 辅助函数 ---
    
    // 一个简单的整数平方根函数
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
