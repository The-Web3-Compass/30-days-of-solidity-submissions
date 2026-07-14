// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SubscriptionStorageLayout.sol";

// This contract inherits the storage layout defined in SubscriptionStorageLayout.
// The proxy contract handling 'delegatecall'
// It can be used as the storage layer for a proxy pattern, allowing the logic contract to be upgraded without changing the storage layout.

contract SubscriptionStorage is day-17/SubscriptionStorageLayout {
    constructor(address _logicContract) {
        owner = msg.sender;
        require(_logicContract != address(0), "Invalid logic address.");
        require(_logicContract.code.length > 0, "Logic must be a contract.");
        logicContract = _logicContract;

    function upgradeTo(address _newLogic) external {
        require(msg.sender == owner, "You are not the owner.");
        require(_newLogic != address(0), "Invalid logic address.");
        require(_newLogic.code.length > 0, "Logic must be a contract.");
        logicContract = _newLogic;

    fallback() external payable {
        address impl = logicContract;
        require(impl != address(0), "Logic contract not set.");

        assembly {
                    let ptr := mload(0x40)
                    calldatacopy(ptr, 0, calldatasize())
                    let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    switch result
                    case 0 { revert(ptr, size) }
                    default { return(ptr, size) }
        }
    }

    receive() external payable {}
}