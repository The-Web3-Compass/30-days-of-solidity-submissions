// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract BasicDepositBox is IDepositBox {
    address private owner;
    bytes32 private storedSecret;
    bool private hasSecret;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function storeSecret(bytes32 secretHash) external override onlyOwner {
        storedSecret = secretHash;
        hasSecret = true;
        emit SecretStored(owner, secretHash);
    }

    function retrieveSecret() external override onlyOwner returns (bytes32) {
        require(hasSecret, "No secret stored");
        emit SecretRetrieved(owner, storedSecret);
        return storedSecret;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getBoxType() external pure override returns (string memory) {
        return "Basic";
    }
} 