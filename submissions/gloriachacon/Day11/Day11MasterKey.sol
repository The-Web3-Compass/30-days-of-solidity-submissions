// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ownable {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }
}

contract VaultMaster is Ownable {
    receive() external payable {}
    function deposit() external payable {}
    function withdraw(uint256 amount, address payable to) external onlyOwner {
        require(to != address(0), "zero");
        require(amount <= address(this).balance, "insufficient");
        to.transfer(amount);
    }
    function sweep(address payable to) external onlyOwner {
        require(to != address(0), "zero");
        to.transfer(address(this).balance);
    }
    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}