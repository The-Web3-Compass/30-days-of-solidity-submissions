//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketPlace is ReentrancyGuard {
    address owner;
    address marketplaceFeeRecepient; // 市场手续费接收者
    uint256 marketplaceFeePercent; // 基点 in basis points(100 = 1%)

    struct Listing {
        address sellerAddress;
        address ntfAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver; // 版税接收者
        uint256 royaltyPercent; // in basis points
        bool isListed;
    }
    mapping(address => mapping(uint256 => Listing)) listings; // nft address =>(nft token id => Listing)

    event MarketplaceFeeUpdated(address recepient, uint256 percent);
    event listingCreated(
        address seller, 
        address nft, 
        uint256 id, 
        uint256 price, 
        address royaltyReceicer, 
        uint256 royaltyPercent
    );
    event listingCancelled(
        address seller,
        address nft,
        uint256 id
    );
    event NFTPurchased(
        address buyer,
        address seller,
        address nft,
        uint256 id,
        uint256 price,
        address royaltyReceicer,
        uint256 royaltyAmount,
        uint256 marketplaceAmount
    );

    constructor(address _marketplaceFeeRecepient, uint256 _marketplaceFeePercent) {
        require(address(0) != _marketplaceFeeRecepient, "Invalid address");
        require(_marketplaceFeePercent < 1000, "Marketplace fee too high(max 10%)");

        owner = msg.sender;
        marketplaceFeeRecepient = _marketplaceFeeRecepient;
        marketplaceFeePercent = _marketplaceFeePercent;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function setMarketplaceFeeRecepient(address _marketplaceFeeRecepient) external onlyOwner {
        marketplaceFeeRecepient = _marketplaceFeeRecepient;
        emit MarketplaceFeeUpdated(marketplaceFeeRecepient, marketplaceFeePercent);
    }

    function setMarketplaceFeePercent(uint256 _marketplaceFeePercent) external onlyOwner {
        marketplaceFeePercent = _marketplaceFeePercent;
        emit MarketplaceFeeUpdated(marketplaceFeeRecepient, marketplaceFeePercent);
    }   

    function listNFT(
        address _nftAddress, 
        uint256 _id, 
        uint256 _price, 
        address _royaltyAddress, 
        uint256 _royaltyPercent
    ) external {
        require(address(0) != _nftAddress && address(0) != _royaltyAddress, "Invalid address");
        require(_price > 0, "Price should be greater than 0");
        require(_royaltyPercent <= 1000, "Royalty fee too high(max 10%)");
        require(!listings[msg.sender][_id].isListed, "Already listed");

        IERC721 nft = IERC721(_nftAddress);
        require(msg.sender == nft.ownerOf(_id), "You are not the owner");
        require(nft.getApproved(_id) == address(this) || 
                nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");
        
        listings[_nftAddress][_id] = Listing(msg.sender, _nftAddress, _id, _price, _royaltyAddress, _royaltyPercent, true);
        emit listingCreated(msg.sender, _nftAddress, _id, _price, _royaltyAddress, _royaltyPercent);
    }

    function cancelListing(address _nftAddress, uint256 _id) external {
        require(address(0) != _nftAddress, "Invalid address");
        Listing memory listing = listings[msg.sender][_id];
        require(listing.isListed, "Not listed");
        require(msg.sender == listing.sellerAddress, "You are not the seller");

        delete listings[_nftAddress][_id];
        emit listingCancelled(msg.sender, _nftAddress, _id);
    }

    function buyNFT(address _nftAddress, uint256 _id) external payable nonReentrant {
        require(address(0) != _nftAddress, "Invalid address");

        Listing memory listing = listings[msg.sender][_id];
        require(listing.isListed, "Not listed");
        require(msg.value == listing.price, "Not enough ETH to buy");
        require(listing.royaltyPercent + marketplaceFeePercent < 10000, "Combined fee exceed 100%");

        // 计算市场手续费，版权费，给买家的金额
        uint256 marketplaceFeeAmount = msg.value * marketplaceFeePercent / 10000;
        uint256 royaltyFeeAmount = msg.value * listing.royaltyPercent / 10000;
        uint256 payToSeller = listing.price - marketplaceFeeAmount - royaltyFeeAmount;

        delete listings[_nftAddress][_id];

        // 转账给市场平台，版权所有人，买家
        if (marketplaceFeeAmount > 0) {
            payable(marketplaceFeeRecepient).transfer(marketplaceFeeAmount);
        }
        if (royaltyFeeAmount > 0 && address(0) != listing.royaltyReceiver) {
            payable(listing.royaltyReceiver).transfer(royaltyFeeAmount);
        }
        payable(listing.sellerAddress).transfer(payToSeller);
        IERC721(_nftAddress).safeTransferFrom(listing.sellerAddress, msg.sender, _id);

        emit NFTPurchased(
            msg.sender, 
            listing.sellerAddress, 
            _nftAddress, 
            _id, 
            listing.price, 
            listing.royaltyReceiver, 
            royaltyFeeAmount, 
            marketplaceFeeAmount
        );
    }

    function getListing(address _nftAddress, uint256 _id) external view returns(Listing memory) {
        return listings[_nftAddress][_id];
    }

    receive() external payable {
        revert("Direct ETH not accepted");
    }

    fallback() external payable {
        revert("Unknown function");
    }
}