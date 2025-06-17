// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//Storage Layout Contract

contract SubscriptionStorageLayout {
    address public owner;
    address public implementation; // Where logic lives

    struct Subscription {
        uint planId;
        uint expiry;
        bool paused;
    }

    mapping(address => Subscription) public subscriptions;
    mapping(uint8 => uint256) public planPrices;
    mapping(uint8 => uint256) public planDuration;
}

//Proxy Contract

contract SubscriptionStorage is SubscriptionStorageLayout {
    constructor(address _implementation) {
        owner = msg.sender;
        implementation = _implementation;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    function upgradeTo(address _implementation) public onlyOwner {
        implementation = _implementation;
    }

    fallback() external payable {
        address impl = implementation;
        require(impl != address(0), "No logic exists");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

//Logic V1 Contract

contract SubscriptionLogicV1 is SubscriptionStorageLayout {
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        uint256 price = planPrices[planId];
        uint256 duration = planDuration[planId];

        require(price > 0, "Plan does not exist");
        require(msg.value >= price, "Insufficient payment");

        subscriptions[msg.sender] = Subscription({
            planId: planId,
            expiry: block.timestamp + duration,
            paused: false
        });
    }

    function isSubscribed(address user) external view returns (bool) {
        Subscription memory sub = subscriptions[user];
        return block.timestamp < sub.expiry && !sub.paused;
    }
}

// Logic V2 Contract
contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    function addPlan(uint8 planId, uint256 price, uint256 duration) external {
        planPrices[planId] = price;
        planDuration[planId] = duration;
    }

    function subscribe(uint8 planId) external payable {
        uint256 price = planPrices[planId];
        uint256 duration = planDuration[planId];

        require(price > 0, "Plan does not exist");
        require(msg.value >= price, "Insufficient payment");

        subscriptions[msg.sender] = Subscription({
            planId: planId,
            expiry: block.timestamp + duration,
            paused: false
        });
    }

    function isSubscribed(address user) external view returns (bool) {
        Subscription memory sub = subscriptions[user];
        return block.timestamp < sub.expiry && !sub.paused;
    }

    function pauseAccount(address user) external {
        subscriptions[user].paused = true;
    }

    function resumeAccount(address user) external {
        subscriptions[user].paused = false;
    }
}
