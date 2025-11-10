// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox{
    string private metadata;

    event MetadataUpdated(address indexed owner);

    function setMetadata(string calldata _metadata) external onlyOwner{
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }

    function getMetadata() external view onlyOwner returns(string memory){
        return metadata;
    }

    function getBoxType()public pure override returns(string memory){
        return "Premium";
    }

}