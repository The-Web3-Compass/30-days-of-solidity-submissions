// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract AuctionHouse {
    // 状态变量
    address public owner; //拍卖创建者
    string public item; //拍卖物品
    uint256 public auctionEndTime; //拍卖结束时间
    address public highestBidder; //最高出价者
    uint256 public highestBid; //最高出价
    bool public ended; //拍卖是否结束

    mapping(address => uint256) public bids; //映射每个地址的出价
    address[] public bidders; //所有出价者地址

    //事件
    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event Withdrawn(address indexed bidder, uint256 amount);

    //构造函数
    constructor(string memory _item, uint256 _biddingTime) {
        owner = msg.sender;
        item = _item;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        require(msg.value > 0, "Bid amount must be greater than zero");
        require(msg.value > highestBid, "Bid must be higher than current highest bid");

        // 记录新出价者
        if (bids[msg.sender] == 0) {
            bidders.push(msg.sender);
        }

        // 更新出价
        bids[msg.sender] += msg.value;

        // 更新最高出价
        highestBid = msg.value;
        highestBidder = msg.sender;

        emit BidPlaced(msg.sender, msg.value);
    }

    // 结束拍卖
    function endAuction() external onlyOwner {
        require(block.timestamp >= auctionEndTime, "Auction has not yet ended");
        require(!ended, "Auction has already ended");
        ended = true;

        emit AuctionEnded(highestBidder, highestBid);
    }

    // 获取获胜者
    function getWinner() external view returns (address, uint256) {
        require(ended, "Auction has not ended yet");
        return (highestBidder, highestBid);
    }

    // 获取所有出价者
    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }

    // 撤回出价（非最高出价者）
    function withdraw() external {
        require(ended, "Auction has not ended yet");
        require(msg.sender != highestBidder, "Highest bidder cannot withdraw");
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No funds to withdraw");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }

}