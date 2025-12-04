// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

// 抽象合约：不可直接部署，需被子类继承
abstract contract BaseDepositBox is IDepositBox {
    // 状态变量：私有，仅内部访问
    address private owner;       // 金库所有者
    string private secret;       // 存储的秘密
    uint256 private depositTime; // 金库创建时间（区块时间戳）

    // 事件：记录关键操作（用于前端追踪/链上日志）
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    // 修饰符：限制仅所有者可调用函数
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the box owner");
        _; // 执行函数主体
    }

    // 构造函数：部署时自动设置所有者和创建时间
    constructor() {
        owner = msg.sender;          // 部署者即为初始所有者
        depositTime = block.timestamp; // 记录部署时的区块时间
    }

    // 实现接口函数：获取所有者
    function getOwner() public view override returns (address) {
        return owner;
    }

    // 实现接口函数：转移所有权（仅所有者可调用）
    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address"); // 禁止零地址
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // 实现接口函数：存储秘密（仅所有者可调用）
    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    // 实现接口函数：读取秘密（仅所有者可调用）
    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    // 实现接口函数：获取创建时间
    function getDepositTime() external view virtual override returns (uint256) {
        return depositTime;
    }

    // 未实现接口的getBoxType()：留待子类（具体金库）实现
}