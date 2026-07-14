// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perfrom this action.");
        _;
    }

    constructor () {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function getOwner() external override view returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner{
        require(newOwner != address(0), "Invalid address.");
        require(newOwner != owner, "Already the owner.");

        address prevOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(prevOwner, owner);
    }

    function storeSecret(string calldata _secret) external override onlyOwner{
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    function getDepositTime() public view virtual override returns (uint256) {
        return depositTime;
    }
 }