// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AdminOnly {
    address public Owner;
    uint256 treasureAmount;

    //计时器
    uint256 timer = block.timestamp;

    mapping(address => uint256) public approveList;
    mapping(address => bool) public hasWithdrawn;

    //构造函数
    constructor(){
        Owner = msg.sender;
    }

    //权限管理
    modifier onlyOwner(){
        require(msg.sender == Owner,"Access denied: Only the owner can perform this action");
        _;
    }

    //更改拥有者
    function transferOwnership(address _newOwner)public onlyOwner{
        require(_newOwner != address(0),"Can't change owner to a empty address");
        Owner = _newOwner;
    }


    function addTreasure(uint256 _amount) public onlyOwner{
        treasureAmount+=_amount;
    }

    //批准
    function approveWithdrawl(address _user,uint256 _amount)public onlyOwner{
        require(_user != address(0),"Can't approvel empty address");
        require(_amount <= treasureAmount,"Not enough treasure available");
        //用户单次最大提取上限
        approveList[_user] = _amount;
    }

    //获得宝藏明细
    function getTreasureDetails() public view onlyOwner returns (uint256){
        return (treasureAmount);
    }

    //重置状态
    function resetWithdrawalStatus(address _user) public onlyOwner{
        require(_user != address(0),"Empty address");
        hasWithdrawn[_user] = false;
    }

    //取宝藏
    function withdrawTreasure(uint256 _amount) public {
        require(_amount <= treasureAmount,"Not enough treasure available");
        if(msg.sender == Owner){
            treasureAmount -= _amount;
            return;
        }
        uint256 allowance = approveList[msg.sender];
        require(block.timestamp>timer,"Cooling down......");
        require(!hasWithdrawn[msg.sender],"You have already withdrawn your treasure");
        require(allowance>0,"You don't have any treasure allowance");
        require(_amount<treasureAmount,"Not enough treasure in the chest");
        require(_amount<=allowance,"You don't have enough treasure allowance");
        hasWithdrawn[msg.sender] = true;
        treasureAmount -= _amount;

        timer = block.timestamp+120;
    }

    //添加一个查询函数，让用户查看自己是否被批准、是否已提取
    function checkStatus() view external returns(uint256,bool){
        require(msg.sender!=Owner,"You are Owner");
        return (approveList[msg.sender],hasWithdrawn[msg.sender]);
    }

}