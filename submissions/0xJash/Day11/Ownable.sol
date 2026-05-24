// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address (0), "Invalid address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
} 