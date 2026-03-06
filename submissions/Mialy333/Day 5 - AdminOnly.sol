//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

contract AdminOnly{
    address public owner;
    uint256 public treasureAmount;
    mapping(address => uint256) public withdrawlAllowance;
    mapping(address => bool) hasWithdrawn;

    constructor(){

        owner = msg.sender;
    }

    
}