// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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
    }
    
    function upgradeTo(address _newLogic) external onlyOwner {
        require(_newLogic != address(0), "New logic contract cannot be zero address");
        require(_newLogic != logicContract, "Same logic contract");
        
        address oldLogic = logicContract;
        logicContract = _newLogic;
        
        emit LogicUpgraded(oldLogic, _newLogic);
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