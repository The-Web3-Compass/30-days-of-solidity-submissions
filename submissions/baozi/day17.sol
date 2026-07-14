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
     
import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout {
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
