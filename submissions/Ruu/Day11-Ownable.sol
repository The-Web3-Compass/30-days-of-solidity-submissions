//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Ownable{
    address private Owner;
    event OwnershipTransferred(address indexed PreviousOwner, address indexed NewOwner);

    constructor(){
        Owner = msg.sender;
    }

    modifier OnlyOwner(){
        require(msg.sender == Owner, "Only owner can perform this action");
        _;
    }

    function OwnerAddress() public view returns(address){
        return Owner;

    }

    function TransferOwnership(address _newowner_) public OnlyOwner{
        require(_newowner_ != address(0), "Invalid address");
        address previous = Owner;
        Owner = _newowner_;
        emit OwnershipTransferred(previous, _newowner_);
        
    }
}
