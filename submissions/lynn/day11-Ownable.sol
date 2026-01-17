// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function transferOwner(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner, "Invalide address");

        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function getOwner() public view returns(address) {
        return owner;
    }
}