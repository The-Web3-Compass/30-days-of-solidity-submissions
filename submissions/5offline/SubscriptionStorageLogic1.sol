//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day17SubscriptionStorageLayout.sol";

//先写1，后面会在2调用
//一样继承

contract SubscriptionLogicV1 is SubscriptionStorageLayout {
    
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        //用户写入的信息
    planPrices[planId] = price;
    //普通5块，高级8块，超高级10块
    planDuration[planId] = duration;
    //几个月有效
    //这使得订阅系统可自定义
}
function subscribe(uint8 planId) external payable {
    //开始订阅，要付钱的所以用payable
    require(planPrices[planId] > 0, "Invalid plan");
    require(msg.value >= planPrices[planId], "Insufficient payment");
    //两个条件
    Subscription storage s = subscriptions[msg.sender];
    //设置变量叫s
    if (block.timestamp < s.expiry) {
        //看看会员到期没有
        //没到期+上，到期设置一下当前的时间+duration

        s.expiry += planDuration[planId];
    }//没到期 ，延长一下
    else {
        s.expiry = block.timestamp + planDuration[planId];
        //过期了


    }
    s.planId = planId;
    s.paused = false;
    //现在不是暂停状态


}
function isActive(address user) external view returns (bool) {
    Subscription memory s = subscriptions[user];
    return (block.timestamp < s.expiry && !s.paused);
    
}
//检查一下状态，让任何人都可以检查


}
//Version1 函数里的at address输入proxy：直接用 proxy 地址
//代理合约是入口
//保持数据和接口不变
//在 Remix 里，“at address”让你连接到已经部署的合约。
//输入 proxy 的地址后，你就能用 Remix 的界面直接调用代理合约（实际会转发到逻辑合约）。

