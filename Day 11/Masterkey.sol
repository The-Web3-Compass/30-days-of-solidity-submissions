// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//  Reusable base contract for ownership logic
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// VaultMaster contract inherits from Ownable
contract VaultMaster is Ownable {
    uint public vaultBalance;

    // Deposit Ether into the vault
    function deposit() public payable {
        require(msg.value > 0, "Send some ETH");
        vaultBalance += msg.value;
    }

    // Withdraw only by the master key holder
    function withdraw(uint amount) public onlyOwner {
        require(amount <= vaultBalance, "Insufficient funds");
        vaultBalance -= amount;
        payable(owner).transfer(amount);
    }

    // View contract balance
    function getBalance() public view returns (uint) {
        return vaultBalance;
    }
}
