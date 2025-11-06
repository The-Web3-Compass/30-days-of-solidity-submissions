// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title MyNFT
 * @dev An NFT contract supporting ERC2981 royalties.
 */
contract MyNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    address private _royaltyRecipient;
    uint96 private _royaltyBps; // Basis points, e.g., 500 for 5%

    constructor(address initialOwner, address royaltyRecipient, uint96 royaltyBps)
        ERC721("Marketplace NFT", "MNFT")
        Ownable(initialOwner)
    {
        _royaltyRecipient = royaltyRecipient;
        _royaltyBps = royaltyBps;
    }

    function mint(address to) public onlyOwner {
        _safeMint(to, ++_tokenIdCounter);
    }
    
    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyRecipient, (_salePrice * _royaltyBps) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}


/**
 * @title NFTMarketplace
 * @dev A marketplace for buying and selling NFTs.
 */
contract NFTMarketplace is Ownable {
    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event ItemListed(address indexed nft, uint256 indexed tokenId, uint256 price, address indexed seller);
    event ItemSold(address indexed nft, uint256 indexed tokenId, address indexed buyer, uint256 price);
    event ItemUnlisted(address indexed nft, uint256 indexed tokenId);

    constructor() Ownable(msg.sender) {}

    function listItem(address _nftAddress, uint256 _tokenId, uint256 _price) external {
        require(_price > 0, "Price must be positive");
        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not the owner");
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");

        listings[_nftAddress][_tokenId] = Listing(_price, msg.sender);
        emit ItemListed(_nftAddress, _tokenId, _price, msg.sender);
    }

    function buyItem(address _nftAddress, uint256 _tokenId) external payable {
        Listing memory currentListing = listings[_nftAddress][_tokenId];
        require(currentListing.price > 0, "Not listed");
        require(msg.value == currentListing.price, "Incorrect price");

        delete listings[_nftAddress][_tokenId];

        IERC721 nft = IERC721(_nftAddress);
        nft.transferFrom(currentListing.seller, msg.sender, _tokenId);

        _handleRoyalties(_nftAddress, _tokenId, currentListing.price, currentListing.seller);

        emit ItemSold(_nftAddress, _tokenId, msg.sender, currentListing.price);
    }

    function cancelListing(address _nftAddress, uint256 _tokenId) external {
        Listing memory currentListing = listings[_nftAddress][_tokenId];
        require(currentListing.seller == msg.sender, "Not the seller");
        
        delete listings[_nftAddress][_tokenId];
        emit ItemUnlisted(_nftAddress, _tokenId);
    }
    
    function _handleRoyalties(address _nftAddress, uint256 _tokenId, uint256 _salePrice, address _seller) private {
        try IERC2981(_nftAddress).royaltyInfo(_tokenId, _salePrice) returns (address receiver, uint256 royaltyAmount) {
            if (receiver != address(0) && royaltyAmount > 0) {
                payable(receiver).transfer(royaltyAmount);
                payable(_seller).transfer(_salePrice - royaltyAmount);
            } else {
                payable(_seller).transfer(_salePrice);
            }
        } catch {
            payable(_seller).transfer(_salePrice);
        }
    }
}
