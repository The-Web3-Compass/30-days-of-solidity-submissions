// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {//继承和导入
    string private metadata;

    event MetadataUpdated(address indexed owner);

    constructor(address initialOwner,address initialManager) 
        BaseDepositBox(initialOwner,initialManager) 
    {}

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
