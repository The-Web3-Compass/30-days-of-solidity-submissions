// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable{
  address private _owner;
  event OwnerTransferred(address indexed previousOwner,address indexed newOwner);

  constructor(){
    _owner = msg.sender;
  }

  modifier onlyOwner(){
    require(msg.sender == _owner,"Only owner can perform this action");
    _;
  }

  function getOwner() public view returns (address){
    return _owner;
  }

  function transferOwnership(address _newOwner) public onlyOwner{
    require(_newOwner != address(0),"Cannot set owner to zero");
    address previous = msg.sender;
    _owner = _newOwner;
    emit OwnerTransferred(previous,_newOwner);
  }
  
}