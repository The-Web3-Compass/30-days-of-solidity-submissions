// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    address public owner;
    uint public marketplaceFeePercent;  //in basis points -> 100 = 1%
    address public feeRecipient;

    struct Listing{
        address seller;
        address nftAddress;
        uint tokenId;
        uint price;
        address royaltyReceiver;
        uint royaltyPercent;
        bool isListed;
    }

    mapping(address => mapping (uint => Listing)) public listings;  // nft address -> tokeId -> Listing

    event Listed(
        address indexed seller, 
        address indexed nftAddress, 
        uint indexed tokenId, 
        uint price, 
        address royaltyReceiver, 
        uint royaltyPercent
    );
    event Purchased(
        address indexed buyer, 
        address indexed nftAddress, 
        uint indexed tokenId, 
        uint price, 
        address seller,
        address royaltyReceiver, 
        uint royaltyAmount,
        uint marketplaceFeeAmount
    );
    event Unlisted(
        address indexed seller,
        uint indexed tokenId,
        address indexed nftAddress
    );
    event FeeUpdated(
        uint newMarketplaceFee,
        address newFeeRecepient
    );

    constructor(uint _marketFeePercent, address _feeRecipient){
        require(_marketFeePercent <= 1000, "marketplace fee is too high");
        require(_feeRecipient != address(0), "recipient address must not be 0");
        owner = msg.sender;
        marketplaceFeePercent = _marketFeePercent;
        feeRecipient = _feeRecipient;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "not authorized");
        _;
    }

    function setMarketplaceFeePercent(uint _newFee) external onlyOwner(){
        require(_newFee <= 1000, "new fee is too high");
        marketplaceFeePercent = _newFee;

        emit FeeUpdated(_newFee, feeRecipient);
    }

    function setFeeRecipient(address _newFeeRecipient) external onlyOwner(){
        require(_newFeeRecipient != address(0), "recipient address must not be 0");

        feeRecipient = _newFeeRecipient;
        emit FeeUpdated(marketplaceFeePercent, feeRecipient);
    }

    function listNFT(address _nftAddress,uint _tokenId, uint _price, address _royaltyReceiver, uint _royaltyPercent) external {
        require(_price > 0 , "nft price must be greater than 0");
        require(_royaltyReceiver != address(0), "xero adress of royalty receiver");
        require(_royaltyPercent <= 1000, "max 10% royalty fee is allowed");
        require(!listings[_nftAddress][_tokenId].isListed);

        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "not the owner");
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "marketplace isnt approved");

        listings[_nftAddress][_tokenId] = Listing({
            seller: msg.sender,
            nftAddress: _nftAddress,
            royaltyReceiver: _royaltyReceiver,
            royaltyPercent: _royaltyPercent,
            price: _price,
            tokenId: _tokenId,
            isListed: true
        });

        emit Listed(msg.sender, _nftAddress, _tokenId, _price, _royaltyReceiver, _royaltyPercent);
    }

    function purchaseNFT(address _nftAddress, uint _tokenId) external payable nonReentrant {
        Listing memory item = listings[_nftAddress][_tokenId];
        require(item.isListed, "this nft isnt listed");
        require(msg.value == item.price, "invalid amount paid");
        require(marketplaceFeePercent + item.royaltyPercent <= 1000, "combined fee should be less than 10%");

        uint feeAmount = (msg.value * marketplaceFeePercent)/10000;
        uint royaltyAmount = (msg.value * item.royaltyPercent)/10000;
        uint sellerAmount = msg.value - royaltyAmount - feeAmount;

        if(feeAmount > 0){
            payable(feeRecipient).transfer(feeAmount);
        }
        if(royaltyAmount > 0 && item.royaltyReceiver != address(0)){
            payable(item.royaltyReceiver).transfer(royaltyAmount); 
        }
        payable(item.seller).transfer(sellerAmount);
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);
        delete listings[_nftAddress][_tokenId];

        emit Purchased(msg.sender, _nftAddress, _tokenId, item.price, item.seller, item.royaltyReceiver, royaltyAmount, feeAmount);
    }

    function CancelListing(address _nftAddress, uint _tokenId) external {
        Listing memory item = listings[_nftAddress][_tokenId];
        require(item.isListed, "this nft isnt listed");
        require(item.seller == msg.sender, "tu hai kon");

        delete listings[_nftAddress][_tokenId];

        emit Unlisted(msg.sender, _tokenId, _nftAddress);

    }

    function getListing(address _nftAddress, uint _tokenId) external view returns(Listing memory){
        return listings[_nftAddress][_tokenId];
    }

    receive() external payable {
       revert("direct eth not accepted");
    }

    fallback() external payable {
       revert("function does not exist");
    }

}