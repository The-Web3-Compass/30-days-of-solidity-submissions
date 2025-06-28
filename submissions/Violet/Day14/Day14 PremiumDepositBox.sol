// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Day14 BaseDepositBox.sol";


contract PremiumDepositBox is BaseDepositBox {
    
    mapping(string => string) private _metadata;

    event MetadataSet(string key, string value);

    constructor(address initialOwner) BaseDepositBox(initialOwner) {}

    /**
     * @dev 设置一个元数据键值对 (仅限所有者)。
     */
    function setMetadata(string calldata key, string calldata value) external onlyOwner {
        _metadata[key] = value;
        emit MetadataSet(key, value);
    }

    /**
     * @dev 根据键获取元数据。
     */
    function getMetadata(string calldata key) external view returns (string memory) {
        return _metadata[key];
    }
}
