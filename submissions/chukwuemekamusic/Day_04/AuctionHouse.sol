// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract AuctionHouse {
    error AuctionHouse_MissingCreationFields();
    error AuctionHouse_NotActive();
    error AuctionHouse_AuctionNotOpen();
    error AuctionHouse_AuctionClosed();
    error AuctionHouse_InvalidItemId(); //
    error AuctionHouse_InvalidEntry();
    error AuctionHouse_LowBid();
    error AuctionHouse_UnAuthorized();
    error AuctionHouse_AlreadyOpen();

    error AuctionHouse_AuctionNotEnded();
    error AuctionHouse_NoFundsToWithdraw();
    error AuctionHouse_AuctionAlreadySettled();
    error AuctionHouse_NoHighestBid();
    error AuctionHouse_FailedToSendEther();

    address immutable i_owner;

    struct Bid {
        address bidder;
        uint256 bidAmount;  
        uint256 timestamp; 
    }

    struct AuctionItem {
        uint256 id;
        uint256 startingPrice;
        string name;
        string description;
        uint256 auctionEndTime;
        uint256 durationInHours;
        address payable seller;
        bool isActive; // used to show if an item exists and not removed
        bool isOpenToAuction;
        bool isSettled;
        mapping(address => uint256) pendingReturns;
        Bid highestBid;
        //bytes32[] metadata;  // to store the image of item
        //string tokenURI;     /// link to the tokenized asset
    }

    uint256 itemCount;

    mapping(uint256 itemId => AuctionItem) items;

    event AuctionItemCreated(address indexed seller, uint256 indexed itemId, string name);
    event BidPlaced(uint256 itemId, address indexed bidder, uint256 bidAmount, uint256 highestBidSoFar);
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);
    event AuctionSettled(uint256 indexed itemId, address indexed winner, uint256 finalBid);

  
    
    constructor(){
            i_owner = msg.sender;
    }

    struct ItemData {
        string name;
        string description;
        uint256 startingPrice;
        uint256 duration_In_Hour;
        bool isOpenToAuction;
        //bytes32[] metadata;  // to store the image of item
        //string tokenURI;     /// link to the tokenized asset
    }

    function createAuctionItem(ItemData calldata _itemData) public returns (uint256) {
        if (
            _itemData.startingPrice == 0 || _itemData.duration_In_Hour == 0 || 
            bytes(_itemData.name).length == 0  || bytes(_itemData.description).length == 0
        ) revert AuctionHouse_MissingCreationFields();

        uint _newItemId = itemCount;

        AuctionItem storage newItem = items[_newItemId];
        newItem.id = _newItemId;
        newItem.name = _itemData.name;
        newItem.description = _itemData.description;
        newItem.startingPrice = _itemData.startingPrice;
        newItem.seller = payable(msg.sender);
        newItem.isActive = true;
        newItem.isSettled = false;
        newItem.isOpenToAuction = _itemData.isOpenToAuction;
        if (_itemData.isOpenToAuction == true) {
            newItem.auctionEndTime = block.timestamp + (_itemData.duration_In_Hour * 1 hours);
            newItem.durationInHours = _itemData.duration_In_Hour;
        } else if (_itemData.isOpenToAuction == false){
            newItem.auctionEndTime =  0;
        }
        
        ++itemCount;  
        emit AuctionItemCreated(msg.sender, _newItemId, newItem.name);
       return(_newItemId);
    } 

            // Helper modifier for item existence and validity checks
    modifier _validAuctionItem(uint256 _itemId) {
        if (_itemId >= itemCount) revert AuctionHouse_InvalidItemId(); // For 0-indexing
        AuctionItem storage item = items[_itemId];
        if (!item.isActive) revert AuctionHouse_NotActive(); // Item must be active (not removed)
        _;
    }

    function bidAuctionItem(uint256 _itemId) external payable {
        if (msg.value == 0 || _itemId > itemCount || _itemId < 0) revert AuctionHouse_InvalidEntry();
        AuctionItem storage item = items[_itemId];
        if (item.isActive != true) revert AuctionHouse_NotActive();
        if (!item.isOpenToAuction) revert AuctionHouse_AuctionNotOpen();
        if (block.timestamp > item.auctionEndTime) revert AuctionHouse_AuctionClosed();

        if (msg.value < item.startingPrice || msg.value <= item.highestBid.bidAmount) revert AuctionHouse_LowBid();


        // If there was a previous highest bidder (not the initial address(0))
        if (item.highestBid.bidder != address(0)) {
            item.pendingReturns[item.highestBid.bidder] += item.highestBid.bidAmount;
        }
        // set highest bidder
        item.highestBid = Bid(msg.sender, msg.value, block.timestamp);

        emit BidPlaced(_itemId, msg.sender, msg.value, item.highestBid.bidAmount);
    }



    // allow the item owner to set item up for auction -- this should adjust the duration
    function openItemToAuction(uint256 _itemId, uint256 _duration_In_Hours) public {
        if (_itemId > itemCount ||_itemId < 1 ) revert AuctionHouse_InvalidEntry();
        AuctionItem storage item = items[_itemId];
        if (msg.sender != address(item.seller)) revert AuctionHouse_UnAuthorized();

        if (!item.isActive) revert AuctionHouse_NotActive();
        if (item.isOpenToAuction) revert AuctionHouse_AlreadyOpen();
        if (item.isSettled) revert AuctionHouse_AuctionAlreadySettled();
        
        item.isOpenToAuction = true;
        item.auctionEndTime = block.timestamp +( _duration_In_Hours * 1 hours) ;
        item.durationInHours = _duration_In_Hours ;
        
    }

    // let the user know what the highest bidder is
    function getCurrentHighestBid(uint256 _itemId) external view returns (uint){
        AuctionItem storage item = items[_itemId];
         Bid memory currentBid = item.highestBid;
            return (currentBid.bidAmount);
    }

    // allow the bidders to pull back their funds
    function withdrawFunds(uint256 _itemId) external _validAuctionItem(_itemId){
        AuctionItem storage item = items[_itemId];
        uint256 amount = item.pendingReturns[msg.sender];

        if (amount == 0) revert AuctionHouse_NoFundsToWithdraw();

        item.pendingReturns[msg.sender] = 0; // Clear the balance first to prevent re-entrancy

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            item.pendingReturns[msg.sender] = amount; // Revert state change
            revert AuctionHouse_FailedToSendEther();
        }
        emit FundsWithdrawn(msg.sender, amount);
    }

    // allow the seller to end auction with current bid
    function endAuction() public {}


    function settleAuction() public {}

    // GETTERS
   function getItemDetails(uint256 _itemId) public view _validAuctionItem(_itemId) returns (
        uint256 id,
        string memory name,
        string memory description,
        uint256 startingPrice,
        uint256 durationInHours,
        uint256 auctionEndTime,
        address seller,
        bool isActive,
        bool isOpenToAuction,
        bool isSettled
        
    ) {
        AuctionItem storage item = items[_itemId];
        return (
            item.id,
            item.name,
            item.description,
            item.startingPrice,
            item.durationInHours,
            item.auctionEndTime,
            item.seller,
            item.isActive,
            item.isOpenToAuction,
            item.isSettled
        );
    }

    function getTimeRemaining(uint256 _itemId) public view returns (uint256) {
        AuctionItem storage item = items[_itemId];
        if (item.auctionEndTime == 0) return 0;
        return item.auctionEndTime - block.timestamp;
    }

}