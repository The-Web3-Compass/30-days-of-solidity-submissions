// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day17-storageContract.sol";

contract SubscriptionLogicV1 is StorageLayout {
    function addPlan(uint8 _planId, uint256 _price, uint256 _duration) external {
        planPrices[_planId] = _price;
        planDuration[_planId] = _duration;
    }

    function subscribe(uint8 _planId) external payable {
        require(planPrices[_planId] > 0 , "invalid plan");
        require(msg.value >= planPrices[_planId], "insufficient amount");

        Subscription storage sub = subscriptions[msg.sender];

        if(block.timestamp < sub.expiry){
            sub.expiry += planDuration[_planId];
        }else{
           sub.expiry = planDuration[_planId];
        }

        sub.planId = _planId;
        sub.paused = false;
    }

    function isActive(address _user) public view returns(bool){
        Subscription memory sub = subscriptions[_user];
        return (sub.expiry > block.timestamp && !sub.paused);
    }
}