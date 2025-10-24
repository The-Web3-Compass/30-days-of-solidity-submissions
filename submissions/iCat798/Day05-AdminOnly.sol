// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminOnly{
    address public owner;

    constructor() {
        owner = msg.sender;        // 设计合约拥有者
    }
    

    // 通过修饰符时间可复用的访问控制
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only the owner can perform this action");
        _; 
    }   
}
