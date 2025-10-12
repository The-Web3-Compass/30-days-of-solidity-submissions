// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse{

    //拍吗发起者（合约部署人）
    address private owner;
    // 拍卖商品
    string private item;
    //拍卖结束时间
    uint private endTimestemp;
    //最高价出价者
    address private highestBidder;
    //最高价
    uint private highestBid;


    //出价客户的地址
    address[] private bidders;
    //出价客户地址->价格
    mapping(address=>uint) private bidMap;

    /**
    构造函数的请求参数中
    引用类型需要带memory或calldata，主要有string、数组、mapping（不可用于构造函数请求参数）、bytes、struct
    数值类型不需要 uint、bool、enum、bute1-byte32、address

    string是保存UTF8的字符串，动态字节数组
    bytes是保存任意二进制数据的动态字节数组

    msg是EVM提供的全局变量，主要说明发起交易者的基本数据
    sender：发起交易者的地址
    value：代币数量，当前网络对应的原生币数量
    data，交易请求的完整数据（函数选择器+ABI编码的参数）
    aig data的前四字节，函数选择器

    block EVM全局变量，当前区块的相关信息
    timestamp 区块的打包时间戳
    */
    constructor(string memory _item, uint _durationInMin) {
        owner = msg.sender;
        item=_item;
        endTimestemp = block.timestamp + _durationInMin;
    }

    /**
     * 竞拍
     * bidCount：竞拍的代币数量
     * 要求：
     * 1.拍卖未结束
     * 2.竞拍的代币数量大于当前最高价
     * 3.竞拍的代币数量大于0
     * 4.竞拍的代币数量大于当前最高价
     

    */
    function bid(uint  bidCount) public {
        require(block.timestamp < endTimestemp , unicode"拍卖已结束");
        // require(bidCount > highestBid , unicode"未超过最高价");
        require(bidCount > 0 , unicode"竞拍代币不允许为0");
        require(bidCount > bidMap[msg.sender] , unicode"客户出价必须高于上一次出价");
    
 
        if(bidMap[msg.sender] == 0){
            bidders.push(msg.sender);
        }
        bidMap[msg.sender] = bidCount;

        require(bidCount > highestBid , unicode"未超过最高价");

        if(bidCount > highestBid){
            highestBid = bidCount;
            highestBidder = msg.sender;
        }
    }

    // 返回所有参加竞拍的客户地址
    function getAllCust() public view  returns (address[] memory){
        return bidders;
    }

    //查询获胜者
    function getWinner() public view returns (address , uint ){
        require(block.timestamp > endTimestemp,unicode"竞拍未结束");
        return (highestBidder,highestBid);
    }

}