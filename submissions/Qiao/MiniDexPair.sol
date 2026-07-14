 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MiniDexPair is ReentrancyGuard {
    address public immutable tokenA;
    address public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLPSupply;

    mapping(address => uint256) public lpBalances;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swapped(address indexed user, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "Identical tokens.");
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address.");

        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function _updateReserves() private {
        reserveA = IERC20(tokenA).balanceOf(address(this));
        reserveB = IERC20(tokenB).balanceOf(address(this));
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant {
        require(amountA > 0 && amountB > 0, "Invalid amount to add.");
        
        uint256 lpToMint;
        if(totalLPSupply == 0) {
            lpToMint = sqrt(amountA * amountB);
        } else {
            lpToMint = min(amountA * totalLPSupply / reserveA, amountB * totalLPSupply / reserveB);
        }

        lpBalances[msg.sender] += lpToMint;
        totalLPSupply += lpToMint;

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        _updateReserves();

        emit LiquidityAdded(msg.sender, amountA, amountB, lpToMint);
    }

    function removeLiquidity(uint256 lpAmount) external nonReentrant {
        require(lpAmount > 0 && lpAmount <= lpBalances[msg.sender], "Invalid amount to remove.");
        
        uint256 amountA = lpAmount * reserveA / totalLPSupply;
        uint256 amountB = lpAmount * reserveB / totalLPSupply;

        lpBalances[msg.sender] -= lpAmount;
        totalLPSupply -= lpAmount;

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        _updateReserves();

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    function getAmountOut(uint256 inputAmount, address inputToken) public view returns (uint256 outputAmount) {
        require(inputToken == tokenA || inputToken == tokenB, "Invalid token.");
        require(inputAmount > 0, "Invalid amount.");

        bool isTokenA = (inputToken == tokenA);
        (uint256 inputReserve, uint256 outputReserve) = isTokenA ? (reserveA, reserveB) : (reserveB, reserveA);
        outputAmount = outputReserve - inputReserve * 1000 * outputReserve / (inputReserve * 1000 + inputAmount * 997);
    }

    function swap(uint256 inputAmount, address inputToken) external nonReentrant {
        require(inputToken == tokenA || inputToken == tokenB, "Invalid token.");
        require(inputAmount > 0, "Invalid amount.");

        bool isTokenA = (inputToken == tokenA);
        address outputToken = isTokenA ? tokenB : tokenA;
        uint256 outputAmount = getAmountOut(inputAmount, inputToken);

        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);
        IERC20(outputToken).transfer(msg.sender, outputAmount);

        _updateReserves();

        emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);

    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getLPBalance(address user) external view returns (uint256) {
        require(user != address(0), "Invalid address.");
        return lpBalances[user];
    }

    function getTotalLPSupply() external view returns (uint256) {
        return totalLPSupply;    
    }
 
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

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