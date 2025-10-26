// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14_IDepositBox.sol";

/*
    abstract 用来声明一个抽象合约，它不能被直接部署，只能被继承。
    有转态变量
    有实现函数
    有接口
    不可部署，只可以被继承
    有构造函数
    子合约必须实现接口函数

*/
abstract contract BaseDepositBox is IDepositBox {
    // box 拥有者
    address private owner;
    // box中保存的字符串
    string private secret;
    // box 创建时间
    uint private depositTime;

    constructor(){
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    modifier checkBoxOwner(){
        require(msg.sender != owner,"not the box owner ");
        _;
    }
    // box 转移拥有者
    event transferNewOwner(address indexed oldOwner, address indexed newOwner);
    // box 内保存数据
    event storeSecretInBox(address indexed owner);

    // 返回当前box 拥有者
    function getOwner() external view returns (address){
        return owner;
    }
    // 将box所有权转让给其他人
    function transferOwnership(address newOwner) external checkBoxOwner{
        require(newOwner != address(0), unicode"不能是零地址");
        emit transferNewOwner(owner, newOwner);
        owner = newOwner;
    }
    // 保存一个字符串到box中
    function storeSecret(string calldata _secret) external   checkBoxOwner{
        secret = _secret;
        emit storeSecretInBox(owner);
    }
    // 查询存储的秘密string
    function getSecret() public  view virtual checkBoxOwner returns (string memory) {
        return secret;
    }
    // 查询box创建时间
    function getDepositTime() external view returns (uint256){
        return depositTime;
    }

}