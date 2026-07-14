// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract piggyBank {
    
    mapping(address => uint256) public balances;

  
    event Deposited(address indexed user, uint256 amount);

  
    event Withdrawn(address indexed user, uint256 amount);

   
    function deposit() external payable {
        require(msg.value > 0, "Must send Ether to deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}