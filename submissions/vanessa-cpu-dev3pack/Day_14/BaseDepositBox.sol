// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function getDepositTime() external view virtual override returns (uint256) {
        return depositTime;
    }

    function getBoxType() external pure virtual override returns (string memory);
}