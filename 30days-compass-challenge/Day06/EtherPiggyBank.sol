// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract EtherPiggyBank {
    // Mapping to store balances of each user
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);

    
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getBalance() external view returns (uint256 balance) {
        return balances[msg.sender];
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
