//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day17-SubscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout {

    //定义或更新一个套餐方案
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;     //记录 planId 对应的价格
        planDuration[planId] = duration;     //记录 planId 对应的时长
    }

    //subscribe() —— 订阅或续期
    //用户调用该函数完成订阅购买或续期
    function subscribe(uint8 planId) external payable {

        //检查套餐是否存在（价格大于 0 才合法）
        require(planPrices[planId] > 0, "Invalid plan");

        //检查用户支付金额是否足够
        require(msg.value >= planPrices[planId], "Insufficient payment");
        
        //获取当前用户（msg.sender）的订阅数据引用（storage 类型会修改原始数据）
        Subscription storage s = subscriptions[msg.sender];

        //如果还没过期，则直接延长
        if (block.timestamp < s.expiry) {
            s.expiry += planDuration[planId];

        //如果已经过期，则重新设置新到期时间
        } else {
            s.expiry = block.timestamp + planDuration[planId];
        }

        //更新套餐编号与暂停状态
        s.planId = planId;
        s.paused = false;
    }

    //isActive() —— 查询订阅状态
    //查看某个用户的订阅是否处于“活跃状态”。
    //block.timestamp < s.expiry：没过期
    //!s.paused：没有被暂停
    //两者都满足时返回 true
    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);
    }
    
    //pauseAccount() —— 暂停账户
    //手动暂停某个用户的订阅
    //设置 paused 字段为 true
    //不修改 expiry，也就是说暂停时时间仍然在走
    //通常供管理员使用（例如检测到滥用、退款纠纷等）
    function pauseAccount(address user) external {
        subscriptions[user].paused = true;
    }
    
    //resumeAccount() —— 恢复账户
    //重新启用用户的订阅
    function resumeAccount(address user) external {
        subscriptions[user].paused = false;
    }
}
