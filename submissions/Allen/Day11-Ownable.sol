// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;


contract Ownable{

    address private owner;

    event OwnershipTransfered(address indexed previousOwner,address indexed newOwner);

    constructor(){
        owner = msg.sender;
        emit OwnershipTransfered(address(0), msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"Only owner can perform this action");
        _;
    }

    function ownerAddress() public view returns (address) {
        return owner;
    }


    function transferedOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0),"Invail new owner");
        address preOwner = owner;
        owner = _newOwner;
        emit OwnershipTransfered(preOwner, _newOwner);
    }





}