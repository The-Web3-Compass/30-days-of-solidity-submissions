// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
  address private owner;
  constructor () {
    owner = msg.sender;
  }

  modifier onlyOwner{
    require(msg.sender == owner, "Not the owner!");
    _;
  }

  function transferOwnerhsip(address _newOwner) external onlyOwner{
    owner = _newOwner;
  }
}


contract VaultMaster is Ownable{

  modifier nonReentrant(){
    bool lock = true;
    require(lock);
    _;
    lock = false;
  }

  function withdraw(uint256 _amount) external nonReentrant onlyOwner{
    require(_amount <= address(this).balance && _amount > 0,"No sufficient balance!");
    payable(msg.sender).transfer(_amount);
  }

  receive () external payable{}
}
