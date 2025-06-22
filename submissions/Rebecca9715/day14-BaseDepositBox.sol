// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14-IDepositBox.sol";

// 定义一个抽象合约，virtual
abstract contract BaseDepositBox is IDepositBox {
    // 所有想要获取的人需要走一段程序：public getter function，也就是interface提供的external function
    // 存款人的相关profile
    address private owner;
    // secret为一段私密的需要保存的字符串
    string private secret;
    uint256 private depositTime;

// 定义事件如更改owner、secret存储，以及定义modifier器
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the box owner");
        _;
    }

    // 部署时定义当前时间为取钱时间
    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external virtual  override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    function getDepositTime() external view virtual  override returns (uint256) {
        return depositTime;
    }
}
