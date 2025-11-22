//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./day17-SubscriptionStorageLayout.sol";

contract SubscriptionStorage is SubscriptionStorageLayout {
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor(address _contractAddress) {
        currentLogicContract = _contractAddress;
        owner = msg.sender;
    }

    function updateLogicContract(address _contractAddress) external onlyOwner {
        currentLogicContract = _contractAddress;
    }

    fallback() external payable {
        address impl = currentLogicContract;
        require(impl != address(0), "Not set logic contract");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {revert(0, returndatasize())}
            default {return(0, returndatasize())}
        }
    }

    receive() external payable {}
}