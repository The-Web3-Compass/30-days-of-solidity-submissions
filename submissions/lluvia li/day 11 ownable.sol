// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Ownable{
    address private owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(){
        owner=msg.sender;
        emit OwnershipTransferred(address(0), msg.sender); 
    }
    
    modifier OnlyOwner(){
        require(msg.sender==owner,"Only owner can perform this action" );
        _;
    }

    function ownerAddress() public  view returns(address){
        return owner;
    }

    function transferOwnership(address _newOwner) public OnlyOwner{
        require(_newOwner != address(0), "Invalid address" );
        address previous = owner;
        owner= _newOwner;
        emit OwnershipTransferred(previous, _newOwner);

    }
