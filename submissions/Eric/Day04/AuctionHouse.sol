// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
/**
 * @title Simple Auction House Smart Contract
 * @author Eric (https://github.com/0xxEric)
 * @notice A decentralized auction system for managing item bids and settlements
 * @custom:project 30-days-of-solidity-submissions: Day04
 */
contract AuctionHouse {
    address public immutable admin;

    struct BidItem{
        string itemName; 
        uint256 floorPrice;
        uint256 highestPrice;
        address highestBidder;
        uint256 endTime;
        bool isEnded;
    }
    BidItem currentBidItem;

    uint32 bidItemID;
    mapping(uint=>BidItem) private auctionRecord;

    event SetAuction(string _item, uint256 _floorprice);
    event Bid(string _item, uint256 price,address bidder);
    event AuctionEnded(address winner, uint256 amount);

    constructor(){
        admin=msg.sender;
        currentBidItem.isEnded=true;
    }

    modifier Onlyadmin {
    require(msg.sender==admin, "Only admin can set the auction round");
    _;
    }

    //Administrator set the new auction round
    function setAuctionRound(string memory _itemName, uint256 _floorprice, uint256 biddingTime) external Onlyadmin {
        require(currentBidItem.isEnded,"current auction not finished");
        require(_floorprice>0, "Floor 0");
        require( bytes(_itemName).length>0, "empty name");
        require(biddingTime>300, "time < 5min");
        currentBidItem=BidItem({
            itemName:_itemName,
            floorPrice:_floorprice,
            highestPrice:_floorprice,
            highestBidder:address(0),
            endTime:block.timestamp+biddingTime,
            isEnded:false
            });
        unchecked {
            bidItemID++;
        }
        emit SetAuction(_itemName, _floorprice);
    }

    //Users bid
    function bid(uint256 price) external{
        BidItem storage item = currentBidItem;
        require(block.timestamp<item.endTime,"auction ended");
        if (price<=item.highestPrice) revert("low bid");
        else {
            item.highestPrice=price;
            item.highestBidder=msg.sender;
            emit Bid(item.itemName,price,msg.sender);
        }
    }

    // When time is up,only admin can end this auctaion round.
    function endBid() external Onlyadmin  returns(address winner,uint256 highestPrice)  {
         BidItem storage item = currentBidItem;
        require(block.timestamp >= item.endTime, "not ended yet");
        item.isEnded=true;
        auctionRecord[bidItemID]=item;
        emit AuctionEnded(item.highestBidder,item.highestPrice);
        return(item.highestBidder,item.highestPrice);
    }

    // View the current auction item.
    function getCurrentItem() external view returns(string memory itemName,uint256 highestPrice) {
            return(currentBidItem.itemName,currentBidItem.highestPrice);
    }

    //When the auction round end, push the data into record for the users to view. 
    function getauctionRecord(uint32 id) external view returns(string memory item,uint256 floorPrice,address winner,uint256 price){
        BidItem memory b=auctionRecord[id];
        if (b.endTime==0) revert("BidItem does not exist");
        return(b.itemName,b.floorPrice,b.highestBidder,b.highestPrice);
    }
}
