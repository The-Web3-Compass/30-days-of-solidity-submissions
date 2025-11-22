// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// 导入ERC20标准
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/// @title Automated Market Maker with Liquidity Token
contract AutomatedMarketMaker is ERC20 {
    // IERC接口，像ERC—20代币，有transfer、transferFrom、approve等函数
    IERC20 public tokenA;
    IERC20 public tokenB;

    // 每种代币数量
    uint256 public reserveA;
    uint256 public reserveB;

    //部署合约的地址
    address public owner;

    //谁添加了多少流动性，添加了多少tokenA和tokenB，获得了多少LP代币
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity); 
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    //谁进行了交换，兑换进来的代币种类，给进的代币数量，兑换出去的代币种类和数量
    event TokensSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut); 

    // AMM支持哪些代币，LP代币的名称，谁部署了合约
    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    /// @notice Add liquidity to the pool
    // 用户通过存入等值金额的Token A和Token B来向池子添加流动性，同时获得LP代币
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        // 计算要铸造的LP代币，保证每个人在池子中的份额是公平的
        uint256 liquidity;
        if (totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min(
                amountA * totalSupply() / reserveA,
                amountB * totalSupply() / reserveB
            );
        }

        _mint(msg.sender, liquidity); // 把LP代币发给用户

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity from the pool
    function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut) {
        require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
        require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");

        // 获取LP代币总量
        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");

        // 计算要返回的代币数量
        // 用户的LP份额 * 代币总储备 = 提取数量
        amountAOut = liquidityToRemove * reserveA / totalLiquidity;
        amountBOut = liquidityToRemove * reserveB / totalLiquidity;

        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");

        reserveA -= amountAOut;
        reserveB -= amountBOut;

        _burn(msg.sender, liquidityToRemove); 

        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
        return (amountAOut, amountBOut);
    }

    /// @notice Swap token A for token B
    function swapAforB(uint256 amountAIn, uint256 minBOut) external {
        require(amountAIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountAInWithFee = amountAIn * 997 / 1000; // 收取0.3%手续费
        uint256 amountBOut = reserveB * amountAInWithFee / (reserveA + amountAInWithFee);

        require(amountBOut >= minBOut, "Slippage too high"); // 滑点检查

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAInWithFee;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    /// @notice Swap token B for token A
    function swapBforA(uint256 amountBIn, uint256 minAOut) external {
        require(amountBIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountBInWithFee = amountBIn * 997 / 1000;
        uint256 amountAOut = reserveA * amountBInWithFee / (reserveB + amountBInWithFee);

        require(amountAOut >= minAOut, "Slippage too high");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBInWithFee;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }

    /// @notice View the current reserves
    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    /// @dev Utility: Return the smaller of two values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Utility: Babylonian square root
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
