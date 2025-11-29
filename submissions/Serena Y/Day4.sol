// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract AuditionHouse{
    address public owner;//我们需要追踪负责操作的人——即部署合约的人
    string public item;//拍卖的东西
    uint public auctionEndTime;//拍卖结束的时间
    address private highestBidder;
    uint private highestBid;
    bool public ended;//标记拍卖是否结束 bool的初始值为false

    mapping (address => uint) public bids;
    address[] public bidders;
    //初始化拍卖 售卖的物品以及时间
    constructor(string memory _item, uint _biddingTime){//constructor 是一个特殊的函数，用于在合约部署时初始化状态变量或执行一次性设置
    owner = msg.sender;
    item = _item;
    auctionEndTime = block.timestamp + _biddingTime;
    }
//允许用户去竞拍
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended");//Unnecessary？？？
        require(amount > 0, "Bid amount must be greater than zero");
        require(amount > bids[msg.sender],"New bid must be higher than your current bid.");
//跟踪新的竞拍者
    if (bids[msg.sender] ==0){
        bidders.push(msg.sender);
    }
    bids[msg.sender] = amount;
    if(amount > highestBid){
        highestBid = amount;
        highestBidder = msg.sender;
    }
    
    if(block.timestamp>=auctionEndTime && !ended){//New added, to save the problem that auction can't end automatically-not working
        ended = true;
        revert("Auction has ended");//立即终止函数执行
        
    }
}  
modifier onlyOwner() {
    require(msg.sender==owner,"Not Owner");//New added, to save the problem that anyone can end the auction
    _;
}
function endAuction() external onlyOwner{
    require(block.timestamp >= auctionEndTime, "Auction hasn't ended yet.");//确保拍卖在合约预设的时间上已经结束
    require(!ended,"Audition end already called");
    ended = true;
}
function getAllBidders() external view returns (address[] memory){
    return bidders;
}
function getWinner() external view returns (address, uint){
    require(ended,"Auction has not ended yet.");
    return (highestBidder, highestBid);
}
}