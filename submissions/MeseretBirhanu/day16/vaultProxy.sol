// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract vaultProxy{
    mapping(address => uint256) public deposits;
    uint256 public fee;
    address public owner;
    address public implementation;

    constructor(address _logic) {
        owner = msg.sender;
        implementation = _logic;
    }

    function upgrade(address _newLogic) public {
        require(msg.sender == owner, "Not owner");
        implementation = _newLogic;
    }

    fallback() external payable {
        address _impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}