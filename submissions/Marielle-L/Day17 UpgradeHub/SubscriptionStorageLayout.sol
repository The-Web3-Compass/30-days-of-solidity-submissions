//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//只包含state variables，不包含任何函数，定义了代理和逻辑合约的内存结构
//通过导入和继承此布局，两个合约可以共享和操作相同的数据
contract SubscriptionStorageLayout{
    address public logicContract;
    address public owner;

    struct Subscription{
        uint8 planId;
        uint256 expiry;
        bool paused;
    }

    mapping(address => Subscription) public subscritions;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;
} 
