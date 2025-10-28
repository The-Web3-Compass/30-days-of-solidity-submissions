//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;
    uint256 public treasureAmount=0;
    mapping(address=>uint256) public withdrawlAllowance;
    mapping (address=>bool) public hasWithdrawl;

    //确定主人
    constructor(){
        owner=msg.sender;
    }

    //"护栏"：修饰符
    modifier onlyOwner(){
        require(msg.sender==owner,"Access denied:Only the owner can perform this action.");
        _;
    }

    //放置宝物
    function addTreasure(uint Amount)public onlyOwner{
        treasureAmount+=Amount;
    }

    //授权
    function approveWithdrawl(address recipient,uint256 amount) public onlyOwner{
        require(amount<=treasureAmount,"Insufficient treasure to approve this withdrawl.");
        withdrawlAllowance[recipient]+=amount;
    }

    //取宝
    function withdrawlTreasure(uint256 amount)public {
        if(msg.sender==owner){
            require(amount<=treasureAmount,"Not enough treasure avaliable.");
            treasureAmount-=amount;
            return;
        }
        
        //设置准许金
        uint256 allowance=withdrawlAllowance[msg.sender];

        require(amount<=allowance,"You are not allowed to withdraw this amount.");//取得钱过多
        require(!hasWithdrawl[msg.sender],"You have already withdrawn your treasure.");//已经取过一次
        require(amount>0,"You don't have any treasure.");//有没有
        require(amount<treasureAmount,"Not enough treasure avaliable.");//钱不够
    
        hasWithdrawl[msg.sender]=true;//标记已经取钱
        withdrawlAllowance[msg.sender];//可取宝箱清零
        treasureAmount-=amount;//总额减少
    }

    //开放私人宝箱领取机会
    function resetWithdrawlTreasure (address resetplayer)public onlyOwner{ 
        hasWithdrawl[resetplayer]=false;
        }
    
    //拥有者交接,转移合约拥有权
    function transferOwnership(address newOwner)public onlyOwner{
        require(newOwner!=address(0),"Invalid address");
        owner=newOwner;
    }

    //查询官方帐户余额

    function getTreasureDetails() public view onlyOwner returns(uint256){
        return treasureAmount;
    }
   

}