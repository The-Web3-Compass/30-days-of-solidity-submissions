// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable{
    address private owner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    constructor(){
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Not the owner!");
        _;
    }

    function showOwner() public view returns(address){
        return owner;
    }

    function transferOwnerShip(address _addr)public onlyOwner{
        owner = _addr;
        emit OwnershipTransferred(msg.sender, _addr);
    }

}