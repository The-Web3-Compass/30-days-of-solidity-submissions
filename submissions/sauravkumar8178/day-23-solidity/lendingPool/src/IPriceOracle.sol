// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPriceOracle {
    /// @notice returns price with 18 decimals (e.g., 1 ETH => 1e18)
    function getPrice(address token) external view returns (uint256);
}
