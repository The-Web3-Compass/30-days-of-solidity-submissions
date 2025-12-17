// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout {
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    //the initial contract depolyed for interacting.
    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }
    //change interacted contract.
    function upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set");
    //Yul call
        assembly {
            calldatacopy(0, 0, calldatasize())//calldatacopy(destOffset, offset, length)
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)//run logic at logic contract
            returndatacopy(0, 0, returndatasize())//returndatacopy(destOffset, offset, length)

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}
