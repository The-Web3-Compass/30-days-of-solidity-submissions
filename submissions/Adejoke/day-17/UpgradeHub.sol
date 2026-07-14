// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// SubscriptionStorageLayout.sol blueprint
// It is critical that both logic contracts and the proxy share the EXACT same storage layout.
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
    
    // Day 17 Challenge: adding emergency pause and version tracking
    bool public emergencyPaused;
    string public version;
}

// SubscriptionStorage.sol (Proxy)
contract SubscriptionStorage is SubscriptionStorageLayout {
    
    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // Allow the owner to update the logic contract address
    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }
    
    // The fallback intercepts all function calls and forwards them to the logic contract
    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");
        
        assembly {
            // Copy call data
            calldatacopy(0, 0, calldatasize())
            // Execute logic contract's code in proxy's context
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            // Copy return data
            returndatacopy(0, 0, returndatasize())
            // Return or revert
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}

// SubscriptionLogicV1.sol
contract SubscriptionLogicV1 is SubscriptionStorageLayout {
    
    // We cannot use a constructor to initialize state variables in an upgradeable logic contract.
    // Instead, we use an initialize function that can only be called once.
    bool private initialized;
    
    function initialize() external {
        require(msg.sender == owner, "Only owner");
        require(!initialized, "Already initialized");
        planPrices[1] = 0.01 ether;
        planDuration[1] = 30 days;
        version = "V1";
        initialized = true;
    }
    
    function subscribe(uint8 _planId) external payable {
        require(!emergencyPaused, "System paused");
        require(planPrices[_planId] > 0, "Invalid plan");
        require(msg.value == planPrices[_planId], "Incorrect payment");
        
        subscriptions[msg.sender] = Subscription({
            planId: _planId,
            expiry: block.timestamp + planDuration[_planId],
            paused: false
        });
    }
}

// SubscriptionLogicV2.sol
contract SubscriptionLogicV2 is SubscriptionStorageLayout {
    
    function initializeV2() external {
        require(msg.sender == owner, "Only owner");
        version = "V2 - With pause features";
    }

    function subscribe(uint8 _planId) external payable {
        require(!emergencyPaused, "System paused");
        require(planPrices[_planId] > 0, "Invalid plan");
        require(msg.value == planPrices[_planId], "Incorrect payment");
        
        subscriptions[msg.sender] = Subscription({
            planId: _planId,
            expiry: block.timestamp + planDuration[_planId],
            paused: false
        });
    }
    
    // New functionality in V2:
    function pauseSystem() external {
        require(msg.sender == owner, "Not owner");
        emergencyPaused = true;
    }
    
    function resumeSystem() external {
        require(msg.sender == owner, "Not owner");
        emergencyPaused = false;
    }
    
    function pauseUserSubscription() external {
        require(!emergencyPaused, "System paused");
        require(subscriptions[msg.sender].expiry > block.timestamp, "No active subscription");
        subscriptions[msg.sender].paused = true;
    }
}
