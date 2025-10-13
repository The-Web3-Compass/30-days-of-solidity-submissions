// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Auction House
/// @notice 一个简单的拍卖合约，允许用户对物品进行竞价
/// @dev 合约所有者可以结束拍卖并确定获胜者
contract auctionHouse { 
    /// @notice 拍卖所有者地址
    address public owner;
    
    /// @notice 拍卖结束时间戳
    uint256 public auctionEndTime;
    
    /// @notice 起拍价格
    uint public startPrice;
    
    /// @notice 拍卖物品名称
    string public itemName;
    
    /// @notice 当前最高出价者地址
    address public highestBidder;
    
    /// @notice 当前最高出价金额
    uint public highestBid;
    
    /// @notice 标记拍卖是否已结束
    bool public auctionEnded;
    
    /// @notice 记录每个地址的出价金额
    mapping(address => uint256) public bids;
    
    /// @notice 所有出价者的地址列表
    address[] public bidders;

    /// @notice 构造函数，初始化拍卖
    /// @param _itemName 拍卖物品名称
    /// @param _auctionEndTime 拍卖持续时间（秒）
    /// @param _startPrice 起拍价格
    constructor(string memory _itemName, uint256 _auctionEndTime, uint _startPrice) { 
        owner = msg.sender;
        itemName = _itemName;
        auctionEndTime = _auctionEndTime + block.timestamp;
        startPrice = _startPrice;
        highestBid = startPrice;
    }

    /// @notice 查看拍卖物品和当前最高价格
    /// @return 物品名称和当前最高出价
    /// @dev 只有在拍卖未结束时才能调用
    function lookItemAndPrice() external view returns(string memory,uint){
        require(!auctionEnded, "Auction has ended");
        return (itemName,highestBid);
    }
    
    /// @notice 用户出价函数
    /// @param _amount 出价金额
    /// @dev 出价必须高于当前最高价且拍卖未结束
    function bid(uint _amount) external{
        // 确保拍卖未结束
        require(!auctionEnded, "Auction has ended");
        // 确保出价高于当前最高价
        require(_amount > highestBid, "Bid amount must be higher than the current highest bid");
        // 确保拍卖时间未结束
        require(block.timestamp < auctionEndTime, "Auction ended");
        
        // 更新最高出价和出价者
        highestBid = _amount;
        highestBidder = msg.sender;
        bidders.push(msg.sender);
        bids[msg.sender] = _amount;   
    }
    
    /// @notice 结束拍卖函数
    /// @dev 只有合约所有者可以调用
    function endAuction() external{ 
        // 确保只有所有者可以结束拍卖
        require(msg.sender == owner, "Only the owner can end the auction");
        // 确保拍卖时间未结束
        require(block.timestamp < auctionEndTime, "Auction has ended");
        // 确保拍卖未结束
        require(!auctionEnded,"Auction has ended");
        auctionEnded = true;
    }
    
    /// @notice 获取拍卖获胜者和出价
    /// @return 获胜者地址和出价金额
    /// @dev 只有在拍卖结束后才能调用
    function getWinner() external view returns(address,uint){ 
        require(auctionEnded, "Auction has not ended");
        return (highestBidder,highestBid);
    }
    
    /// @notice 获取所有出价者地址
    /// @return 出价者地址数组
    /// @dev 只有在拍卖结束后才能调用
    function getAllBids() external view returns(address[] memory){ 
        require(auctionEnded, "Auction has not ended");
        return bidders;
    }
    
}