// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AdminOnly {
    //state variables
    address public owner; //存储合约的“拥有者”地址,用来区分谁有权限执行“管理员操作”。
    uint256 public treasureAmount; //存储宝库中有多少“资金/资源”,整个合约的“金库余额”。
    mapping (address => uint256) public withdrawalAllowance; //为每个用户记录“允许提取的额度”
    mapping (address => bool) public haswithdrawn; //记录用户是否已经提取过

    // Constructor sets the contract creator as the owner
    constructor(){
        owner = msg.sender;
    }

    //Modifier for owner-only functions
    modifier onlyOwner(){
        require(msg.sender == owner,"Access denied:Only the owner can perform this action.");
        _;
    }

    //Only the owner can add treasure
    function addTreasure(uint256 amount) public onlyOwner {
        treasureAmount += amount;//管理员增加宝库余额,让管理员定义宝库资源总额
    }

    //Only the owner can approve withdrawals
    function approvewithdrawal(address recipient,uint256 amount) public onlyOwner{
        require(amount <= treasureAmount,"Not enough treasure available.");//管理员审批某个用户可以提取多少额度
        withdrawalAllowance[recipient] = amount;
    }

    //Anyone can attempt to withdraw,but only those with allowance will succeed
    function withdrawTreasure(uint256 amount) public{

        if(msg.sender == owner){
            require(amount <= treasureAmount,"Not enough treasury available for this action.");
            treasureAmount -= amount;

            return;
        }
        uint256 allowance = withdrawalAllowance[msg.sender];

        //Check if user has an allowance and hasn't withdrawn yet
        require(allowance > 0,"You don't have any treasure allowance.");
        require(!haswithdrawn[msg.sender],"You have already withdrawn your treasure.");
        require(allowance <= treasureAmount,"Not enough treasure in the chest.");
        require(allowance >= amount,"You can't withdraw more than you are allowed.");

        //Mark as withdrwan and reduce treasure
        haswithdrawn[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;

    }

    //Only the owner can reset someone's withdrawal status
    function resetwithdrawalStatus(address user,uint256 newAllowance) public onlyOwner{
        haswithdrawn[user] = false;
        withdrawalAllowance[user] = newAllowance;//优化：重置后给他的新额度
    }

    //Only the owner can transfer ownership
    function transferOwnership(address newOwner)public onlyOwner{
        require(newOwner != address(0),"Invalid address.");
        owner = newOwner;
    }

    function getTreasureDetails()public view onlyOwner returns (uint256){
        return treasureAmount;
    }

}
