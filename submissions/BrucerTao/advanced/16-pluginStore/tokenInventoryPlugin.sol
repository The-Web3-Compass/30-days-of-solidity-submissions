// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TokenInventoryPlugin: 查询 ERC-20 和 ERC-721 的持有情况
// 说明：
// - 提供常用的只读查询：ERC20 余额、ERC721 拥有校验、ERC721 余额
// - 可与前端或其他合约结合，直接调用查询，不更改现有插件逻辑
contract TokenInventoryPlugin {
    // 最简 ERC20 接口
    interface IERC20 {
        function balanceOf(address account) external view returns (uint256);
    }

    // 最简 ERC721 接口
    interface IERC721 {
        function ownerOf(uint256 tokenId) external view returns (address);
        function balanceOf(address owner) external view returns (uint256);
    }

    // 查询 ERC20 余额
    function getERC20Balance(address token, address user) external view returns (uint256) {
        require(token != address(0) && user != address(0), "Invalid address");
        return IERC20(token).balanceOf(user);
    }

    // 查询是否拥有某个 ERC721 代币
    function ownsERC721(address nft, address user, uint256 tokenId) external view returns (bool) {
        require(nft != address(0) && user != address(0), "Invalid address");
        address owner = IERC721(nft).ownerOf(tokenId);
        return owner == user;
    }

    // 查询持有的 ERC721 数量
    function getERC721Balance(address nft, address user) external view returns (uint256) {
        require(nft != address(0) && user != address(0), "Invalid address");
        return IERC721(nft).balanceOf(user);
    }
}