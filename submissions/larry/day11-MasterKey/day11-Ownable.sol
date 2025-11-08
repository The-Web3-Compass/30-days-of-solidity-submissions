// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function ownerAddress() public view returns(address) {
        return owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");

        address preivous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(preivous, _newOwner);
    }
}