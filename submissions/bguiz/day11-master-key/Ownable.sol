// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.30;

/**
 * @title Ownable
 */
contract Ownable {
    address public owner;

    event OwnerUpdate(address indexed prevOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnerUpdate(address(0x00), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner allowed to perform this action");
        _;
    }

    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0x00), "null address not allowed to be owner");
        require(newOwner != owner, "cannot set new owner to the previous owner");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
    }
}
