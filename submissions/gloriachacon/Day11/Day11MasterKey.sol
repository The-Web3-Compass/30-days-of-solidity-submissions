// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NotOwner();
error ZeroAddress();
error InsufficientBalance(uint256 requested, uint256 available);
error TransferFailed();

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { owner = msg.sender; }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract VaultMaster is Ownable {
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    receive() external payable { 
        if (msg.value > 0) emit Deposited(msg.sender, msg.value);
    }

    function deposit() external payable {
        if (msg.value == 0) revert InsufficientBalance(0, 0);
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount, address payable to) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        uint256 bal = address(this).balance;
        if (amount > bal) revert InsufficientBalance(amount, bal);

        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit Withdrawn(to, amount);
    }

    function sweep(address payable to) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        uint256 bal = address(this).balance;
        if (bal == 0) revert InsufficientBalance(0, 0);

        (bool ok, ) = to.call{value: bal}("");
        if (!ok) revert TransferFailed();
        emit Withdrawn(to, bal);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}