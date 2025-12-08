// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//users can bid
//the highest won the item
//have a time limit

contract AuctionHouse{
    address public owner;
    string public itemName;
    uint256 auctionEndTime;
    uint256 itemPrice;
    uint256 highestPrice;
    mapping (uint256 => address) public Bidders;

    constructor (string memory _itemNamer,uint256 _itemPrice,uint256 _auctionEndTime){
        owner = msg.sender;
        itemName = _itemNamer;
        itemPrice = _itemPrice;
        auctionEndTime = _auctionEndTime + block.timestamp;
        highestPrice = _itemPrice;

    }

    function Bid(uint256 _price) external {
        require(block.timestamp < auctionEndTime,"Auction ended already!!");
        require(_price != 0 || _price > highestPrice, "Invalid Price");
    
        Bidders[_price] = msg.sender;
        highestPrice = _price;
    }

    function CheckCurrentPrice() public view returns(address,uint256){
        require(block.timestamp < auctionEndTime,"Auction ended already!!");

        return (Bidders[highestPrice],highestPrice);
    }

    function CheckResult() public view returns(address,uint256){
        require(block.timestamp > auctionEndTime,"Auction is not done yet!!");

        return (Bidders[highestPrice],highestPrice);
    }

}
