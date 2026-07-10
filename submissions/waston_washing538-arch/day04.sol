// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
  contract Auctionhouse {
    address public owner;   //我们将在合约部署时设置它，并使其民众这样任何人都可以验证拍卖品的所有者。
    string public item;
    uint public auctionEndTime;
    address private highestbidder;
    uint private highestbid;
    bool public ended;      //布尔变量在声明时如果没有显式初始化，会默认初始化为 false。
    
    mapping (address=>uint ) public  bids;

    address[] public bidders;    //address[] 表示地址类型的动态数组。动态数组的长度可以在运行时动态变化，也就是说，你可以根据需要向这个数组中添加或删除元素。

    constructor(string memory _item,uint _biddingTime){    //用于初始化状态变量
        owner=msg.sender;
        item=_item;       
        auctionEndTime=block.timestamp+_biddingTime;
    }

    function bid (uint amount) external {
        require (block.timestamp< auctionEndTime,"Auction has already ended.");   //require 就是满足前面的条件，返回后面的信息
        require (amount>0,"bid amount must be greater than 0.");
        require (amount>bids[msg.sender],"New bid must be higher than your current bid.");
        
        if (bids[msg.sender]==0) {
            bidders.push(msg.sender);
        }
        bids[msg.sender]=amount;
        if (amount>highestbid) {
            highestbid=amount;
            highestbidder=msg.sender;
        }
    
    function endAuction() external{
        require(block.timestamp>=auctionEndTime,"Auction has not ended yet.");
        require(!ended,"Acution has already called.")    //!ended 的意思是“取 ended 的相反值”。 若ended为false，！ended为ture，返回后面信息
        ended=true;    //ended 是一个 “全局标记”   
    } 
    // Get a list of all bidders
    function gerAllBidders() external view returns (address[] memory){
        return bidders;
    }
    function getwinner() external view returns (address,uint){
       require (!ended,"not yet.");
       return(highestbidder,highestbid) ;
      
        
    }


     
    }



  }