// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Ownable - Basic access control mechanism where only the owner can execute restricted functions
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    // Returns the current owner of the contract
    function owner() public view returns (address) {
        return _owner;
    }

    // Transfers ownership to a new address
    // newOwner The address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(newOwner != _owner, "Ownable: already the owner");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
