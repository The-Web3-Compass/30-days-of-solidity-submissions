// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract BasicDepositBox is IDepositBox {

    address public override owner;
    string private secret;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function storeSecret(string calldata _secret) external override onlyOwner {
        secret = _secret;
    }

    function readSecret() external view override onlyOwner returns(string memory) {
        return secret;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        owner = newOwner;
    }
}