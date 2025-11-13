//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SubscriptionLayout{
    //核心  定义基础的变量
    address public owner;
    address public logicAdr;

    struct Subscription{
        uint8 planId;    //用户套餐标识符 
        uint256 expiry;  //套餐到期时间
        bool paused;  //是否停用
    }

    mapping(address => Subscription) scps;  //用户-套餐映射
    mapping(uint8 => uint256) prices; //ID-套餐价格映射
    mapping(uint8 => uint256) durations; //ID-套餐持续时间映射
}