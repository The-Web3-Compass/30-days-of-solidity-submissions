//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./SubscriptionLayout.sol";

contract SubscriptionLogicV1 is SubscriptionLayout{
    //新增套餐
    function addPlan(uint8 planId, uint256 price, uint256 duration) external{
        prices[planId] = price;
        durations[planId] = duration;
    }

    //订阅套餐
    function subscirbe(uint8 planId) external payable{
        require(planId > 0 ,"Invalid id");
        require(msg.value >= prices[planId],"Not enough value");
        //此处如果设置套餐价格为100 那么value写100时 无法通过上述规则  可能交易过程中有损耗
        Subscription storage s = scps[msg.sender];
        s.planId = planId;
        if(block.timestamp < s.expiry){ 
            s.expiry += durations[planId];  //用户原来套餐还未到期时订阅  即现有套餐到期时间加上套餐持续时间
        }else{
            s.expiry = block.timestamp + durations[planId];  //原来套餐到期或没有订阅过  当前时间加上持续时间
        }
        s.paused = false;
    }

    //查看某个用户套餐是否正常使用中 如果正常使用则显示还剩余多长时间（秒） 
    function isActive(address _adr) view external returns(string memory,uint256){
        if(scps[_adr].paused == false && scps[_adr].expiry > block.timestamp){
            return ("yes,time:",scps[_adr].expiry - block.timestamp);
        }else{
            return ("no",0);
        }

    }
}