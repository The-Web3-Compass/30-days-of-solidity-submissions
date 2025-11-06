// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day17-SubscriptionStorageLayout.sol";
/**
 * @title SubscriptionLogicV1
 * @notice 逻辑合约版本1：
 *
 * 功能说明：
 * - 添加订阅套餐
 * - 让用户订阅
 * - 检查用户是否活跃

 *
 * @dev 
 */

contract SubscriptionLogicV1 is SubscriptionStorageLayout{
    function addPlan(uint8 _planId, uint256 _price, uint256 _duration) external{
        planPrices[_planId] = _price;
        planDuration[_planId] = _duration;
    }

    function subscribe(uint8 _planId) external payable {
        require(planPrices[_planId] > 0, "Invaild plan");
        require(planPrices[_planId] <= msg.value, "Not enough money");

        Subscription storage s = subscriptions[msg.sender];
        if(block.timestamp < s.expiry) {
            s.expiry += planDuration[_planId];
        }else {
            s.expiry = block.timestamp + planDuration[_planId];
        }

        s.planId = _planId;
        s.paused = false;
    }

    function isActive(address _user) external view returns (bool){
        Subscription memory s = subscriptions[_user];
        return (block.timestamp < s.expiry && !s.paused);
    }
    
}