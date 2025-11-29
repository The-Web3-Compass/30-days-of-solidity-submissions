// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//代理合约，拥有数据，可以随时升级到新的逻辑合约

import "./subscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout {
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;

    }

    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;

    }

    functioin upgradeTo(address _newLogic) external onlyOwner {
        logicContract = _newLogic;

    }

    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "logic contract not set");

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