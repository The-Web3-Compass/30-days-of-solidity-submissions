// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ownable{
    address private owner;

    event ownershipTransferred(address indexed priviousOwner,address indexed newOwner);

    constructor(){
        owner = msg.sender;
        emit ownershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can perform this action.");
        _;
    }

    function owmerAddress() public view returns(address){
        return owner;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner{
        require(_newOwner != address(0),"Invalid address.");
        address previous = owner;
        owner = _newOwner;
        emit ownershipTransferred(previous, _newOwner);
    }
}
