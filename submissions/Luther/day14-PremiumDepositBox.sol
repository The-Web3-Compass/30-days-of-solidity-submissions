//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {     //声明一个新的合约 PremiumDepositBox，并通过 is BaseDepositBox 表示它继承自 BaseDepositBox
    string private metadata;     //定义一个私有字符串变量 metadat，存储“高级存款盒”的额外信息

    event MetadataUpdated(address indexed owner);     //定义一个事件（event）MetadataUpdated，当元数据被修改时触发

    //定义一个函数 getBoxType()，用于返回此合约的类型，告诉系统这是一个 "Premium" 类型的存款盒（高级版）
    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }

    //允许合约拥有者修改存款盒的元信息，并在链上记录这次修改
    function setMetadata(string calldata _metadata) external onlyOwner {
        metadata  = _metadata;
        emit MetadataUpdated(msg.sender);
    }
    
    //让合约所有者查看当前存储的 metadata 值，普通用户无法读取，保证了隐私或专属信息的安全性
    function getMetadata() external view onlyOwner returns (string memory) {
        return metadata;
    }
}