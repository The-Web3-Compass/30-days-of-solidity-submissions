// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        depositTime = block.timestamp;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    function getDepositTime() public view override returns (uint256) {
        return depositTime;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function storeSecret(string calldata _secret) external override onlyOwner {
        secret = _secret;
    }

    function getBoxType() external view virtual override returns (string memory);
}