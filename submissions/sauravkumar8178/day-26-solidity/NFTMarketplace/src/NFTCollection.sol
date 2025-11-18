// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/common/ERC2981.sol";
import "openzeppelin/utils/Counters.sol";

contract NFTCollection is ERC721, ERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string private _baseTokenURI;

    event Minted(address indexed to, uint256 indexed tokenId);

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        _baseTokenURI = baseURI_;
    }

    function mint(address to, uint96 royaltyBps) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        if (royaltyBps > 0) {
            // set per-token royalty (bps)
            _setTokenRoyalty(tokenId, owner(), royaltyBps);
        }
        emit Minted(to, tokenId);
        return tokenId;
    }

    // Owner can set default royalty for all tokens (bps / 10000)
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    // override supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // simple baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory newBase) external onlyOwner {
        _baseTokenURI = newBase;
    }
}
