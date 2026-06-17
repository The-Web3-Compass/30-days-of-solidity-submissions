// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Logic contract interface
interface ISubscriptionLogic {
    function manageSubscription(bytes calldata data) external;
}

// Proxy contract (UpgradeHub)
contract UpgradeHub {
    address public logicContract; // points to current logic
    address public owner;

    // Storage that persists across upgrades
    struct Subscription {
        string plan;
        uint expiry;
        bool active;
    }
    mapping(address => Subscription) public subscriptions;

    event Upgraded(address indexed oldLogic, address indexed newLogic);
    event Executed(address indexed user, address indexed logic);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _logic) {
        owner = msg.sender;
        logicContract = _logic;
    }

    // Upgrade logic (set new implementation)
    function upgradeLogic(address _newLogic) external onlyOwner {
        require(_newLogic != address(0), "Invalid address");
        emit Upgraded(logicContract, _newLogic);
        logicContract = _newLogic;
    }

    // Delegate all logic calls to current implementation
    function execute(bytes calldata data) external {
        (bool success, ) = logicContract.delegatecall(
            abi.encodeWithSignature("manageSubscription(bytes)", data)
        );
        require(success, "Delegatecall failed");
        emit Executed(msg.sender, logicContract);
    }
}
