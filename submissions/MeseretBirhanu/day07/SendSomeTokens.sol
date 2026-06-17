// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SendSomeTokens {
    
    address public owner;
    uint256 public platformfee = 2;
    mapping(address=> bool) public bannedAddresses;

    constructor(){
        owner = msg.sender;
    }

    function banAddress(address _addr) public {
        require(msg.sender == owner , "not authorized!");
        bannedAddresses[_addr] = true;
    }
    function transfer(address _to) public payable {
        require(_to != address(0) , "invalid address");
        require(!bannedAddresses[msg.sender]);
        address recipient = _to;
        uint256 fee = ( msg.value * platformfee )/100;
        uint256 finalTransfer = msg.value - fee; 
        (bool success, ) = recipient.call{value: finalTransfer}("");
        require(success , "sending to person failed");
        (bool successfull, ) = owner.call{value: fee}("");
        require(successfull , "sending fee failed");

    }
}