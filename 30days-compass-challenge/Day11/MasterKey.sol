// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Caller is not the owner");
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract VaultMaster is Ownable {
    mapping(address => uint256) private balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    // Allow anyone to deposit ETH into the vault
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Allow only the owner to withdraw ETH from the vault
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance in vault");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit Withdrawal(_to, _amount);
    }

    // Get balance of the contract
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Get individual user balance (for tracking deposits)
    function getUserBalance(address _user) external view returns (uint256) {
        return balances[_user];
    }
}
