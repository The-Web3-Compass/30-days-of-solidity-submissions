/// @title AuctionHouse
/// @notice 这是一个实现基础拍卖功能的智能合约。
/// @dev 该合约允许用户对一个拍品进行出价，并在拍卖结束后确定赢家并处理资金转移。
/// @dev 主要功能包括：创建拍卖、用户出价、结束拍卖和提现。
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    address public owner; // 合约部署者，接收拍卖款
    string public itemName; // 拍品名称
    uint256 public minBid; // 起拍价
    uint256 public auctionEndTime; // 拍卖结束时间
    uint256 public highestBid; // 当前最高出价
    address public highestBidder; // 当前最高出价者的地址
    bool public ended; // 标志拍卖是否已结束
    bool public itemSold; // 标志拍品是否已售出
    mapping(address => uint256) public bids; // 用于记录每个出价者的出价金额

    // 事件声明
    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount, bool sold);

    constructor(string memory _itemName, uint256 _minBid, uint256 _biddingTime) {
        owner = msg.sender;
        itemName = _itemName;
        minBid = _minBid;
        auctionEndTime = block.timestamp + _biddingTime;
        highestBid = _minBid; // 初始最高价为起拍价
        highestBidder = address(0); // 初始无最高出价者
        ended = false;
        itemSold = false;
    }

    function bid() public payable {
        require(!ended, "Auction has ended.");
        require(block.timestamp < auctionEndTime, "Auction has ended.");
        require(msg.value > highestBid, "Bid must be higher than current highest bid.");

        if (highestBidder != address(0)) {
            // 将前一个最高出价者的资金加入其可提现余额
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    function endAuction() public {
        require(msg.sender == owner, unicode"only owner can end auction");
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet.");
        require(!ended, "Auction has ended.");
        ended = true;

        if (highestBidder != address(0) && highestBid >= minBid) {
            itemSold = true;
            // 将最高出价金额转移给合约所有者
            payable(owner).transfer(highestBid);
            emit AuctionEnded(highestBidder, highestBid, true);
        } else {
            // 拍品未售出
            emit AuctionEnded(address(0), 0, false);
        }
    }


    function withdrawBid() public {
        require(ended, "Auction has not ended yet.");
        require(highestBidder != msg.sender, "You are the current highest bidder, cannot withdraw.");
        
        uint256 refund = bids[msg.sender];
        require(refund > 0, "No withdrawable amount.");

        bids[msg.sender] = 0; // 将可提现金额清零
        payable(msg.sender).transfer(refund);
    }

    // 防止直接向合约发送以太币而不通过 bid() 函数
    receive() external payable {
        revert("Direct payments not allowed. Please use the bid() function.");
    }
}
