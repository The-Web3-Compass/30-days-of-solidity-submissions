// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AuctionHouse {
    uint public auctionStart;
    uint public auctionEnd;
    uint public highestBid;

    // 构造函数，设置拍卖的开始时间和结束时间
    // constructor(uint _auctionDuration) {
    //     auctionStart = block.timestamp; // 拍卖立即开始
    //     auctionEnd = auctionStart + _auctionDuration; // 设置拍卖持续时间
    //     highestBid = 0; // 初始最高出价为0
    // }

    function setDuration(uint _auctionDuration) public { // 设置拍卖持续时间
        auctionStart = block.timestamp; // 拍卖立即开始
        auctionEnd = auctionStart + _auctionDuration; // 设置拍卖持续时间
        highestBid = 0; // 初始最高出价为0
    }

    function bid(uint _bidAmount) public {
        // 如果在拍卖时间内
        if (block.timestamp < auctionEnd) {
            // 如果出价高于当前最高出价，重新赋值
            if (_bidAmount > highestBid) {
                highestBid = _bidAmount;
            }
        }
    }
    // function getHighestBid() public view returns (uint) {
    //     return highestBid;
    // }

    function isAuctionEnded() public view returns (bool) {
        return block.timestamp > auctionEnd;
    }
}
