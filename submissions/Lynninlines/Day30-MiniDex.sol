// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MiniDex is Ownable, ReentrancyGuard {
    constructor() Ownable(msg.sender) ReentrancyGuard() {}

    
    event LiquidityAdded(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(address indexed sender, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    
    struct LiquidityPool {
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalLiquidity;
        mapping(address => uint256) liquidityProviders;
    }

    
    mapping(bytes32 => LiquidityPool) public liquidityPools;

    
    uint256 public creationFee = 0.01 ether;

    
    uint256 public swapFee = 30;

    
    function _poolKey(address tokenA, address tokenB) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    
    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) external payable nonReentrant {
        require(tokenA != tokenB, "Same tokens");
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        bytes32 poolKey = _poolKey(tokenA, tokenB);
        LiquidityPool storage pool = liquidityPools[poolKey];

        
        if (pool.totalLiquidity == 0) {
            require(msg.value >= creationFee, "Creation fee required");
        }

        
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        
        uint256 liquidity;
        if (pool.totalLiquidity == 0) {
            liquidity = amountA; 
        } else {
            uint256 liquidityA = (amountA * pool.totalLiquidity) / pool.reserveA;
            uint256 liquidityB = (amountB * pool.totalLiquidity) / pool.reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        
        pool.reserveA += amountA;
        pool.reserveB += amountB;
        pool.totalLiquidity += liquidity;
        pool.liquidityProviders[msg.sender] += liquidity;

        
        if (pool.tokenA == address(0)) {
            pool.tokenA = tokenA;
            pool.tokenB = tokenB;
        }

        emit LiquidityAdded(tokenA, tokenB, amountA, amountB, liquidity);
    }

    
    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity) external nonReentrant {
        bytes32 poolKey = _poolKey(tokenA, tokenB);
        LiquidityPool storage pool = liquidityPools[poolKey];

        require(pool.totalLiquidity > 0, "No liquidity");
        require(pool.liquidityProviders[msg.sender] >= liquidity, "Insufficient liquidity");

        
        uint256 amountA = (liquidity * pool.reserveA) / pool.totalLiquidity;
        uint256 amountB = (liquidity * pool.reserveB) / pool.totalLiquidity;

        
        pool.reserveA -= amountA;
        pool.reserveB -= amountB;
        pool.totalLiquidity -= liquidity;
        pool.liquidityProviders[msg.sender] -= liquidity;

        
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        emit LiquidityRemoved(tokenA, tokenB, amountA, amountB, liquidity);
    }

    
    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn, address recipient) external nonReentrant {
        require(tokenIn != tokenOut, "Same tokens");
        require(amountIn > 0, "Amount must be > 0");

        bytes32 poolKey = _poolKey(tokenIn, tokenOut);
        LiquidityPool storage pool = liquidityPools[poolKey];

        require(pool.totalLiquidity > 0, "No liquidity");

        
        bool isAtoB = tokenIn == pool.tokenA;
        uint256 inputReserve = isAtoB ? pool.reserveA : pool.reserveB;
        uint256 outputReserve = isAtoB ? pool.reserveB : pool.reserveA;

        
        uint256 fee = (amountIn * swapFee) / 10000;
        uint256 amountAfterFee = amountIn - fee;

        
        uint256 numerator = amountAfterFee * outputReserve;
        uint256 denominator = inputReserve + amountAfterFee;
        uint256 amountOut = numerator / denominator;

        require(amountOut > 0, "Insufficient output amount");

        
        if (isAtoB) {
            pool.reserveA += amountIn;
            pool.reserveB -= amountOut;
        } else {
            pool.reserveB += amountIn;
            pool.reserveA -= amountOut;
        }

        
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(recipient, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    
    function getTokenPrice(address tokenA, address tokenB, uint256 amountIn) external view returns (uint256) {
        bytes32 poolKey = _poolKey(tokenA, tokenB);
        LiquidityPool storage pool = liquidityPools[poolKey];

        if (pool.totalLiquidity == 0) return 0;

        bool isAtoB = tokenA == pool.tokenA;
        uint256 inputReserve = isAtoB ? pool.reserveA : pool.reserveB;
        uint256 outputReserve = isAtoB ? pool.reserveB : pool.reserveA;

        uint256 fee = (amountIn * swapFee) / 10000;
        uint256 amountAfterFee = amountIn - fee;

        uint256 numerator = amountAfterFee * outputReserve;
        uint256 denominator = inputReserve + amountAfterFee;

        return numerator / denominator;
    }

   
    function getLiquidityPool(address tokenA, address tokenB) external view returns (
        address token0,
        address token1,
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalLiquidity,
        uint256 userLiquidity
    ) {
        bytes32 poolKey = _poolKey(tokenA, tokenB);
        LiquidityPool storage pool = liquidityPools[poolKey];

        token0 = pool.tokenA;
        token1 = pool.tokenB;
        reserve0 = pool.reserveA;
        reserve1 = pool.reserveB;
        totalLiquidity = pool.totalLiquidity;
        userLiquidity = pool.liquidityProviders[msg.sender];
    }

    
    function setCreationFee(uint256 newFee) external onlyOwner {
        creationFee = newFee;
    }

    
    function setSwapFee(uint256 newFee) external onlyOwner {
        require(newFee <= 500, "Fee too high");
        swapFee = newFee;
    }

    
    function withdrawCreationFee() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    
    receive() external payable {}
}
