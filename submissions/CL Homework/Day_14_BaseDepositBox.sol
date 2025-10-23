// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day_14_IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    // abstract means this contract cannot be deployed directly.
    address private owner;
    string private secret;
    uint256 private depositTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the box owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        // We use calldata here because it's cheaper on gas when passing in string arguments.
        // Calldata is a non-modifiable, non-persistent area where function arguments are stored and behave mostly like memory.
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    function getDepositTime() external view virtual override returns (uint256) {
        return depositTime;
    }
}
