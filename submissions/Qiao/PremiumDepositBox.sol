// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {
    
    string private metadata;

    event MetadataUpdated(string indexed metadata);

    function getBoxType() external pure override returns(string memory) {
        return "premium";
    }

    function setMetadata(string calldata _metadata) external onlyOwner {
        metadata = _metadata;
        emit MetadataUpdated(metadata);
    }

    function getMetadata() external view onlyOwner returns(string memory) {
        return metadata;
    }



 }