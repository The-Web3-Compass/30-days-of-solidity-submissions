// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private _owner;
    string private _secret;
    uint256 private immutable _depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the box owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _depositTime = block.timestamp;
    }

    function getOwner() public view override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function storeSecret(string calldata secret) public virtual override onlyOwner {
        _secret = secret;
        emit SecretStored(msg.sender);
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return _secret;
    }

    function getDepositTime() public view override returns (uint256) {
        return _depositTime;
    }
}