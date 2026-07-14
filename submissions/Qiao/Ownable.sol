// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Ownable {
    address private owner;

    event OwnershipTransferred (address indexed previousOwner, address indexed newOwner );

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    function getOwnerAddress () public view returns (address) {
        return owner;
    }

    function transferOwnership (address newOwner) public onlyOwner {
        require (newOwner != address(0), "Invalid address.");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}