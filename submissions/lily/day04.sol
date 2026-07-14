// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;    

contract AuctionHouse {
    address public owner;  // 所有者
    string public item;  // 物品
    uint public auctionEndTime;  // 结束拍卖时间
    address private highestBidder;  // 出价最高者地址；私有
    uint private highestBid;  // 最高出价；私有

    bool public ended;  // 拍卖是否结束

    mapping(address=>uint) public bids;  // 出价者地址和出价
    address[] public bidders;  // 参与过出价的人

    // 构造函数 - 合约部署时仅执行一次
    constructor(string memory _item, uint biddingTime) {
        owner = msg.sender;  // 部署合约操作者的地址
        item = _item;
        auctionEndTime = block.timestamp + biddingTime;  // 当前时间 + 持续时间 单位 s
    }

    function bid(uint amount) external { // 只能被外部调用

        // require(A, B) 即 if A ? yes 则继续；no 打印B并退出
        // 出价结束了吗
        require(block.timestamp < auctionEndTime, "Auction Ended");  
        // 出价大于0吗
        require(amount > 0, "Bid amount must be greater than 0.");
        // 这次出价比上次高吗
        require(amount > bids[msg.sender], "New bid must higher than your current bid.");

        if (bids[msg.sender] == 0) {  // 如果是第一次出价
            bidders.push(msg.sender);
        }

        bids[msg.sender] = amount;  // 保存出价

        if (amount > highestBid) {  // 如果出价比当前最高价高，则更新最高价
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }

    function endAuction() external {
        
        // 拍卖时间到了吗
        require(block.timestamp >= auctionEndTime, "Auction hasn't ended.");
        // 有人已经结束他了吗
        require(!ended, "Auction end already called.");
        
        ended = true;
    }

    function getWinner() external view returns (address, uint) {

        // 拍卖结束了吗
        require(ended, "Auction hasn't ended.");
        
        return (highestBidder, highestBid);
    }

    function getAllBidders() external view returns (address[] memory) {
        return bidders;
    }
}