  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

// 继承自base合约
contract PremiumDepositBox is BaseDepositBox {
    // 定义一段metadata
    // 为啥要加一个这个？？？？
    string private metadata;

    event MetadataUpdated(address indexed owner);
    // 类似定义一个boxtype
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

