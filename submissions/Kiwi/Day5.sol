// SPDX-License-Identifier:MIT

pragma solidity^0.8.0;

contract AdminOnly {
    
    uint256 coldtime= block.timestamp;

    address public owner;
    uint256 public treasureAmount;

    mapping (address => uint256) public withdrawalAllowance;
    mapping(address => bool) public hasWithdrawal;
    // constructor sets the contract creator as the owner
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner,"Access denied: Only the owner can perform this action");
        _;
    }

    function addTreasure(uint256 amount) public onlyOwner{
       treasureAmount += amount;
    } 

    function approvalWithdrawal(address recipient, uint256 amount) public onlyOwner {
        require(amount <= treasureAmount,"Not enough treasure available");
        require(block.timestamp >= coldtime, "it's cold time.");
        coldtime = block.timestamp + 1 ;
        withdrawalAllowance[recipient] = amount;
    }

    function withdrawalTreasure(uint256 amount) public {
        if (msg.sender == owner) {
            require(amount <= treasureAmount, "Not enough treasury available for this action.");
            treasureAmount -= amount;

            return;
        }

        uint256 allowance = withdrawalAllowance[msg.sender];

        require(allowance > 0,"You don't have any treasure allowance");
        require(!hasWithdrawal[msg.sender],"You have already withdrawn your treasure");
        require(allowance <= treasureAmount,"Not enough treasure in the chest");
        require(allowance >= amount, "Cannot withdraw more than you are allowed");

        hasWithdrawal[msg.sender] = true;
        treasureAmount -= allowance;
        withdrawalAllowance[msg.sender] = 0;

    }

    function resetWithdrawalStatus(address user) public onlyOwner {
        hasWithdrawal[user] =false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"Invalid address");
        owner = newOwner;
    }

    function getTreasureDetails() public view onlyOwner returns (uint256) {
        return treasureAmount;
    }
}