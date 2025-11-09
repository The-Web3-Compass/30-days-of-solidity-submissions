// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionStorageLayout {
    address public logicContract;
    address public owner;
    
    struct Subscription {
        uint8 planId;
        uint256 expiry;
        bool paused;
    }
    
    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;
}

contract SubscriptionProxy is SubscriptionStorageLayout {
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

// 第一个版本逻辑合约
contract SubscriptionLogicV1 is SubscriptionStorageLayout {
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");

        Subscription storage userSub = subscriptions[msg.sender];
        if (block.timestamp < userSub.expiry) {
            userSub.expiry += planDuration[planId];
        } else {
            userSub.expiry = block.timestamp + planDuration[planId];
        }

        userSub.planId = planId;
        userSub.paused = false;
    }

    function isActive(address user) external view returns (bool) {
        Subscription memory userSub = subscriptions[user];
        return (block.timestamp < userSub.expiry && !userSub.paused);
    }

    function getUserSubscription(address user) external view returns (uint8 planId, uint256 expiry, bool paused) {
        Subscription memory userSub = subscriptions[user];
        return (userSub.planId, userSub.expiry, userSub.paused);
    }
}

// 升级版本逻辑合约 - 添加暂停功能
contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        require(planPrices[planId] > 0, "Invalid plan");
        require(msg.value >= planPrices[planId], "Insufficient payment");

        Subscription storage userSub = subscriptions[msg.sender];
        if (block.timestamp < userSub.expiry) {
            userSub.expiry += planDuration[planId];
        } else {
            userSub.expiry = block.timestamp + planDuration[planId];
        }

        userSub.planId = planId;
        userSub.paused = false;
    }

    function isActive(address user) external view returns (bool) {
        Subscription memory userSub = subscriptions[user];
        return (block.timestamp < userSub.expiry && !userSub.paused);
    }

    function getUserSubscription(address user) external view returns (uint8 planId, uint256 expiry, bool paused) {
        Subscription memory userSub = subscriptions[user];
        return (userSub.planId, userSub.expiry, userSub.paused);
    }

    // V2 新增功能：暂停和恢复订阅
    function pauseSubscription() external {
        subscriptions[msg.sender].paused = true;
    }

    function resumeSubscription() external {
        subscriptions[msg.sender].paused = false;
    }

    function adminPause(address user) external {
        require(msg.sender == owner, "Only owner can pause other users");
        subscriptions[user].paused = true;
    }

    function adminResume(address user) external {
        require(msg.sender == owner, "Only owner can resume other users");
        subscriptions[user].paused = false;
    }
}