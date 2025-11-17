//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

// Build an online market.

// This contract is a fully on-chain NFT marketplace, it lets people:
// 1. List NFTs for sale,setting a price and even a custom royalty;
// 2. Buy NFTs by sending ETH directly to the contract;
// 3. Automatically split the sale between the seller, the creator(for royalties) and the platform(for market fees);
// 4. Cancel listings anytime;
// 5. Update fee settings as the marketplace owner.
// All of this happen safely with built-in protections like ReentrancyGuard.

// Interface of ERC-721.
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// This is a security tool that helps protect the contract from a common type of hack called a reentrancy attack.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard{
    address public owner;
    // This sets the fee percentage the marketplace will take from each sale --- but in basis points.
    // This fee is for the NFT transaction system running, like cost for servers, databases, indexing and so on.
    uint256 public marketplaceFeePercent;
    // This is the wallet that receives the market share from every NFT sale.
    address public feeRecipient;

    // This struct list information for a single NFT.
    struct Listing{
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        address royaltyReceiver;// Optional: the address should receive creator royalties from this sale.
        uint256 royaltyPercent;
        bool isListed;
    }

    mapping(address=>mapping(uint256=>Listing)) public listings; // NFT address=>token ID=>information of NFT

    // Emitted when an NFT is listed for sale.
    event Listed(address indexed seller,address indexed nftAddress, uint256 indexed tokenId,uint256 price,address royaltyReceiver,uint256 royaltyPercent);
    // Emitted when someone buys an NFT.
    event Purchase(address indexed buyer,address indexed nftAddress,uint256 indexed tokenId,uint256 price,address seller,address royaltyReceiver,uint256 royaltyAmount,uint256 marketplaceFeeAmount);
    event Unlisted(address indexed seller,address indexed nftAddress,uint256 indexed tokenId);
    // Logged when the marketplace owner changes fee settings.
    event FeeUpdated(uint256 mewMarketplaceFee,address newFeeRecipient);

    // Set the percent of fee the marketplace would take and decide which wallet these fees would go.
    constructor(uint256 _marketplaceFeePercent,address _feeRecipient){
        // 1000=10%, 500=5%, 250=2.5%
        require(_marketplaceFeePercent<=1000,"Marketplace fee too high(max 10%)");
        require(_feeRecipient!=address(0),"Fee recipient cannot be zero");

        owner=msg.sender;
        marketplaceFeePercent=marketplaceFeePercent;
        feeRecipient=_feeRecipient;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Only owner");
        _;
    }

    function setMarketplaceFeePercent(uint256 _newFee) external onlyOwner{
        require(_newFee<=1000,"Market fee too high");
        marketplaceFeePercent=_newFee;
        emit FeeUpdated(_newFee,feeRecipient);

    }

    // The fee recipient is the address that receives marketplace's share of every sale.
    // The fee recipient might be a founder's wallet, a DAO treasury, a multisig managed by a team and a smart contract that splits revenue further.
    function setFeeRecipient(address _newRecipient) external onlyOwner{
        require(_newRecipient!=address(0),"Invalid fee recipient");
        feeRecipient=_newRecipient;
        emit FeeUpdated(marketplaceFeePercent,_newRecipient);

    }
    
    // This function allows any user to list an NFT they own for sale in the market.
    function listNFT(address nftAddress, uint256 tokenId,uint256 price, address royaltyReceiver,uint256 royaltyPercent) external{
        require(price>0,"Price must be above zero");
        require(royaltyPercent<=1000,"Max 10% royalty allowed");
        require(!listings[nftAddress][tokenId].isListed,"Already listed");

        IERC721 nft=IERC721(nftAddress);
        // Check the caller actually owns the NFT.
        require(nft.ownerOf(tokenId)==msg.sender,"Not the owner");
        // Check the marketplace is approved to transfer the NFT on the user's behalf.
        require(nft.getApproved(tokenId)==address(this)||nft.isApprovedForAll((msg.sender),address(this)),"Marketplace not approved");
        listings[nftAddress][tokenId]=Listing({seller:msg.sender,nftAddress:nftAddress,tokenId:tokenId,price:price,royaltyReceiver:royaltyReceiver,royaltyPercent:royaltyPercent,isListed:true});
        emit Listed(msg.sender,nftAddress,tokenId,price,royaltyReceiver,royaltyPercent);

    }

    // This function:
    // Accepts ETH from a buyer;
    // Splits it between the seller, the creator(for royalties) and the platform(as a fee);
    // Transfers the NFT to the buyer;
    // Deletes the listing;
    // Emits an event to let the world know a purchase happened.
    function buyNFT(address nftAddress,uint256 tokenId) external payable nonReentrant{
        Listing memory item=listings[nftAddress][tokenId];
        require(item.isListed,"Not listed");
        require(msg.value==item.price,"Incorrect ETH sent");
        // 10000=100%
        // The total percent sum of royalty and fee for marketplace can not be higher than 100%
        require(item.royaltyPercent+marketplaceFeePercent<=10000,"Combined fees exceed 100%");

        uint256 feeAmount=(msg.value*marketplaceFeePercent)/10000;
        uint256 royaltyAmount=(msg.value*item.royaltyPercent)/10000;
        uint256 sellerAmount=msg.value-feeAmount-royaltyAmount;

        if(feeAmount>0){
            payable(feeRecipient).transfer(feeAmount);
        }

        if(royaltyAmount>0&&item.royaltyReceiver!=address(0)){
            payable(item.royaltyReceiver).transfer(royaltyAmount);
        }

        payable(item.seller).transfer(sellerAmount);

        // The contract moves the NFT from the seller to the buyer using the standard ERC-721 transfer function.
        IERC721(item.nftAddress).safeTransferFrom(item.seller,msg.sender,item.tokenId);

        delete listings[nftAddress][tokenId];

        emit Purchase(msg.sender,nftAddress,tokenId,msg.value,item.seller,item.royaltyReceiver,royaltyAmount,feeAmount);

    }

    // Remove an NFT from sale.
    function cancelListing(address nftAddress,uint256 tokenId) external{
        Listing memory item=listings[nftAddress][tokenId];
        require(item.isListed,"Not listed");
        require(item.seller==msg.sender,"Not the seller");

        delete listings[nftAddress][tokenId];
        emit Unlisted(msg.sender,nftAddress,tokenId);

    }

    function getListing(address nftAddress,uint256 tokenId) external view returns(Listing memory){
        return listings[nftAddress][tokenId];

    }

    // This function is triggered when someone send ETH directly to the contract without calling a function.
    receive() external payable{
        revert("Direct ETH not accepted");
    }

    // Someone calls a function that doesn't exist in this contract.
    // Or sends ETH without triggering "receive()".
    fallback() external payable{
        revert("Unknown function");

    }
}