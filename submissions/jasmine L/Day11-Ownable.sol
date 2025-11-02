// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 原合约

contract Ownable {
    address private owner;

    event ownershipTransfer(address indexed _previous, address indexed _new);

    constructor(){
        owner = msg.sender;
        emit ownershipTransfer(address(0), owner);
    }
    modifier onlyOwner(){
        require(owner == msg.sender, "No permission!");
        _;
    }
    // owner is private, so that we need a function to view owner;
    function ownerAddress()public view returns(address){
        return owner;
    }

    function transferOwnership(address _new)public onlyOwner{
        require(_new != address(0), "address is not valid!");
        address previous = owner;
        owner = _new;
        emit ownershipTransfer(previous, owner);
    }
    
}