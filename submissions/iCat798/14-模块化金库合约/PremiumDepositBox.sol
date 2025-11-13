//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./BaseDepositBox.sol";

// 高级型金库，继承自BaseDepositBox，添加额外的元数据metadata（描述秘密内容、注释等）
contract PremiumDepositBox is BaseDepositBox{

    // 新状态变量metadata，私有字段，只有此合约内的函数可以读取或修改它。（我们将为所有者创建外部访问函数。）
    string private metadata;
    event MetadataUpdated(address indexed owner);

    // 识别金库类型
    function getBoxType() override public pure returns(string memory){
        return "Premium";
    } 

    // string calldata _metadata：新的元数据值作为参数传入
    function setMetadata(string calldata _metadata) external onlyOwner{
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }

    // 所有者读取metadata内容
    function getMetadata() external view onlyOwner returns(string memory){
        return metadata;
    }


}