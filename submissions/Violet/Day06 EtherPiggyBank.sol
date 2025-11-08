// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherPiggyBank {

    address public owner;
    uint256 public targetAmount;
    uint256 public deadline;
    bool public goalReached;
    
    event Deposit(address indexed depositor, uint256 amount);
    event GoalReached(uint256 totalAmount);
    event Withdrawal(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier canWithdraw() {
        require(goalReached || block.timestamp >= deadline, "Cannot withdraw yet");
        _;
    }

    constructor(uint256 _targetAmount, uint256 _durationInDays) {
        require(_targetAmount > 0, "Target must be > 0");
        require(_durationInDays > 0, "Duration must be > 0");
        
        owner = msg.sender;
        targetAmount = _targetAmount;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }
 
    function deposit() external payable {
        require(msg.value > 0, "Amount must be > 0");
        require(block.timestamp < deadline, "Expired");
        require(!goalReached, "Goal already reached");
        
        emit Deposit(msg.sender, msg.value);
  
        if (address(this).balance >= targetAmount) {
            goalReached = true;
            emit GoalReached(address(this).balance);
        }
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    

    function withdraw() external onlyOwner canWithdraw {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds");
        
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(owner, amount);
    }

    function canWithdrawFunds() external view returns (bool) {
        return goalReached || block.timestamp >= deadline;
    }
}