// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day17-storageContract.sol";

contract SubscriptionStorageProxy is StorageLayout {
    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function upgardeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;
    }

    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "logic contract isnt set.");
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
    
    receive() external payable {

    }
}
