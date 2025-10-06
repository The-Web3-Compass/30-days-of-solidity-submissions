// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title EtherPiggyBank
 * @dev A simple digital piggy bank contract that allows users to deposit and withdraw Ether
 * @notice This contract demonstrates basic Ether handling and balance management
 */
contract EtherPiggyBank {
    // Mapping to store each user's balance
    mapping(address => uint256) private balances;
    
    // Events to track deposits and withdrawals
    event Deposited(address indexed user, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed user, uint256 amount, uint256 newBalance);

    // Allows users to deposit Ether into their piggy bank
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        
        emit Deposited(msg.sender, msg.value, balances[msg.sender]);
    }
    
    /**
     * @dev Allows users to withdraw a specific amount from their piggy bank
     * @param _amount The amount of Ether (in wei) to withdraw
     */
    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, _amount, balances[msg.sender]);
    }
    
    // Allows users to withdraw their entire balance
    function withdrawAll() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount, 0);
    }
    
    // Returns the balance of the caller
    function getMyBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    /**
     * @dev Returns the balance of a specific address
     * @param _user The address to check
     * @return The balance of the specified address
     */
    function getBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
    
    // Returns the total Ether stored in the contract
    function getTotalContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Fallback function to receive Ether
    // Automatically deposits Ether sent directly to the contract
    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value, balances[msg.sender]);
    }
}