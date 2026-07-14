// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {
    // 新增状态变量：存储元数据（私有）
    string private metadata;

    // 新增事件：记录元数据更新
    event MetadataUpdated(address indexed owner);

    // 实现接口的getBoxType()：标识为“Premium”类型
    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }

    // 新增功能：设置元数据（仅所有者可调用）
    function setMetadata(string calldata _metadata) external onlyOwner {
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }

    // 新增功能：读取元数据（仅所有者可调用）
    function getMetadata() external view onlyOwner returns (string memory) {
        return metadata;
    }
}