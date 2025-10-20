// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IERC165 {
    // Checks if contract supports an interface
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    // Returns NFT owner
    function ownerOf(uint256 tokenId) external view returns (address owner);

    // Returns approved address for NFT
    function getApproved(uint256 tokenId) external view returns (address operator);

    // Safely transfers NFT from one address to another
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC2981 is IERC165 {
    // returns royalty info for NFT sales
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}
