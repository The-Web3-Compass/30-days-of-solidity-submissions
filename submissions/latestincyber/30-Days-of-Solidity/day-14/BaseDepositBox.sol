// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function storeSecret(string calldata _secret) external override onlyOwner {
        secret = _secret;
    }

    function getSecret() external view override returns (string memory) {
        return secret;
    }

    function getDepositTime() external view override returns (uint256) {
        return depositTime;
    }

    function getBoxType() external pure virtual override returns (string memory);
}