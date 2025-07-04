// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid 0 address");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}


contract VaultMaster is Ownable {

    receive() external payable {}

     function withdraw () onlyOwner public {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");

        require(success, "Transaction Failed");
    }

   function getBalance() public view returns (uint256){
    return address(this).balance;
   }
}