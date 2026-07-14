// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AutomatedMarketMaker is ERC20 {
    address public owner;

    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    event LiquityAdd(address indexed provider,uint256 amountA,unit256 amountB,uint256 liquidity);
    event LiquityRemove(address indexed provider,uint256 amountA,uint256 amounB,uint256 liquidity);
    event TokensSwapped(address indexed trader,uint256 tokenId,uint256 tokenout,uint256 amountIn,uint256 amountOut);

    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        owner = msg.sender;
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);  
    }

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

    function addLiquidity(uint256 amountA,uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");
        // The user needs to approve the contract to take their tokens first.
        // This is standard ERC-20 behavior — the user must call approve() beforehand.
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        // This part decides how many LP tokens to give the user.
        uint256 liquidity;
        if (totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min(
                amountA * totalSupply() / reserveA,
                amountB * totalSupply() / reserveB
            );
        }

        _mint(msg.sender, liquidity);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }
    
    
    function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut) {
        require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
        // Checking how many LP tokens the user has.
        require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");

        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");
        // their LP share × total token reserve = their withdrawal
        // If they own 25% of the LP tokens, they get back 25% of both tokenA and tokenB in the pool.
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
    /**
    This design keeps the pool balanced, 
    prevents manipulation, and automatically adjusts the price based on supply and demand. 
    */
    function swapAforB(uint256 amountAIn, uint256 minBOut) external {
        require(amountAIn > 0, "Amounts must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountAInWithFee = amountAIn * 997 / 1000;
        uint256 amountBOut = reserveB * amountAInWithFee / (reserveA + amountAInWithFee);
        require(amountBOut >= minBOut, "Slippage too high");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAInWithFee;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, address(tokenA), address(tokenB),amountAIn,amountBOut);

    }

    function swapBforA(uint256 amountBIn,uint256 minAOut) external {
        require(amountBIn > 0, "Amounts must be > 0");
        require(reserveB > 0 && reserveA > 0, "Insufficient reserves");

        uint256 amountBInWithFee = amountBIn * 997 / 1000;
        uint256 amountAOut = reserveB * amountBInWithFee / (reserveB + amountBInWithFee);
        require(amountAOut >= minAOut, "Slippage too high");
        
        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBInWithFee;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, address(tokenB), address(tokenA),amountBIn,amountAOut);
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }



}