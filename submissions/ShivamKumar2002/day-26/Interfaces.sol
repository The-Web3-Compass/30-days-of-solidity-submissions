// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC165
 * @notice Interface for the ERC165 Standard.
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceId` and
     * `interfaceId` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @title IERC721
 * @notice Interface for the ERC721 Non-Fungible Token Standard.
 * @dev We only include the functions needed by the marketplace.
 */
interface IERC721 is IERC165 {
    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     * about them do throw.
     * @param tokenId The identifier for an NFT
     * @return owner The address of the owner of the NFT
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param tokenId The NFT to find the approved address for
     * @return operator The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     * operator, or the approved address for this NFT. Throws if `_from` is
     * not the current owner. Throws if `_to` is the zero address. Throws if
     * `_tokenId` is not a valid NFT.
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    // Note: We don't need the overloaded safeTransferFrom with data
    // Note: We don't need approve, setApprovalForAll, isApprovedForAll directly in the marketplace logic,
    // but the seller needs to call them on the NFT contract beforehand.
}

/**
 * @title IERC2981 Royalties
 * @notice Interface for the ERC2981 NFT Royalty Standard.
 * @dev https://eips.ethereum.org/EIPS/eip-2981
 */
interface IERC2981 is IERC165 {
    /**
     * @notice Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for salePrice
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}