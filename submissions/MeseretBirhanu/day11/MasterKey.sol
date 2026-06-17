// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MasterKey{

    address public owner;

    event paymentRelease(string);

    constructor(){
        owner = msg.sender;
    } 
    modifier onlyOwner{
        require(msg.sender == owner , "not owner");
        _;
    }
    function releasePayment() public onlyOwner {
        emit paymentRelease("payment released");
    }

}