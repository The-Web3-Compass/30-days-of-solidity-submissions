// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@title 拍卖合约 AuctionHouse
///@author yuheng
///@notice 允许用户参与出价拍卖，记录最高出价者，结束后可查询结果
/// @dev 本合约使用模拟金额出价（非真实转账），适合教学与逻辑演示

contract AuctionHouse {
    address public owner;   //声明拍卖发起人（合约的部署者）
    string public item; //声明拍卖的物品名称
    uint public auctionEndTime; //声明拍卖截止的时间戳
    address private highestBidder;  ///@dev 当前最高出价者，仅内部记录，通过 getWinner 函数查看
    uint private highestBid;    /// @dev 当前最高出价金额，仅内部记录，通过 getWinner 函数查看
    bool public ended;  //声明拍卖是否已结束

    mapping(address => uint) public bids;   //声明每位出价者的最高出价记录(映射)
    address[] public bidders;   //声明所有出过价的地址集合

    /*
    @notice 构造函数：部署时初始化拍卖品和持续时间
    @param _item 拍卖物品名称
    @param _biddingTime 拍卖持续时间（以秒为单位）
    */


    constructor(string memory _item, uint _biddingTime){
        owner = msg.sender; // 部署合约的地址为所有者
        item = _item;   // 设置拍卖物品名称
        auctionEndTime = block.timestamp + _biddingTime;    // 拍卖结束时间 = 当前时间 + 拍卖时长
    }
    /*
    @notice 用户出价参与拍卖
    @param amount 用户愿意出价的数值（非真实 ETH，仅为逻辑变量）
    */
    function bid(uint amount) external {
        require(block.timestamp < auctionEndTime, "Auction has already ended.");
        require(amount > 0, "Bid mount must be greater than zero");
        require(amount > bids[msg.sender], "new bid must be higher than your current bid.");
        // 如果该地址是第一次出价，则记录进 bidders 列表
        if (bids[msg.sender] == 0){
            bidders.push(msg.sender);
        }
        // 更新当前用户的出价
        bids[msg.sender] = amount;
        // 如果该出价超过历史最高，则更新最高出价及出价人
        if (amount > highestBid) {
            highestBid = amount;
            highestBidder = msg.sender;
        }
    }
    /*
    @notice 获取所有出过价的参与者地址
    @return bidders 所有竞拍人地址数组
    */
    function getAllBidders() external view returns (address[] memory){
        return bidders;
    }
    /*
    @notice 查询中标者及其出价（只能在拍卖结束后调用）
    @return winner 地址 和 出价金额
    */
    function getWinner() external view returns (address, uint){
        require(ended, "Auction has ended yet.");
        return (highestBidder, highestBid);
    }





}