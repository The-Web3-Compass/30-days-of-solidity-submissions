//SPDX-License-Identifier:MIX
pragma solidity^0.8.0;
//从这天开始变得困难起来


contract AuctionHouse{
    address public owner;
    string public item;
    mapping(address=>uint) public bids;
    
    address[] public bidders;
    //记录变量 拍卖的东西；出的价格，拍卖人=这里要写地址，开始接触owner，就是先定义address，后面再用到owner
    //记录变量 拍卖的限制时间，不能无穷无尽拍卖下去，这里没有想到


    uint public AuctionEndTime;
    bool public ended;
    address private highestbidder;
    uint private highestbid;

    //记录最高出价者和最高价格

constructor (string memory _item, uint _biddingtime){
    //第一次接触constructor，有些动作只有owner能做
    owner=msg.sender;
    item=_item;
    AuctionEndTime=block.timestamp+ _biddingtime;
    //第一次接触时间戳，指的是连接到系统当前时间，后面也会出现

}
 function bid(uint amount)external{
    require(amount>0, "bid amount must be greater than zero.");
    //第一次看条件，要求xx，不然就返回“”这段话
    require(amount>bids[msg.sender],"new bid must be higher than your current bid.");
    require(block.timestamp<AuctionEndTime, "auction has already ended.");

    if (bids[msg.sender]==0){
        bidders.push(msg.sender);
    }
    bids[msg.sender]=amount;

    if(amount>highestbid){
        highestbid=amount;
        highestbidder=msg.sender;
        //这个不是系统最开始就给的，uint默认为0，第一个出价者给钱了之后，就会用这段逻辑成为第一个highestbid
    }
    //这里指的只是参数的数值，没有真的付钱，要结合payable

 }

function endauction()external{
    require(block.timestamp>=AuctionEndTime, "auction has not ended yet.");
    require(!ended, "auction end already called!");
    ended =true;

}
function getwinner()external view returns(address,uint) {
    require(ended,"auction has not ended yet." );
    return(highestbidder,highestbid);

}
function getallthebidder()external view returns(address[]memory ){
    return bidders;
}

//应该加入退钱机制，前一个人出的钱要退回去，我想可不可以先竞价再付款，gpt：高风险，不符合智能合约“自动履行、去信任化”的本质。

    


}