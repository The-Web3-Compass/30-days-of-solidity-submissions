// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MiniDexPair is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable tokenA;
    address public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalLPSupply;

    uint256 private constant MINIMUM_LIQUIDITY = 10**3;
    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    mapping(address => uint256) public lpBalances;

    error IdenticalTokens();
    error ZeroAddress();
    error InvalidAmounts();
    error InsufficientInitialLiquidity();
    error ZeroLPMinted();
    error InvalidLPAmount();
    error InsufficientLiquidityBurned();
    error InvalidInputToken();
    error ZeroInput();
    error InsufficientLiquidity();
    error InsufficientOutput();
    error KInvariantViolation();

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swapped(address indexed user, address indexed inputToken, uint256 inputAmount, address indexed outputToken, uint256 outputAmount);
    event ReservesUpdated(uint256 reserveA, uint256 reserveB);

    constructor(address _tokenA, address _tokenB) {
        if (_tokenA == _tokenB) revert IdenticalTokens();
        if (_tokenA == address(0) || _tokenB == address(0)) revert ZeroAddress();

        tokenA = _tokenA;
        tokenB = _tokenB;
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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _updateReserves() private {
        uint256 newReserveA = IERC20(tokenA).balanceOf(address(this));
        uint256 newReserveB = IERC20(tokenB).balanceOf(address(this));
        reserveA = newReserveA;
        reserveB = newReserveB;
        emit ReservesUpdated(newReserveA, newReserveB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant {
        if (amountA == 0 || amountB == 0) revert InvalidAmounts();

        uint256 balanceABefore = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceBBefore = IERC20(tokenB).balanceOf(address(this));

        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        uint256 actualAmountA = IERC20(tokenA).balanceOf(address(this)) - balanceABefore;
        uint256 actualAmountB = IERC20(tokenB).balanceOf(address(this)) - balanceBBefore;

        uint256 lpToMint;
        if (totalLPSupply == 0) {
            lpToMint = sqrt(actualAmountA * actualAmountB);
            if (lpToMint <= MINIMUM_LIQUIDITY) revert InsufficientInitialLiquidity();
            lpToMint -= MINIMUM_LIQUIDITY;
            totalLPSupply = MINIMUM_LIQUIDITY;
        } else {
            lpToMint = min(
                (actualAmountA * totalLPSupply) / reserveA,
                (actualAmountB * totalLPSupply) / reserveB
            );
        }

        if (lpToMint == 0) revert ZeroLPMinted();

        lpBalances[msg.sender] += lpToMint;
        totalLPSupply += lpToMint;

        _updateReserves();

        emit LiquidityAdded(msg.sender, actualAmountA, actualAmountB, lpToMint);
    }

    function removeLiquidity(uint256 lpAmount) external nonReentrant {
        if (lpAmount == 0 || lpAmount > lpBalances[msg.sender]) revert InvalidLPAmount();

        uint256 amountA = (lpAmount * reserveA) / totalLPSupply;
        uint256 amountB = (lpAmount * reserveB) / totalLPSupply;

        if (amountA == 0 || amountB == 0) revert InsufficientLiquidityBurned();

        lpBalances[msg.sender] -= lpAmount;
        totalLPSupply -= lpAmount;

        IERC20(tokenA).safeTransfer(msg.sender, amountA);
        IERC20(tokenB).safeTransfer(msg.sender, amountB);

        _updateReserves();

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    function getAmountOut(uint256 inputAmount, address inputToken) public view returns (uint256 outputAmount) {
        if (inputToken != tokenA && inputToken != tokenB) revert InvalidInputToken();
        if (inputAmount == 0) revert ZeroInput();

        bool isTokenA = inputToken == tokenA;
        (uint256 inputReserve, uint256 outputReserve) = isTokenA ? (reserveA, reserveB) : (reserveB, reserveA);

        if (inputReserve == 0 || outputReserve == 0) revert InsufficientLiquidity();

        uint256 inputWithFee = inputAmount * FEE_NUMERATOR;
        uint256 numerator = inputWithFee * outputReserve;
        uint256 denominator = (inputReserve * FEE_DENOMINATOR) + inputWithFee;

        outputAmount = numerator / denominator;
    }

    function swap(uint256 inputAmount, address inputToken) external nonReentrant {
        if (inputAmount == 0) revert ZeroInput();
        if (inputToken != tokenA && inputToken != tokenB) revert InvalidInputToken();

        address outputToken = inputToken == tokenA ? tokenB : tokenA;
        uint256 outputAmount = getAmountOut(inputAmount, inputToken);

        if (outputAmount == 0) revert InsufficientOutput();

        uint256 k = reserveA * reserveB;

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        IERC20(outputToken).safeTransfer(msg.sender, outputAmount);

        _updateReserves();

        if (reserveA * reserveB < k) revert KInvariantViolation();

        emit Swapped(msg.sender, inputToken, inputAmount, outputToken, outputAmount);
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getLPBalance(address user) external view returns (uint256) {
        return lpBalances[user];
    }

    function getTotalLPSupply() external view returns (uint256) {
        return totalLPSupply;
    }
}