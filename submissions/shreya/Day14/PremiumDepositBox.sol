// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {
    string public metadata;

    constructor(string memory _initialMetadata) {
        metadata = _initialMetadata;
    }

    function setMetadata(string memory _metadata) public onlyOwner {
        metadata = _metadata;
    }

    function getBoxType() public pure override returns (string memory) {
        return "Premium";
    }
}