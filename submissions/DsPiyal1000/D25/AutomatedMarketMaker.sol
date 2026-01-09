// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AutomatedMarketMaker is ERC20, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public lastUpdateTimestamp;

    uint256 private constant MINIMUM_LIQUIDITY = 1000;
    uint256 private constant FEE_DENOMINATOR = 1000;
    uint256 private constant FEE_NUMERATOR = 3; 
    bool private _locked;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokenSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
    event ProtocolFeeUpdated(uint256 oldFee, uint256 newFee);

    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        Ownable(msg.sender)
    {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        require(_tokenA != _tokenB, "Tokens must be different");

        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lastUpdateTimestamp = block.timestamp;
    }

    modifier ensureNonZeroAddress(address addr) {
        require(addr != address(0), "Zero address not allowed");
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }

    function sqrt(uint256 y) internal pure returns(uint256 z) {
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
        return z;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant returns (uint256 liquidity) {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        if (totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
            require(liquidity > MINIMUM_LIQUIDITY, "Insufficient initial liquidity");

            _mint(address(1), MINIMUM_LIQUIDITY); 
            liquidity = liquidity - MINIMUM_LIQUIDITY;
        } else {
            liquidity = min(
                (amountA * totalSupply()) / reserveA,
                (amountB * totalSupply()) / reserveB
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        _mint(msg.sender, liquidity);

        _updateReserves(
            reserveA + amountA,
            reserveB + amountB
        );

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
        return liquidity;
    }

    function removeLiquidity(uint256 liquidityToRemove) external nonReentrant returns(uint256 amountAOut, uint256 amountBOut) {
        require(liquidityToRemove > 0, "Liquidity to remove must be > 0");
        require(balanceOf(msg.sender) >= liquidityToRemove, "Insufficient liquidity tokens");

        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");

        amountAOut = (liquidityToRemove * reserveA) / totalLiquidity;
        amountBOut = (liquidityToRemove * reserveB) / totalLiquidity;

        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");

        _burn(msg.sender, liquidityToRemove);

        _updateReserves(
            reserveA - amountAOut,
            reserveB - amountBOut
        );

        tokenA.safeTransfer(msg.sender, amountAOut);
        tokenB.safeTransfer(msg.sender, amountBOut);

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
        return (amountAOut, amountBOut);
    }

    function swapAforB(uint256 amountAIn, uint256 minBOut) external nonReentrant returns (uint256 amountBOut) {
        require(amountAIn > 0, "Amount must be > 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient reserves");

        uint256 amountAInWithFee = (amountAIn * (FEE_DENOMINATOR - FEE_NUMERATOR)) / FEE_DENOMINATOR;
        amountBOut = (reserveB * amountAInWithFee) / (reserveA + amountAInWithFee);

        require(amountBOut >= minBOut, "Slippage too high");
        require(amountBOut > 0 && amountBOut < reserveB, "Invalid output amount");

        tokenA.safeTransferFrom(msg.sender, address(this), amountAIn);

        _updateReserves(
            reserveA + amountAIn,
            reserveB - amountBOut
        );

        tokenB.safeTransfer(msg.sender, amountBOut);

        emit TokenSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
        return amountBOut;
    }

    function swapBforA(uint256 amountBIn, uint256 minAOut) external nonReentrant returns (uint256 amountAOut) {
        require(amountBIn > 0, "Amount must be > 0");
        require(reserveB > 0 && reserveA > 0, "Insufficient reserves");

        uint256 amountBInWithFee = (amountBIn * (FEE_DENOMINATOR - FEE_NUMERATOR)) / FEE_DENOMINATOR;
        amountAOut = (reserveA * amountBInWithFee) / (reserveB + amountBInWithFee);

        require(amountAOut >= minAOut, "Slippage too high");
        require(amountAOut > 0 && amountAOut < reserveA, "Invalid output amount");

        tokenB.safeTransferFrom(msg.sender, address(this), amountBIn);

        _updateReserves(
            reserveA - amountAOut,
            reserveB + amountBIn
        );

        tokenA.safeTransfer(msg.sender, amountAOut);

        emit TokenSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
        return amountAOut;
    }

    function _updateReserves(uint256 _reserveA, uint256 _reserveB) private {
        reserveA = _reserveA;
        reserveB = _reserveB;
        lastUpdateTimestamp = block.timestamp;
    }

    function getReserves() external view returns (uint256, uint256, uint256) {
        return (reserveA, reserveB, lastUpdateTimestamp);
    }

    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256) {
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");
        require(amountIn > 0, "Amount must be > 0");

        uint256 amountInWithFee = (amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR)) / FEE_DENOMINATOR;

        if (tokenIn == address(tokenA)) {
            return (reserveB * amountInWithFee) / (reserveA + amountInWithFee);
        } else {
            return (reserveA * amountInWithFee) / (reserveB + amountInWithFee);
        }
    }

    function getTokenRatio() external view returns (uint256) {
        require(reserveA > 0 && reserveB > 0, "Reserves cannot be zero");
        return (reserveA * 1e18) / reserveB; 
    }

    function rescueToken(address token, address to, uint256 amount) external onlyOwner ensureNonZeroAddress(to) {
        require(token != address(tokenA) && token != address(tokenB), "Cannot rescue pool tokens");
        IERC20(token).safeTransfer(to, amount);
    }
}