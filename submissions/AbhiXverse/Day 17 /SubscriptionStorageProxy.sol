// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorageProxy is SubscriptionStorageLayout {

    modifier Admin() {
        require(msg.sender == owner, "not the owner");
        _;
    }

    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function upgradetTo(address _newlogic) external Admin {
        logicContract = _newlogic;
    }

    fallback() external payable {
        address _impl = logicContract;
        require(_impl != address(0), "logicContract is not set");
        assembly{
            calldatacopy(0,0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(),0 ,0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
                }
                default {
                    return (0, returndatasize())
                    } 
                }
           }

           receive() external payable{}
}