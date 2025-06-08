// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LiquidityPool.sol";

/**
 * @title MiniDexFactory
 * @author shivam
 * @dev Factory contract to deploy and manage LiquidityPool instances for token pairs.
 * Ensures that only one pool exists per unique pair of tokens.
 */
contract MiniDexFactory {
    // --- State Variables ---

    /// @notice Mapping from token0 address => token1 address => pool address.
    /// Ensures canonical ordering (token0 < token1).
    mapping(address => mapping(address => address)) public getPool;

    /// @notice Array storing all created pool addresses.
    address[] public allPools;

    // --- Events ---

    /// @notice Emitted when a new liquidity pool is created.
    /// @param token0 The address of the first token in the pair (ordered).
    /// @param token1 The address of the second token in the pair (ordered).
    /// @param pool The address of the newly created liquidity pool.
    /// @param poolIndex The index of the pool in the allPools array.
    event PoolCreated(address indexed token0, address indexed token1, address indexed pool, uint256 poolIndex);

    // --- Functions ---

    /**
     * @notice Creates a liquidity pool for the given token pair if one doesn't already exist.
     * @dev Deploys a new LiquidityPool contract instance and initializes it.
     * Stores the pool address and emits a PoolCreated event.
     * @param tokenA The address of the first token.
     * @param tokenB The address of the second token.
     * @return pool The address of the newly created or existing liquidity pool for the pair.
     */
    function createPool(address tokenA, address tokenB) external returns (address pool) {
        require(tokenA != address(0) && tokenB != address(0), "Factory: ZERO_ADDRESS");
        require(tokenA != tokenB, "Factory: IDENTICAL_ADDRESSES");

        // Ensure consistent ordering of tokens
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // Check if pool already exists
        pool = getPool[token0][token1];

        if (pool == address(0)) {
            // Deploy a new LiquidityPool instance
            // The factory address is implicitly passed as msg.sender to the LiquidityPool constructor
            pool = address(new LiquidityPool());

            // Initialize the newly created pool
            LiquidityPool(pool).initialize(token0, token1);

            // Store the pool address in the mapping and array
            getPool[token0][token1] = pool;
            // Also store the reverse mapping for easier lookup if needed (optional)
            // getPool[token1][token0] = pool; // Uncomment if needed, but primary lookup uses ordered pair

            allPools.push(pool);
            uint256 poolIndex = allPools.length; // Index will be length before push + 1, but arrays are 0-indexed

            // Emit the event
            emit PoolCreated(token0, token1, pool, poolIndex - 1); // Use 0-based index
        }
        // If pool already existed, the existing address is returned
    }

    /**
     * @notice Returns the total number of pools created by the factory.
     * @return The count of pools in the allPools array.
     */
    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }
}