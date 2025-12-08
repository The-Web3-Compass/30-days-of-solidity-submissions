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
        require(msg.sender == owner, "not the box owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;

    }

    function getOwner() public view override returns (address) {
        return owner;

    }

    //允许当前所有者将所有权转移给其他人
    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "new owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;

    }

    //存储密钥
    function storeSecret(string calldata _secret) external virtual override onlyOwner {
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