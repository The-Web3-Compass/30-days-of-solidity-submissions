// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// 具备额外的元数据能力
import "./BaseDepositBox.sol";
contract PremiumDepositBox is BaseDepositBox {
    string private  metadata;

    event MetadataUpdated(address indexed owner);

    //接口实现
    function getBoxType()external pure override returns (string memory){
        return  "Premium";
    }

    //增加内容: Metadata
    function updateMetadata(string calldata _metadata)external onlyOwner{
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }
    function getMetadata()external view  onlyOwner returns (string memory){
        return metadata;
    }
}