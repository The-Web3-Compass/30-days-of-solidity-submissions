// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract NFTMarketplace is ReentrancyGuard {
    address public owner;
    uint256 public marketplaceFeePercent; // basis points (100 = 1%)
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

    event Listed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercent
    );

    event Purchase(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address royaltyReceiver,
        uint256 royaltyAmount,
        uint256 marketplaceFeeAmount
    );

    event Unlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event FeeUpdated(
        uint256 newMarketplaceFee,
        address newFeeRecipient
    );

    event PriceUpdated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 oldPrice,
        uint256 newPrice
    );

    constructor(uint256 _marketplaceFeePercent, address _feeRecipient) {
        require(_marketplaceFeePercent <= 1000, "Max 10%");
        require(_feeRecipient != address(0), "Invalid fee receiver");

        owner = msg.sender;
        marketplaceFeePercent = _marketplaceFeePercent;
        feeRecipient = _feeRecipient;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Max 10%");
        marketplaceFeePercent = _newFee;
        emit FeeUpdated(_newFee, feeRecipient);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid");
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
        require(price > 0, "Invalid price");
        require(royaltyPercent <= 1000, "Max 10% royalty");
        require(!listings[nftAddress][tokenId].isListed, "Already listed");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
        require(
            nft.getApproved(tokenId) == address(this) ||
            nft.isApprovedForAll(msg.sender, address(this)),
            "Approve marketplace"
        );

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            royaltyReceiver: royaltyReceiver,
            royaltyPercent: royaltyPercent,
            isListed: true
        });

        emit Listed(
            msg.sender,
            nftAddress,
            tokenId,
            price,
            royaltyReceiver,
            royaltyPercent
        );
    }
    
    function updateListingPrice(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external {
        Listing storage item = listings[nftAddress][tokenId];

        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not seller");
        require(newPrice > 0, "Price > 0");

        uint256 oldPrice = item.price;
        item.price = newPrice;

        emit PriceUpdated(nftAddress, tokenId, oldPrice, newPrice);
    }

    function buyNFT(address nftAddress, uint256 tokenId)
        external
        payable
        nonReentrant
    {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(msg.value == item.price, "Incorrect ETH sent");
        require(
            item.royaltyPercent + marketplaceFeePercent <= 10000,
            "Fee overflow"
        );

        uint256 feeAmount = (msg.value * marketplaceFeePercent) / 10000;
        uint256 royaltyAmount = (msg.value * item.royaltyPercent) / 10000;
        uint256 sellerAmount = msg.value - feeAmount - royaltyAmount;

        if (feeAmount > 0) {
            payable(feeRecipient).transfer(feeAmount);
        }

        if (royaltyAmount > 0 && item.royaltyReceiver != address(0)) {
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }

        payable(item.seller).transfer(sellerAmount);

        IERC721(item.nftAddress).safeTransferFrom(
            item.seller,
            msg.sender,
            item.tokenId
        );

        delete listings[nftAddress][tokenId];

        emit Purchase(
            msg.sender,
            nftAddress,
            tokenId,
            msg.value,
            item.seller,
            item.royaltyReceiver,
            royaltyAmount,
            feeAmount
        );
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.isListed, "Not listed");
        require(item.seller == msg.sender, "Not seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender, nftAddress, tokenId);
    }

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[nftAddress][tokenId];
    }

    receive() external payable {
        revert("Direct ETH not accepted");
    }

    fallback() external payable {
        revert("Invalid call");
    }
}
