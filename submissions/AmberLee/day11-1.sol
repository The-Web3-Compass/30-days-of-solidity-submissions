// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address private owner;

    event OwnershipTransferred (address indexed previousOwner, address indexed newOwner);

    constructor (){
        owner = msg.sender;
        emit OwnershipTransferred (address (0), msg.sender);
    }

    modifier onlyOwner (){
        require (msg.sender == owner,"only owner can transfer");
        _;
    }

    function ownerAddress ()public view returns (address){
        return owner;
    }

    function transferOwner (address _newOwner) public onlyOwner {
        require (_newOwner != address (0), "Invalid address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred (previous, _newOwner);
    }
}