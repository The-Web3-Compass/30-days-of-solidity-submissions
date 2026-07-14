// SPDX-License-Identifier: MIT
// parent contract
pragma solidity ^0.8.18;

contract ownable {
    address private owner;
     event ownershipTransferred
     (address indexed previousOwner, address indexed newOwner);

 // constructors
 constructor () {
    owner = msg.sender;
 }
 modifier onlyOwner () {
    require (msg.sender == owner,"only owner can perform this action");
    _;
 }

 function ownerAdress () public view returns (address) {
    return owner;
 }

 function transferOwvership(address _newOwner) public onlyOwner
   {
    require(_newOwner != address(0), "this address can't be zero");
    address previous = owner;
    owner = _newOwner;
    emit ownershipTransferred(previous, _newOwner);

 }


}  