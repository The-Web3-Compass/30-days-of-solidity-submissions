// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly{

address public owner;
uint256 public treasureAmount;
mapping(address=>uint256) public withdrawalAllowance;//提款限额
mapping(address=>bool) public hasWithdrawn;//判断是否已撤回

constructor(){
    owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender==owner, "Access denied: Only the owner can perform this action");
    _;
}
//往宝箱中添加宝物
function addTreasure(uint256 amount) public onlyOwner{//只有owner能够加宝藏
    treasureAmount += amount;
}
//授权Ta人取宝
function approveWithdrawal(address recipient, uint256 amount) public onlyOwner{
    require(amount<=treasureAmount, "Not enough treasure available");
    withdrawalAllowance[recipient]=amount;
}
//实际的取宝过程
function withdrawTreasure(uint256 amount) public{
    //拥有者自己取宝
    if(msg.sender==owner){
        require(amount<=treasureAmount,"Not enough treasury available for this action");
        treasureAmount-=amount;
        return;
    }
    //普通用户取宝
    uint256 allowance = withdrawalAllowance[msg.sender];
    require(allowance>= amount,"Can not withdraw more than you are allowed");//不能够超出权限取宝物
    require(amount <= treasureAmount, "Not enough treasure in the chest");//宝箱里是否仍有足够的宝物？
    require(allowance>0,"You don't have any treasure allowance");//是否被批准提取？
    require(!hasWithdrawn[msg.sender],"You have already withdrawn your treasure");//是否已经提取过？
    
    
    //完成取宝操作
    
    treasureAmount-=amount;//从宝箱中减去被批准的提取数量
    withdrawalAllowance[msg.sender]-=amount;//扣减部分授权额

    if(withdrawalAllowance[msg.sender]==0){
        hasWithdrawn[msg.sender]=true;//将用户标记为“已提取”；
    }
    }


//重置用户的提取状态
    function resetWithdrawalStatus(address user) public onlyOwner{
        hasWithdrawn[user]=false;
    }
    //转移合约拥有权
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0),"Invalid address");
        owner= newOwner;
    }

    //查看宝箱信息（仅限拥有者）
    function getTreasureDetails() public view onlyOwner returns (uint256){
        return treasureAmount;
    }

}
