// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

contract Ownable {

    address public owner;

    // Event to log ownership transfer
    event OwnershipTransfer(address indexed previousOwner, address newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier Admin() {
        require(owner == msg.sender, "Only Admin can call");
        _;
    }

    function transferOwnership(address _newOwner) public Admin {
        require(_newOwner != address(0), "Invalid Address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransfer(previous, _newOwner);
    }
}