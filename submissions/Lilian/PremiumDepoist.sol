// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepoist.sol";

contract PremiumDepoist is BaseDepoist{
    string private metadata;//只有在此合约内可以使用

    event metadataupdated (address indexed owner);//更新元数据时更新

    function getBoxType()external pure override returns (string memory){
        return "Premium";//返回premium，可以被前端标记
    }

    function setmetadata(string calldata _metadata)external OnlyOwner{
        metadata=_metadata;//更新存储的值
        emit metadataupdated(msg.sender);//记录变更
    }

    function getMetadata() external view onlyowner returns (string memory){
        return metadata;
    }
}