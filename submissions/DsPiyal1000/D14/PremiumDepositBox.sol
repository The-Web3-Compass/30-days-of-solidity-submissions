// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {
    string private _metadata;

    event MetadataUpdated(address indexed owner);

    function getBoxType() public pure override returns (string memory) {
        return "Premium";
    }

    function setMetadata(string calldata metadata) public onlyOwner {
        _metadata = metadata;
        emit MetadataUpdated(msg.sender);
    }

    function getMetadata() public view onlyOwner returns (string memory) {
        return _metadata;
    }
}