// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Ownable {

    address private owner;

    event TransferOwnership(address indexed from, address indexed to);

    constructor(){
        owner = msg.sender;
        emit TransferOwnership(address(0), owner);
    }

    modifier onlyOwner(){
        require (msg.sender == owner, "Not authorized!");
        _;
    }

    function getOwner() public view returns (address){
        return owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner{
        require (_newOwner != address(0), "Enter a valid address");

        address previousOwner = owner;
        owner = _newOwner;
        emit TransferOwnership(previousOwner, _newOwner);
    }
}
