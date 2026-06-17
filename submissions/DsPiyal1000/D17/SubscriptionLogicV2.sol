// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
    
    function addPlan(uint8 planId, uint256 price, uint256 duration) external onlyOwner {
        require(planId > 0, "Plan ID must be greater than 0");
        require(price > 0, "Price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        planPrices[planId] = price;
        planDuration[planId] = duration;
        
        emit PlanAdded(planId, price, duration);
    }
    
    function subscribe(uint8 planId) external payable nonReentrant {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");
        
        Subscription storage s = subscriptions[msg.sender];
        
        if (block.timestamp < s.expiry) {
            s.expiry += planDuration[planId];
        } else {
            s.expiry = block.timestamp + planDuration[planId];
        }
        
        s.planId = planId;
        s.paused = false;
        
        emit UserSubscribed(msg.sender, planId, s.expiry);
        
        if (msg.value > planPrices[planId]) {
            uint256 refund = msg.value - planPrices[planId];
            (bool success, ) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund failed");
        }
    }
    
    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return (block.timestamp < s.expiry && !s.paused);
    }
    
    function pauseAccount(address user) external onlyOwner {
        require(subscriptions[user].expiry > 0, "User has no subscription");
        require(!subscriptions[user].paused, "Account already paused");
        
        subscriptions[user].paused = true;
        emit AccountPaused(user);
    }
    
    function resumeAccount(address user) external onlyOwner {
        require(subscriptions[user].expiry > 0, "User has no subscription");
        require(subscriptions[user].paused, "Account not paused");
        
        subscriptions[user].paused = false;
        emit AccountResumed(user);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}