//SPDX-License-Identifier:MIT;
pragma solidty ^0.8.0;

//合约部署者、拍卖品、拍卖结束时间、最高拍卖者/拍卖价、是否结束(默认false)
contract Auctionhouse{
    address public owner;
    string public item;
    uint public auctionEndTime;
    address private highestBidder;
    uint private highestBid;
    bool public ended;

    mapping(address=>uint) public bids;
    address[] public bidders;

//构造函数：部署合约只执行一次，且合约内只能定义一个
    constructor(string memory _item , uint _biddingTime){
        owner=msg.sender;
        item=_item;
        auctionEndTime= block.timestamp + _biddingTime;
    } 

    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

    bids[msg.sender] = amount;

    if (amount > highestBid) {
          highestBid = amount;
          highestBidder = msg.sender;
       }
    }

//终止拍卖，并确保无人提前结束拍卖
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");
        require(!ended, "Auction end already called.");

        ended = true;
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    function getWinner() external view returns (address, uint) {
        require(ended, "Auction has not ended yet.");
        return (highestBidder, highestBid);
    }
    
}
