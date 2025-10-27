//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day17-SubscriptionStorageLayout.sol";

contract SubscriptionLogicV1 is SubscriptionStorageLayout {

    //addPlan() —— 定义套餐方案
    //新增或修改一个套餐
    //将套餐编号对应的价格写入 planPrices
    //将套餐编号对应的时长写入 planDuration
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    //subscribe() —— 用户订阅 / 续费功能
    //让用户完成订阅（或续费）
    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");     //验证套餐是否存在
        require(msg.value >= planPrices[planId], "Insufficient payment");     //验证支付金额是否足够

        //从映射中获取当前用户的订阅信息
        //用 storage 是为了修改原数据（不是副本）
        Subscription storage s = subscriptions[msg.sender];

        //如果当前时间小于到期时间（还没过期），则延长有效期
        if (block.timestamp < s.expiry) {
            s.expiry += planDuration[planId];

        //如果已过期，则从现在起重新计算新的到期时间
        } else {
            s.expiry = block.timestamp + planDuration[planId];
        }
        
        //记住用户当前选择的套餐，并自动取消暂停状态（恢复正常使用）
        s.planId = planId;
        s.paused = false;
    }

    //isActive() —— 检查用户是否有效
    //查看某个用户当前是否处于活跃订阅状态
    function isActive(address user) external view returns (bool) {

        //从映射中读取该用户的订阅数据
        Subscription memory s = subscriptions[user];

        //检查两个条件：1.当前时间小于到期时间 2.没有被暂停
        //满足两者则返回 true
        return (block.timestamp < s.expiry && !s.paused);
    }
}
