// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract AdminOnly {
    address public owner ;
    uint public treasureAmount;
    mapping(address => uint256) public withdrawAllwance;
    mapping(address => bool) public hasWithdraw;

    constructor () {
        owner = msg.sender;
    }



    //定义onlyOwner修饰器
    modifier onlyOwner(){
        require(msg.sender == owner,"Access deny");
        _;
    }

    //owner向宝箱中加入宝藏
    function addTreasure(uint amount) public onlyOwner{
        treasureAmount += amount ;
    }

    
    function approveWithdraw(address recipient ,uint256  amount ) public onlyOwner{
        require(amount <= treasureAmount,"treasureAmount don't enough");
        withdrawAllwance[recipient] = amount;
    }

    function withdrawTreasure(uint256 amount) public {
        if(msg.sender == owner){
            require(amount <= treasureAmount,"treasureAmount don't enough");
            treasureAmount -= amount;
            return;
        }
        uint256 allwance = withdrawAllwance[msg.sender];
        require(allwance > 0 ,"you don't have any treasuer allwance");
        require(allwance <= treasureAmount,"treasuerAmount don't enough");
        require(amount <= allwance,"Allwance don't enough");
        require(hasWithdraw[msg.sender] == false,"you have withdrawn");
        treasureAmount -= allwance ;
        hasWithdraw[msg.sender]=true;
        withdrawAllwance[msg.sender] = 0;
        
    }
    
    //重置用户提取状态
    function  resetWithdrawalStatus(address user) public onlyOwner{
            hasWithdraw[user] = false;
        }

    //转让所有权
    function transferOwnership(address user) public onlyOwner{
        require(user != address(0) ,"zero address");
        owner = user;
    }

    function getTreasuer() public  view onlyOwner returns (uint256){
        return treasureAmount;
    }


}

