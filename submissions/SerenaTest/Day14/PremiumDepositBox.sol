//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox{

    string private metadata;  //附加一个私有的字符串
    event MetadataUpdated(address indexed owner);

    function getBoxType() override public pure returns(string memory){
        return "Premium";
    } 

    function setMetadata(string calldata _metadata) external onlyOwner{
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }

    function getMetadata() external view onlyOwner returns(string memory){
        return metadata;
    }


}