// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ERC-721 Non-Fungible Token Standard Interface
interface IERC721 {
    // 1. 事件定义
    /// @notice 转移NFT时触发（包括mint和burn）
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @notice 授权别人操作某个NFT时触发
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @notice 批量授权别人操作自己所有NFT时触发
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // 2. 必须实现的函数

    /// @notice 查询某个地址拥有的NFT数量
    function balanceOf(address owner) external view returns (uint256);

    /// @notice 查询某个NFT的拥有者
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice 授权别人操作某个NFT
    function approve(address to, uint256 tokenId) external;

    /// @notice 查询某个NFT被授权给了谁
    function getApproved(uint256 tokenId) external view returns (address);

    /// @notice 批量授权别人操作自己所有NFT
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice 查询某人是否被授权操作另一个人的所有NFT
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice 转移NFT（不检查接收方是否能接收NFT）
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice 安全转移NFT（检查接收方是否能接收NFT）
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @notice 安全转移NFT（带额外数据参数）
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


/// @title ERC-721 Token Receiver Interface
interface IERC721Receiver {
    /**
     * @notice 当NFT通过safeTransferFrom转账到合约时自动调用
     * @param operator 谁发起的转账
     * @param from NFT原持有者
     * @param tokenId 被转移的NFT编号
     * @param data 附加数据
     * @return 返回特定的selector，表示合约能接收NFT
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
