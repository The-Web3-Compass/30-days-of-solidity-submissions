// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {//关键字 abstract 表示这个合约不能直接部署。它是充当其他合约构建的模板或地基。
    address private owner;//存储拥有此存款箱人员的地址
    address private manager;//用来信任ValutManager
    string private secret;//用户可以安全地存储在该存款箱中的私有字符串
    uint256 private depositTime;//记录存款箱部署的准确时间（Unix 时间戳）

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);//当存储新秘密时触发。

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the box owner");
        _;
    }

    //constructor() {//该金库在创建时自动设置所有权和时间跟踪
        //owner = msg.sender;
        //depositTime = block.timestamp;
    //}

    constructor(address initialOwner,address initialManager) {
    owner = initialOwner; 
    manager = initialManager;
    depositTime = block.timestamp;
    }


    //constructor(address initialOwner) { owner = initialOwner; depositTime = block.timestamp; }

    function getOwner() public view override returns (address) {//返回金库的当前所有者。这是一个简单的 getter 函数
        return owner;
    }

    function transferOwnership(address newOwner) external virtual  override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function transferOwnershipByManager(address newOwner) external {
        require(msg.sender == manager, "Not the manager");
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function storeSecret(string calldata _secret) external virtual override onlyOwner {//calldata，因为在传递字符串参数时，它在 gas 上更便宜。
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function storeSecretByManager(address ownerAddress, string calldata _secret) external {
        require(msg.sender == manager, "Not the manager");
        secret = _secret;
        emit SecretStored(ownerAddress); 
}

    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    function getDepositTime() external view virtual  override returns (uint256) {
        return depositTime;
    }
}
