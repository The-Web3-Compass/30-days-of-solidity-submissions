// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout {
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _logicContract) {
        require(_logicContract != address(0), "Logic contract cannot be zero address");
        owner = msg.sender;
        logicContract = _logicContract;
        
        // Initialize allowed function selectors
        allowedSelectors[bytes4(keccak256("addPlan(uint8,uint256,uint256)"))] = true;
        allowedSelectors[bytes4(keccak256("subscribe(uint8)"))] = true;
        allowedSelectors[bytes4(keccak256("isActive(address)"))] = true;
        allowedSelectors[bytes4(keccak256("pauseAccount(address)"))] = true;
        allowedSelectors[bytes4(keccak256("resumeAccount(address)"))] = true;
        allowedSelectors[bytes4(keccak256("withdraw()"))] = true;
    }
    
    function upgradeTo(address _newLogic) external onlyOwner {
        require(_newLogic != address(0), "New logic contract cannot be zero address");
        require(_newLogic != logicContract, "Same logic contract");
        
        address oldLogic = logicContract;
        logicContract = _newLogic;
        
        emit LogicUpgraded(oldLogic, _newLogic);
    }
    
    function updateSelector(bytes4 selector, bool allowed) external onlyOwner {
        allowedSelectors[selector] = allowed;
    }
    
    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");
        
        // Extract function selector and validate
        bytes4 selector;
        assembly {
            selector := calldataload(0)
        }
        require(allowedSelectors[selector], "Function not allowed");
        
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