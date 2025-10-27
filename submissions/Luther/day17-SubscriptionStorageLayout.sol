//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//一个独立的存储布局合约,包含任何逻辑函数,只定义了变量和数据结构，用于在代理模式中保存状态数据
//确保逻辑升级时，变量顺序一致、存储布局不变，防止数据错位
contract SubscriptionStorageLayout {

    //保存当前使用的 逻辑合约地址
    address public logicContract;

    //存储合约管理员（通常是部署者）的地址
    address public owner;

    //定义每个用户的订阅信息,结构体会被 mapping 存储和索引
    struct Subscription {
        uint8 planId;
        uint256 expiry;
        bool paused;
    }
    
    //将每个用户的 address 映射到对应的 Subscription 数据
    mapping(address => Subscription) public subscriptions;

    //保存每个套餐 ID 对应的价格（单位：Wei）
    mapping(uint8 => uint256) public planPrices;

    //定义每个套餐的有效期时长（单位：秒）
    mapping(uint8 => uint256) public planDuration;
}