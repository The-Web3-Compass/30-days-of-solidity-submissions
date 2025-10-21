//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//tougher and tougher yesssss

//和web2.0不同的是，web3.0上链之后不能更改，发现bug不能更新修复
//所以需要可升级的合约，将存储与逻辑分离。
//需要四个合约：第一个军师，搞布局的；第二个存数据再把数据发出去
//第三个订阅逻辑，第四个升级订阅逻辑
contract SubscriptionStorageLayout {
    //定义结构，定义了 proxy 和 logic contracts 的内存结构 
    address public logicContract;
    //储存了实际功能所在的 logic contract
    //现在是logic1的，后面会变成logic2的，通过proxy实现
    address public owner;
    //限制owner才能更新升级logic
     struct Subscription {
        uint8 planId;
        //可以用123来标记普通高级超级会员
        uint256 expiry;
        //会员什么时候到期
        bool paused;
        //暂时不续费会员
    }
    mapping(address => Subscription) public subscriptions;
     //定义一个mapping，用来存储每人不同的订阅，到期了没 暂停了没
    mapping(uint8 => uint256) public planPrices;
    //1个月成本5块，两个月8块钱
    mapping(uint8 => uint256) public planDuration;
    //几个月到期

    //军师使用完毕，不可以有function





}

    
    

