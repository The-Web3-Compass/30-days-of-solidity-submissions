// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20 Minimal Interface
 * @dev Interface for required ERC20 functions for AMM
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title AutomatedMarketMaker
 * @author shivam
 * @notice A basic Automated Market Maker (AMM) contract for swapping two ERC-20 tokens using the constant product formula (x * y = k) and managing liquidity pools.
 * @dev This contract implements a basic AMM with constant product formula and liquidity management.
 */
contract AutomatedMarketMaker {

    /// @notice Event emitted when liquidity is added to the pool
    /// @param provider The address of the liquidity provider
    /// @param amountA The amount of tokenA added
    /// @param amountB The amount of tokenB added
    /// @param liquidityMinted The amount of liquidity tokens minted
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidityMinted);

    /// @notice Event emitted when liquidity is removed from the pool
    /// @param provider The address of the liquidity provider
    /// @param amount The amount of liquidity tokens burned
    /// @param amountA The amount of tokenA withdrawn
    /// @param amountB The amount of tokenB withdrawn
    event LiquidityRemoved(address indexed provider, uint256 amount, uint256 amountA, uint256 amountB);

    /// @notice Event emitted when a token swap occurs
    /// @param swapper The address of the swapper
    /// @param tokenIn The address of the token sent in
    /// @param amountIn The amount of token sent in
    /// @param tokenOut The address of the token sent out
    /// @param amountOut The amount of token sent out
    event TokenSwapped(address indexed swapper, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    /// @notice The address of the first ERC-20 token in the pool
    IERC20 public tokenA;
    /// @notice The address of the second ERC-20 token in the pool
    IERC20 public tokenB;

    /// @notice The current reserve of tokenA in the pool
    uint256 public reserveA;
    /// @notice The current reserve of tokenB in the pool
    uint256 public reserveB;
    /// @notice The total supply of liquidity tokens
    uint256 public totalSupply;

    /// @notice The minimum amount of liquidity tokens to lock
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    /// @notice Mapping from liquidity provider address to their balance of liquidity tokens
    mapping(address => uint256) public liquidityTokens;

    /// @notice The trading fee percentage (e.g., 997 for 0.3% fee, 1000 for 0% fee)
    uint256 public fee;

    /**
     * @notice Initializes the contract with the addresses of the two ERC-20 tokens and the trading fee.
     * @param _tokenA The address of the first ERC-20 token.
     * @param _tokenB The address of the second ERC-20 token.
     * @param _fee The trading fee percentage (multiplied by 1000, e.g., 3 for 0.3%).
     */
    constructor(address _tokenA, address _tokenB, uint256 _fee) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        fee = 1000 - _fee; // Store as multiplier (1000 - fee_percentage)
    }

    /**
     * @notice Adds liquidity to the pool by depositing tokenA and tokenB.
     * @param amountA The amount of tokenA to add.
     * @param amountB The amount of tokenB to add.
     * @dev Requires amounts to be greater than 0.
     * @dev For subsequent liquidity additions, requires amounts to be proportional to current reserves.
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint256 liquidityMinted;
        if (totalSupply == 0) {
            liquidityMinted = amountA;
            // Lock minimum liquidity to prevent potential issues with zero liquidity
            liquidityTokens[address(0)] += MINIMUM_LIQUIDITY;
            totalSupply += MINIMUM_LIQUIDITY;
            liquidityMinted -= MINIMUM_LIQUIDITY;
        } else {
            uint256 shareA = (amountA * totalSupply) / reserveA;
            uint256 shareB = (amountB * totalSupply) / reserveB;
            require(shareA == shareB, "Amounts must be proportional to reserves");
            liquidityMinted = shareA;
        }

        reserveA += amountA;
        reserveB += amountB;
        totalSupply += liquidityMinted;
        liquidityTokens[msg.sender] += liquidityMinted;
        emit LiquidityAdded(msg.sender, amountA, amountB, liquidityMinted);
    }

    /**
     * @notice Removes liquidity from the pool by burning liquidity tokens.
     * @param amount The amount of liquidity tokens to burn.
     * @dev Requires the amount to be greater than 0 and the sender to have sufficient liquidity tokens.
     */
    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(liquidityTokens[msg.sender] >= amount, "Insufficient liquidity tokens");

        uint256 amountA = (amount * reserveA) / totalSupply;
        uint256 amountB = (amount * reserveB) / totalSupply;

        require(amountA > 0 && amountB > 0, "Insufficient reserves");

        liquidityTokens[msg.sender] -= amount;
        totalSupply -= amount;
        reserveA -= amountA;
        reserveB -= amountB;

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);
        emit LiquidityRemoved(msg.sender, amount, amountA, amountB);
    }

    /**
     * @notice Swaps one token for the other using the constant product formula.
     * @param tokenIn The address of the token being sent in.
     * @param amountIn The amount of the token being sent in.
     * @param amountOutMin The minimum amount of the output token.
     * @param deadline The deadline for the transaction.
     * @return amountOut The amount of the output token received.
     * @dev Requires the amount to be greater than 0 and the token to be one of the pool's tokens.
     * @dev Requires sufficient liquidity in the pool.
     */
    function swapTokens(address tokenIn, uint256 amountIn, uint256 amountOutMin, uint256 deadline) external returns (uint256) {
        require(block.timestamp <= deadline, "Swap transaction expired");
        require(amountIn > 0, "Amount must be greater than 0");
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");

        uint256 reserveIn;
        uint256 reserveOut;
        IERC20 tokenOut;

        if (tokenIn == address(tokenA)) {
            reserveIn = reserveA;
            reserveOut = reserveB;
            tokenOut = tokenB;
        } else {
            reserveIn = reserveB;
            reserveOut = reserveA;
            tokenOut = tokenA;
        }

        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Calculate amountOut using the constant product formula with fee:
        // fee is stored as 1000 - fee_percentage
        uint256 amountInWithFee = amountIn * fee / 1000;
        uint256 amountOut = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);

        require(amountOut > 0, "Amount out is zero");
        require(amountOut >= amountOutMin, "Amount out is less than minimum");
        require(reserveOut >= amountOut, "Insufficient reserves for swap");


        if (tokenIn == address(tokenA)) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        IERC20(tokenOut).transfer(msg.sender, amountOut);
        emit TokenSwapped(msg.sender, tokenIn, amountIn, address(tokenOut), amountOut);
        return amountOut;
    }
}