// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Ownable {

    address owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require (msg.sender == owner, "Not authorized!");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner{
        require (newOwner != address(0), "Enter a valid address");
        owner = newOwner;
    }
}