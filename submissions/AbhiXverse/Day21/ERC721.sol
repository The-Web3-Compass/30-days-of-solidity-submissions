// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// interfaces for ERC721 standard
interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId); // Emitted on NFT transfer
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId); // Emitted when token approval changes
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved); // Emitted when operator approval changes

    function balanceOf(address _owner) external view returns (uint256); // Returns total NFTs owned by address
    function ownerOf(uint256 _tokenId) external view returns (address); // Returns owner of given NFT

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable; // Safely transfers NFT with data
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable; // Safely transfers NFT without data
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable; // Transfers NFT (not safe)

    function approve(address _approved, uint256 _tokenId) external payable; // Approves another address to transfer the given NFT
    function setApprovalForAll(address _operator, bool _approved) external; // Approves or revokes an operator for all caller's NFTs

    function getApproved(uint256 _tokenId) external view returns (address); // Returns approved address for given NFT
    function isApprovedForAll(address _owner, address _operator) external view returns (bool); // Checks if operator is approved for owner
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool); // Checks if interface is supported
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4); // Handles safe transfers
}

interface ERC721Metadata {
    function name() external view returns (string memory _name); // Returns token collection name
    function symbol() external view returns (string memory _symbol); // Returns token symbol
    function tokenURI(uint256 _tokenId) external view returns (string memory); // Returns token metadata URI
}
