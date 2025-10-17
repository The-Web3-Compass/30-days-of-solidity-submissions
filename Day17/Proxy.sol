// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Proxy {
    address public implementation;
    address public admin;

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    function upgrade(address newImplementation) external {
        require(msg.sender == admin, "Only admin");
        implementation = newImplementation;
    }

    fallback() external payable {
        (bool success, ) = implementation.delegatecall(msg.data);
        require(success, "Delegatecall failed");
    }
}
