// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MiniDexPair.sol";

/// @title  MiniDexFactory
/// @author rainwaters11 — Day 30: The Final Build (Mini DEX)
/// @notice Deploys and indexes MiniDexPair contracts.
///
/// @dev    Key design decisions:
///
///         TOKEN SORTING — `createPair` always stores the pair under the
///         canonical key  (token0, token1)  where  token0 < token1  (by
///         address value).  This means there is exactly ONE pool per
///         ordered pair of ERC-20 tokens — calling createPair(A, B) and
///         createPair(B, A) returns the same pool address, preventing
///         liquidity fragmentation across duplicate pools.
///
///         PAIR REGISTRY — The `getPair` mapping and `allPairs` array give
///         integrators two ways to discover pools: by token addresses or
///         by sequential index.
///
///         ACCESS CONTROL — Any address may create a pair; no owner is
///         required.  A `feeTo` address (initially zero) is reserved for
///         future protocol-fee collection and can only be changed by
///         `feeToSetter`, who is set at construction time.
contract MiniDexFactory {

    // ─── State ────────────────────────────────────────────────────────────────

    /// @notice Returns the pair address for a canonical (token0, token1) key.
    ///         Always look up with  token0 < token1.
    ///         Returns address(0) if the pair has not been created yet.
    mapping(address => mapping(address => address)) public getPair;

    /// @notice All pairs ever created, in creation order.
    address[] public allPairs;

    /// @notice Address that will receive protocol fees (zero = fees off).
    address public feeTo;

    /// @notice Only this address can update `feeTo`.
    address public feeToSetter;

    // ─── Events ───────────────────────────────────────────────────────────────

    /// @notice Emitted when a new pair is deployed.
    /// @param token0       Lower-address token.
    /// @param token1       Higher-address token.
    /// @param pair         Address of the newly deployed MiniDexPair.
    /// @param totalPairs   Length of `allPairs` after this creation.
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address         pair,
        uint256         totalPairs
    );

    // ─── Errors ───────────────────────────────────────────────────────────────

    error IdenticalTokens();
    error ZeroAddress();
    error PairAlreadyExists(address existingPair);
    error Forbidden();

    // ─── Constructor ──────────────────────────────────────────────────────────

    constructor(address _feeToSetter) {
        if (_feeToSetter == address(0)) revert ZeroAddress();
        feeToSetter = _feeToSetter;
    }

    // ─── Core factory logic ───────────────────────────────────────────────────

    /// @notice Deploy a new MiniDexPair for `tokenA` and `tokenB`.
    ///
    /// @dev    TOKEN SORTING — The function sorts tokens so that
    ///         token0 < token1 (by uint160 cast of the address).  This
    ///         canonical ordering ensures there is never more than one
    ///         pool for a given pair, regardless of the argument order
    ///         the caller uses.
    ///
    ///         Example:
    ///           createPair(WATERS, WETH) → same pool as createPair(WETH, WATERS)
    ///
    /// @param  tokenA  One of the two ERC-20 tokens.
    /// @param  tokenB  The other ERC-20 token.
    /// @return pair    Address of the newly deployed MiniDexPair.
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        // ── Validate inputs ────────────────────────────────────────────────────
        if (tokenA == tokenB) revert IdenticalTokens();
        if (tokenA == address(0) || tokenB == address(0)) revert ZeroAddress();

        // ── Sort tokens: token0 < token1 ──────────────────────────────────────
        //
        //   Casting addresses to uint160 gives a stable total order.
        //   The lower address becomes token0 so the canonical key is always
        //   getPair[token0][token1] with token0 < token1.
        //
        (address token0, address token1) = uint160(tokenA) < uint160(tokenB)
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        // ── Guard against duplicate pools ──────────────────────────────────────
        address existing = getPair[token0][token1];
        if (existing != address(0)) revert PairAlreadyExists(existing);

        // ── Deploy the pair ────────────────────────────────────────────────────
        //
        //   We pass token0 and token1 in sorted order so the MiniDexPair
        //   constructor stores them that way internally — callers can always
        //   rely on pair.token0() < pair.token1().
        //
        pair = address(new MiniDexPair(token0, token1));

        // ── Register in both directions so lookups work regardless of arg order.
        //   The canonical record lives at [token0][token1]; the reverse entry
        //   is a convenience alias pointing to the same address.
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;   // convenience reverse lookup

        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // ─── Views ────────────────────────────────────────────────────────────────

    /// @notice Returns the total number of pairs created by this factory.
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    // ─── Fee administration ───────────────────────────────────────────────────

    /// @notice Update the protocol fee recipient.
    ///         Only callable by `feeToSetter`.
    function setFeeTo(address _feeTo) external {
        if (msg.sender != feeToSetter) revert Forbidden();
        feeTo = _feeTo;
    }

    /// @notice Transfer the fee-setter role to a new address.
    ///         Only callable by the current `feeToSetter`.
    function setFeeToSetter(address _feeToSetter) external {
        if (msg.sender != feeToSetter) revert Forbidden();
        if (_feeToSetter == address(0)) revert ZeroAddress();
        feeToSetter = _feeToSetter;
    }
}
