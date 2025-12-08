// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

/**
 * @title TokenInventoryPlugin
 * @dev Reads player token/NFT holdings. Purely view-based plugin.
 */
contract TokenInventoryPlugin {
    /// @notice Get ERC-20 token balance for a player.
    function getERC20Balance(address user, address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(user);
    }

    /// @notice Get ERC-721 (NFT) balance for a player.
    function getNFTBalance(address user, address nftAddress) public view returns (uint256) {
        return IERC721(nftAddress).balanceOf(user);
    }
}
