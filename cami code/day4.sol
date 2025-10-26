// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract auction{

    address public owner;
    string public item;
    uint256 public auctionendtime;
    address private highestbidder;
    uint256 private highestbid;
    bool public ended;

    mapping(address => uint256)public bids;
    address[] public bidders;

    constructor(string memory _item, uint256 _biddingtime){
        owner =msg.sender;
        item = _item;
        auctionendtime = block.timestamp + _biddingtime;
    }

    function bid(uint256 amount) external {
        require(block.timestamp< auctionendtime, "Auction has already ended");
        require(amount > 0, "Bid amount must be greater than zero.");
        require(amount > bids[msg.sender], "New bid must be higher than your current bid.");

        if (bids[msg.sender] == 0) {
        bidders.push(msg.sender);
        }
    
        bids[msg.sender] = amount;

        if (amount > highestbid) {
        highestbid = amount;
        highestbidder = msg.sender;
        }
    }
    
    
    function endauction () external {
    require(block.timestamp >= auctionendtime, "Auction hasn't ended yet.");
    require(!ended, "Auction end already called.");

    ended = true;
}

    function getWinner() external view returns (address, uint) {
    require(ended, "Auction has not ended yet.");
    return (highestbidder, highestbid);
}

    
    function getAllBidders() external view returns (address[] memory) {
    return bidders;
}

}