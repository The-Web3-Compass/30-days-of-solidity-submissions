//SPDX-License-Identifier:MIT

pragma solidity^0.8.0;

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox{

    string private metadata;

    event MetadataChanged(address indexed owner);

    function getBoxType() external pure override returns(string memory){
        return "Premium";
    }
    //报告自己盒子是什么类型
    function setMetadata(string calldata _metadata) external onlyOwner{
        metadata= _metadata;
        emit MetadataChanged(msg.sender); 
    }//修改自己的元数据
    
    function getMetadata() external view onlyOwner returns (string memory){
        return metadata;
    }



}