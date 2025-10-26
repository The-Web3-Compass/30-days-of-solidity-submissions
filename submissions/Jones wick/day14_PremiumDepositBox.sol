  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14_BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {
    string private metadata;

    event MetadataUpdated(address indexed owner);

    constructor(address _owner) BaseDepositBox(_owner){
    }
    
    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }

    function setMetadata(string calldata _metadata) external onlyOwner {
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }

    function getMetadata() external view onlyOwner returns (string memory) {
        return metadata;
    }
}
