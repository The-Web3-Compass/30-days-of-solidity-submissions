//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract AdminOnly{
    //宝藏系统

    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawAllowance;
    mapping(address => bool) public hasWithdraw;  //每个用户都有提取标志

    constructor(){
      owner  = msg.sender ;
    }

    modifier onlyOwner{
        require(msg.sender == owner,"Access denied!");
        _;
    }

    //添加宝藏总数
    function addTreasureAmount(uint256 amount) public onlyOwner{
        treasureAmount += amount; 
    }

    //为某个用户分配宝藏数
    function allowWithdral(address recipient,uint256 amount) public onlyOwner{
        require(amount <= treasureAmount,"Treasure is not enough!");
        withdrawAllowance[recipient] = amount;
    }

    //提取宝藏
    function withdraw(uint256 amount) public {
        if(msg.sender == owner){
            require(amount <= treasureAmount,"Treasure is not enough!");
            treasureAmount -= amount;
            return;
        }

        require(amount <= treasureAmount,"Treasure is not enough!"); //小于库存
        require(withdrawAllowance[msg.sender] >= 0,"You dont allowed to withdraw");  //宝藏主人分配了
        require(amount <= withdrawAllowance[msg.sender] ,"You dont have enough allowance!"); //大于主人分配的额度
        require(!hasWithdraw[msg.sender],"You have already withdrawed!");  //没有提取过宝藏
        treasureAmount -= amount;
        withdrawAllowance[msg.sender] -= amount;
        hasWithdraw[msg.sender] = true;
        
    }

    function resetWithdraw(address recipient) public onlyOwner{
        hasWithdraw[recipient] = false;
    }

    function transferNewOwner(address recipient) public onlyOwner{
        require(recipient != address(0),"address is not exist!");
        owner = recipient;
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }

}