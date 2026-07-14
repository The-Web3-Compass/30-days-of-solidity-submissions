// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SubscriptionLogicV1 {
    struct Subscription {
        address owner;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    mapping(uint256 => Subscription) public subscriptions;
    address public logicContract;
    address public admin;

    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed owner);

    function createSubscription(uint256 subscriptionId, uint256 duration, uint256 price) external {
        require(subscriptions[subscriptionId].owner == address(0), "Subscription already exists");

        subscriptions[subscriptionId] = Subscription({
            owner: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            price: price
        });

        emit SubscriptionCreated(subscriptionId, msg.sender);
    }

    function upgradeSubscription(uint256 subscriptionId, uint256 additionalDuration) external {
        Subscription storage sub = subscriptions[subscriptionId];
        require(sub.owner == msg.sender, "You don't own this subscription");
        
        sub.endTime += additionalDuration;
    }

    function viewSubscription(uint256 subscriptionId) external view returns (address owner, uint256 startTime, uint256 endTime, uint256 price) {
        Subscription storage sub = subscriptions[subscriptionId];
        require(sub.owner != address(0), "Subscription does not exist");
        return (sub.owner, sub.startTime, sub.endTime, sub.price);
    }
}

contract SubscriptionLogicV2 {
    struct Subscription {
        address owner;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    mapping(uint256 => Subscription) public subscriptions;
    address public logicContract;
    address public admin;

    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed owner);
    event SubscriptionPaused(uint256 indexed subscriptionId);

    function createSubscription(uint256 subscriptionId, uint256 duration, uint256 price) external {
        require(subscriptions[subscriptionId].owner == address(0), "Subscription already exists");

        subscriptions[subscriptionId] = Subscription({
            owner: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            price: price
        });

        emit SubscriptionCreated(subscriptionId, msg.sender);
    }

    function upgradeSubscription(uint256 subscriptionId, uint256 additionalDuration) external {
        Subscription storage sub = subscriptions[subscriptionId];
        require(sub.owner == msg.sender, "You don't own this subscription");
        
        sub.endTime += additionalDuration;
    }

    function pauseSubscription(uint256 subscriptionId) external {
        Subscription storage sub = subscriptions[subscriptionId];
        require(sub.owner == msg.sender || msg.sender == admin, "Not authorized to pause");
        
        sub.endTime = block.timestamp;
        emit SubscriptionPaused(subscriptionId);
    }

    function viewSubscription(uint256 subscriptionId) external view returns (address owner, uint256 startTime, uint256 endTime, uint256 price) {
        Subscription storage sub = subscriptions[subscriptionId];
        require(sub.owner != address(0), "Subscription does not exist");
        return (sub.owner, sub.startTime, sub.endTime, sub.price);
    }

    function isSubscriptionActive(uint256 subscriptionId) external view returns (bool) {
        Subscription storage sub = subscriptions[subscriptionId];
        return sub.owner != address(0) && block.timestamp < sub.endTime;
    }
}

contract SubscriptionProxy {
    struct Subscription {
        address owner;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    mapping(uint256 => Subscription) public subscriptions;
    address public logicContract;
    address public admin;

    event SubscriptionCreated(uint256 indexed subscriptionId, address indexed owner);
    event LogicUpgraded(address newLogic);

    constructor(address _logicContract) {
        admin = msg.sender;
        logicContract = _logicContract;
    }

    function upgradeLogic(address _newLogic) external {
        require(msg.sender == admin, "Only admin can upgrade");
        logicContract = _newLogic;
        emit LogicUpgraded(_newLogic);
    }

    fallback() external {
        address logic = logicContract;
        (bool success, bytes memory result) = logic.delegatecall(msg.data);
        require(success, "Logic call failed");
        
        if (result.length > 0) {
            assembly {
                return(add(result, 0x20), mload(result))
            }
        }
    }
}
