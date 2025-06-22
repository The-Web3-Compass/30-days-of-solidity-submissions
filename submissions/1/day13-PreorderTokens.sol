// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract Ownable {

    address public Owner;

    constructor() {
        Owner = msg.sender;
    }

    modifier onlyOwner ()  {
        require(Owner == msg.sender, "Not a owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner() {
        require(_newOwner != address(0), "Not a valid address");
        Owner = _newOwner;
    }

}

contract VaultMaster is Ownable {

    function withdraw(uint _amount) public onlyOwner {
    require(_amount <= address(this).balance, "Insufficient balance");
    payable(msg.sender).transfer(_amount);
    }

    receive() external payable { }

}