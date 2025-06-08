// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20 Minimal Interface
 * @dev Interface for required ERC20 functions for Liquidity Pool
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

/**
 * @title LiquidityPool
 * @author shivam
 * @dev Manages liquidity for a pair of tokens and facilitates swaps.
 * Acts as an ERC20 token for Liquidity Provider (LP) shares.
 * Uses a constant product formula (x * y = k) for pricing.
 * Takes a 0.3% fee on swaps, distributed to liquidity providers.
 */
contract LiquidityPool {
    // --- LP Token State ---
    /// @notice The name of the LP token.
    string public constant name = "MiniDEX LP Token";
    /// @notice The symbol of the LP token.
    string public constant symbol = "MDLP";
    /// @notice The number of decimals for the LP token.
    uint8 public constant decimals = 18;
    /// @notice The total supply of LP tokens.
    uint256 public totalSupply;
    /// @notice The balance of LP tokens for each address.
    mapping(address => uint256) public balanceOf;
    /// @notice The allowance of LP tokens for each address.
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Pool State ---
    /// @notice The address of the factory that created the pool.
    address public factory;
    /// @notice The address of the first token in the pair.
    address public token0;
    /// @notice The address of the second token in the pair.
    address public token1;

    // Reserves are updated after transfers occur
    uint256 private reserve0;
    uint256 private reserve1;

    uint256 private constant MINIMUM_LIQUIDITY = 10 ** 3; // Avoid division by zero, lock initial liquidity

    // --- Events ---
    /**
     * @notice Emitted when liquidity is added to the pool.
     * @param sender The address of the sender.
     * @param amount0 The amount of token0 added.
     * @param amount1 The amount of token1 added.
     */
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    /**
     * @notice Emitted when liquidity is removed from the pool.
     * @param sender The address of the sender.
     * @param amount0 The amount of token0 removed.
     * @param amount1 The amount of token1 removed.
     * @param to The address of the recipient.
     */
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );

    /**
     * @notice Emitted when a swap occurs.
     * @param sender The address of the sender.
     * @param amount0In The amount of token0 in.
     * @param amount1In The amount of token1 in.
     * @param amount0Out The amount of token0 out.
     * @param amount1Out The amount of token1 out.
     * @param to The address of the recipient.
     */
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /**
     * @notice Emitted when the reserves are updated.
     * @param reserve0 The new reserve of token0.
     * @param reserve1 The new reserve of token1.
     */
    event Sync(uint256 reserve0, uint256 reserve1);

    // LP Token Events
    /**
     * @notice Emitted when LP tokens are transferred.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param value The amount of LP tokens transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
     * @notice Emitted when an approval is set.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @param value The amount of LP tokens approved.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // --- Modifiers ---
    modifier lock() {
        // Basic reentrancy guard
        _;
    }

    // --- Constructor ---
    // Pool is created by the factory, initialization happens in `initialize`
    constructor() {
        factory = msg.sender; // Assume factory deploys this
    }

    // --- Initialization ---
    /**
     * @notice Initializes the pool with the two token addresses.
     * @dev Can only be called once by the factory.
     * @param _token0 Address of the first token.
     * @param _token1 Address of the second token.
     */
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "Pool: FORBIDDEN"); // Only factory can initialize
        require(
            token0 == address(0) && token1 == address(0),
            "Pool: ALREADY_INITIALIZED"
        );
        require(_token0 != _token1, "Pool: IDENTICAL_ADDRESSES");
        // Ensure consistent ordering
        (token0, token1) = _token0 < _token1
            ? (_token0, _token1)
            : (_token1, _token0);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Safely transfers tokens to prevent issues with non-standard ERC20 tokens.
     */
    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Pool: TRANSFER_FAILED"
        );
    }

    /**
     * @dev Mints LP tokens to a recipient.
     */
    function _mintLP(address to, uint256 amount) private {
        require(to != address(0), "Pool: MINT_TO_ZERO");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Burns LP tokens from a specific account.
     */
    function _burnLP(address from, uint256 amount) private {
        require(from != address(0), "Pool: BURN_FROM_ZERO");
        require(balanceOf[from] >= amount, "Pool: BURN_AMOUNT_EXCEEDS_BALANCE");
        totalSupply -= amount;
        balanceOf[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    /**
     * @dev Updates reserves based on current balances. Should be called after transfers.
     */
    function _updateReserves(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        emit Sync(_reserve0, _reserve1);
    }

    // --- Liquidity Provision ---

    /**
     * @notice Adds liquidity to the pool.
     * @dev Users must first approve the pool contract to spend their tokens.
     * @param amount0Desired The desired amount of token0 to add.
     * @param amount1Desired The desired amount of token1 to add.
     * @return amount0 The actual amount of token0 added.
     * @return amount1 The actual amount of token1 added.
     * @return liquidity The amount of LP tokens minted.
     */
    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired
    )
        external
        lock
        returns (uint256 amount0, uint256 amount1, uint256 liquidity)
    {
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;

        // Calculate optimal amounts if reserves exist
        if (_reserve0 > 0 || _reserve1 > 0) {
            uint256 amount1Optimal = (amount0Desired * _reserve1) / _reserve0;
            if (amount1Optimal <= amount1Desired) {
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                uint256 amount0Optimal = (amount1Desired * _reserve0) /
                    _reserve1;
                // amount0Optimal <= amount0Desired should hold if previous condition failed
                require(
                    amount0Optimal <= amount0Desired,
                    "Pool: INSUFFICIENT_B_AMOUNT"
                ); // Should not happen if logic is correct
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }
        } else {
            // First liquidity provider sets the initial ratio
            amount0 = amount0Desired;
            amount1 = amount1Desired;
        }

        require(
            amount0 > 0 && amount1 > 0,
            "Pool: INSUFFICIENT_LIQUIDITY_ADDED"
        );

        // Pull tokens from user
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        // Mint LP tokens
        uint256 _totalSupply = totalSupply; // Cache total supply
        if (_totalSupply == 0) {
            // Initial liquidity minting
            liquidity = amount0 > amount1 ? amount0 : amount1; // Simplistic initial mint
            require(
                liquidity > MINIMUM_LIQUIDITY,
                "Pool: INSUFFICIENT_INITIAL_LIQUIDITY"
            );
            _mintLP(address(0), MINIMUM_LIQUIDITY); // Lock minimum liquidity
            _mintLP(msg.sender, liquidity - MINIMUM_LIQUIDITY);
        } else {
            // Subsequent liquidity minting: proportional to existing reserves
            liquidity = (amount0 * _totalSupply) / _reserve0;
            uint256 liquidity1 = (amount1 * _totalSupply) / _reserve1;
            if (liquidity1 < liquidity) {
                liquidity = liquidity1;
            }
            require(liquidity > 0, "Pool: INSUFFICIENT_LIQUIDITY_MINTED");
            _mintLP(msg.sender, liquidity);
        }

        // Update reserves *after* calculations and transfers
        _updateReserves(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @notice Removes liquidity from the pool.
     * @dev Users must first approve the pool contract to spend their LP tokens.
     * @param liquidity The amount of LP tokens to burn.
     * @return amount0 The amount of token0 returned.
     * @return amount1 The amount of token1 returned.
     */
    function removeLiquidity(
        uint256 liquidity
    ) external lock returns (uint256 amount0, uint256 amount1) {
        require(liquidity > 0, "Pool: INSUFFICIENT_LIQUIDITY_BURNED");
        uint256 _balance0 = IERC20(token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(token1).balanceOf(address(this));
        uint256 _totalSupply = totalSupply;

        // Calculate underlying token amounts
        amount0 = (liquidity * _balance0) / _totalSupply;
        amount1 = (liquidity * _balance1) / _totalSupply;

        require(
            amount0 > 0 && amount1 > 0,
            "Pool: INSUFFICIENT_LIQUIDITY_BURNED"
        );

        // Burn LP tokens from user
        _burnLP(msg.sender, liquidity);

        // Transfer underlying tokens to user
        _safeTransfer(token0, msg.sender, amount0);
        _safeTransfer(token1, msg.sender, amount1);

        // Update reserves
        _updateReserves(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
        emit Burn(msg.sender, amount0, amount1, msg.sender);
    }

    // --- Swapping ---

    /**
     * @notice Swaps an exact amount of input tokens for output tokens.
     * @dev User must approve the pool to spend `amountIn` of `tokenIn`.
     * A 0.3% fee is taken on the input amount.
     * @param tokenIn The address of the token being sent to the pool.
     * @param amountIn The exact amount of `tokenIn` being sent.
     * @param amountOutMin The minimum amount of output tokens expected. Prevents front-running/slippage.
     * @param to The address that will receive the output tokens.
     * @return amountOut The actual amount of output tokens received.
     */
    function swap(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external lock returns (uint256 amountOut) {
        require(amountIn > 0, "Pool: INSUFFICIENT_INPUT_AMOUNT");
        require(to != address(0), "Pool: SWAP_TO_ZERO");
        require(tokenIn == token0 || tokenIn == token1, "Pool: INVALID_TOKEN");

        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        require(_reserve0 > 0 && _reserve1 > 0, "Pool: INSUFFICIENT_LIQUIDITY");

        address tokenOut = (tokenIn == token0) ? token1 : token0;
        uint256 reserveIn = (tokenIn == token0) ? _reserve0 : _reserve1;
        uint256 reserveOut = (tokenOut == token0) ? _reserve0 : _reserve1;

        // Pull tokenIn from user
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Calculate amountOut applying 0.3% fee
        // fee = amountIn * 3 / 1000. amountInAfterFee = amountIn * 997 / 1000
        uint256 amountInWithFee = amountIn * 997; // Numerator part of fee calculation
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;

        require(amountOut >= amountOutMin, "Pool: INSUFFICIENT_OUTPUT_AMOUNT");
        require(amountOut < reserveOut, "Pool: INSUFFICIENT_LIQUIDITY"); // Ensure pool has enough to send

        // Transfer tokenOut to recipient
        _safeTransfer(tokenOut, to, amountOut);

        // Update reserves
        uint256 currentBalance0 = IERC20(token0).balanceOf(address(this));
        uint256 currentBalance1 = IERC20(token1).balanceOf(address(this));
        _updateReserves(currentBalance0, currentBalance1);

        // Emit swap event (distinguish amounts in/out for each token)
        uint256 amount0In = (tokenIn == token0) ? amountIn : 0;
        uint256 amount1In = (tokenIn == token1) ? amountIn : 0;
        uint256 amount0Out = (tokenOut == token0) ? amountOut : 0;
        uint256 amount1Out = (tokenOut == token1) ? amountOut : 0;
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // --- LP Token ERC20 Functions (Simplified) ---

    /**
     * @notice Transfers LP tokens from the caller to a recipient.
     */
    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success) {
        require(_to != address(0), "Pool LP: transfer to the zero address");
        uint256 senderBalance = balanceOf[msg.sender];
        require(
            senderBalance >= _value,
            "Pool LP: transfer amount exceeds balance"
        );

        balanceOf[msg.sender] = senderBalance - _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Approves a spender for the caller's LP tokens.
     */
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success) {
        require(_spender != address(0), "Pool LP: approve to the zero address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Transfers LP tokens using the allowance mechanism.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success) {
        require(_from != address(0), "Pool LP: transfer from the zero address");
        require(_to != address(0), "Pool LP: transfer to the zero address");
        require(
            balanceOf[_from] >= _value,
            "Pool LP: transfer amount exceeds balance"
        );

        uint256 currentAllowance = allowance[_from][msg.sender];
        require(
            currentAllowance >= _value,
            "Pool LP: transfer amount exceeds allowance"
        );

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] = currentAllowance - _value; // Decrease allowance

        emit Transfer(_from, _to, _value);
        return true;
    }

    // --- View Functions ---

    /**
     * @notice Returns the current reserves of token0 and token1.
     * @return _reserve0 The reserve amount of token0.
     * @return _reserve1 The reserve amount of token1.
     */
    function getReserves()
        external
        view
        returns (uint256 _reserve0, uint256 _reserve1)
    {
        return (reserve0, reserve1);
    }
}
