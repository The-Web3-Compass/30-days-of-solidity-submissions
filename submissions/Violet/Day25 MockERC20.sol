// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @dev A simple ERC20 token for testing purposes.
 */
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * (10**decimals()));
    }
}

/**
 * @title AutomatedMarketMaker
 * @dev A simple Automated Market Maker (AMM) using the constant product formula.
 * This contract also acts as an ERC20 token for liquidity provider (LP) shares.
 */
contract AutomatedMarketMaker is ERC20 {
    // --- State Variables ---
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;
    
    // --- Events ---
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokensMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokensBurned);
    event Swapped(address indexed user, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    constructor(
        address _tokenA,
        address _tokenB
    ) ERC20("AMM-LP-Token", "ALP") {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // --- Core Functions ---

    /**
     * @dev Adds liquidity to the pool.
     */
    function addLiquidity(uint256 _amountA, uint256 _amountB) external returns (uint256 lpTokens) {
        require(_amountA > 0 && _amountB > 0, "Amounts must be positive");

        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        // For the first liquidity provider
        if (totalSupply() == 0) {
            lpTokens = sqrt(_amountA * _amountB);
            _mint(msg.sender, lpTokens);
        } else {
            // Ensure the ratio is maintained
            require(reserveA * _amountB == reserveB * _amountA, "Incorrect ratio");
            lpTokens = (_amountA * totalSupply()) / reserveA;
            _mint(msg.sender, lpTokens);
        }

        reserveA += _amountA;
        reserveB += _amountB;

        emit LiquidityAdded(msg.sender, _amountA, _amountB, lpTokens);
    }

    /**
     * @dev Swaps one token for another.
     */
    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut) {
        require(_tokenIn == address(tokenA) || _tokenIn == address(tokenB), "Invalid token");
        require(_amountIn > 0, "Amount in must be positive");

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

        // Transfer token in from user
        tokenIn_.transferFrom(msg.sender, address(this), _amountIn);

        // Calculate output amount based on x * y = k
        // amountOut = (reserveOut * amountIn) / (reserveIn + amountIn)
        // We subtract a small fee (0.3%) for liquidity providers
        uint256 amountInWithFee = _amountIn * 997; // 1000 - 3 (0.3% fee)
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
        
        require(amountOut > 0, "Insufficient output amount");

        // Update reserves
        if (_tokenIn == address(tokenA)) {
            reserveA += _amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += _amountIn;
            reserveA -= amountOut;
        }

        // Transfer token out to user
        tokenOut_.transfer(msg.sender, amountOut);

        emit Swapped(msg.sender, _tokenIn, _amountIn, address(tokenOut_), amountOut);
    }

    /**
     * @dev Removes liquidity from the pool.
     */
    function removeLiquidity(uint256 _lpAmount) external returns (uint256 amountA, uint256 amountB) {
        require(_lpAmount > 0, "LP amount must be positive");
        
        uint256 totalLP = totalSupply();
        amountA = (_lpAmount * reserveA) / totalLP;
        amountB = (_lpAmount * reserveB) / totalLP;

        require(amountA > 0 && amountB > 0, "Insufficient liquidity to remove");

        reserveA -= amountA;
        reserveB -= amountB;
        
        _burn(msg.sender, _lpAmount);
        
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, _lpAmount);
    }
    
    // --- Helper Functions ---
    
    // A simple integer square root function (for initial liquidity calculation)
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
