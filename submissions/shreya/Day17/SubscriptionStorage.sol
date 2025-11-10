// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout {
    event Upgraded(address indexed implementation);

    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function upgradeTo(address newLogicContract) external {
        require(msg.sender == owner, "Only owner can upgrade");
        logicContract = newLogicContract;
        emit Upgraded(newLogicContract);
    }

    fallback() external payable {
        _delegate(logicContract);
    }

    receive() external payable {
        _delegate(logicContract);
    }

    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
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
}