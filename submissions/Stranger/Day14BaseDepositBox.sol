// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Day14IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {
    address private owner;
    string private secret;
    uint256 private depositTime;

    // 属主转移事件 及 秘密存储事件
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this function.");
        _;
    }

    // 查询属主
    function getOwner() public view override returns (address) {
        return owner;
    }

    // 属主转移
    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "Invalid address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // 存储秘密
    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    // 查询秘密
    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    // 查询存款箱部署时间
    function getDepositTime() external view virtual override onlyOwner returns (uint256) {
        return depositTime;
    }
}