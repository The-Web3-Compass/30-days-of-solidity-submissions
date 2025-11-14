// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    address public owner;
    uint256 public marketplaceFeePercent;
    address public feeRecipient;

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver;
        uint256 royaltyPercent;
        bool isListed;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    );

    event NFTPurchased(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address royaltyReceiver,
        uint256 royaltyAmount,
        uint256 marketplaceFeeAmount
    );

    event NFTUnlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event FeeUpdated(
        uint256 newMarketplaceFee,
        address newFeeRecipient
    );

    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Invalid fee.");
        require(_feeRecipient != address(0), "Invalid fee recipient.");
        
        owner = msg.sender;
        marketplaceFeePercent = _marketplaceFeePercent;
        feeRecipient = _feeRecipient;
    }
       

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this operation.");
        _;
    }

    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Invalid fee.");
        
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid recipient.");
       
        feeRecipient = _newRecipient;
        emit FeeUpdated(marketplaceFeePercent, _newRecipient);
    }

    function listNFT(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    ) external {
        require(price > 0, "Invalid price.");
        require(royaltyPercent <= 1000, "Invalid royalty percent.");
        require(!listings[nftAddress][tokenId].isListed, "Already listed");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );
        listings[msg.sender][tokenId] = Listing(msg.sender,
                                                nftAddress,
                                                tokenId,
                                                price,
                                                royaltyReceiver,
                                                royaltyPercent,
                                                true);
        emit NFTListed(msg.sender, nftAddress, tokenId, price, royaltyReceiver, royaltyPercent);

    }

    function buyNFT(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.isListed, "Not listed");
        require(msg.value == listing.price, "Incorrect payment amount");
        require(
            listing.royaltyPercent + marketplaceFeePercent <= 10000,
            "Combined fees exceed 100%"
        );

        uint256 fee = (msg.value * marketplaceFeePercent) / 10000;
        uint256 royalty = (msg.value * listing.royaltyPercent) / 10000;
        uint256 payoutToSeller = msg.value - fee - royalty;


        if (fee > 0) 
            payable(feeRecipient).transfer(fee);

        if (royalty > 0 && listing.royaltyReceiver != address(0)) 
            payable(listing.royaltyReceiver).transfer(royalty);

        payable(listing.seller).transfer(payoutToSeller);

        IERC721(listing.nftAddress).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        delete listings[nftAddress][tokenId];

        emit NFTPurchased(
            msg.sender,
            nftAddress,
            tokenId,
            msg.value,
            listing.seller,
            listing.royaltyReceiver,
            royalty,
            fee
        );
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        require(nftAddress != address(0), "Invalid NFT address.");
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.isListed, "Not listed");
        require(listing.seller == msg.sender, "Only seller can cancel their listing.");
       
        delete listings[nftAddress][tokenId];
        emit NFTUnlisted(msg.sender, nftAddress, tokenId);
    }

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        require(nftAddress != address(0), "Invalid NFT address.");
        return listings[nftAddress][tokenId];
    }

    receive() external payable {
        revert("Direct payment not accepted.");
    }

    fallback() external payable {
        revert("Unknown function");
    }
}

