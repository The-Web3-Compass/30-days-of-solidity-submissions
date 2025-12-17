// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;
/*
   Build a secure Vault contract that only the owner (master key holder) can control. 
   You'll split your logic into two parts: a reusable 'Ownable' base contract and a 'VaultMaster' 
   contract that inherits from it. 
   Only the owner can withdraw funds or transfer ownership. 
   This shows how to use Solidity's inheritance model to write clean, reusable access control patterns — 
   just like in real-world production contracts. 
   It's like building a secure digital safe where only the master key holder can access or delegate control.
*/    

contract Ownable {
    address private owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // constructor() {
    //     owner = msg.sender;
    //     emit OwnershipTransferred(address(0), msg.sender);
    // }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function ownerAddress() public view returns (address) {
        return owner;
    }

    function transfer(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner);
    }
}
