//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;

import "./Day14BaseDepositBox.sol";

// Give the deposit box something extra: a piece of data called metadata
// Features: "metadata" could describe what the secret is about, when it shouble be accessed or any other note you want to attach.
contract PremiumDepositBox is BaseDepositBox{

    string private metadata;
    event MetadataUpdated(address indexed owner);

    function getBoxType() override public pure returns(string memory){
        return "Premium";
    }

    function setMetadata(string calldata _metadata) external onlyOwner{
        metadata=_metadata;
        emit MetadataUpdated(msg.sender);
    }

    function getMetadata() external view onlyOwner returns(string memory){
        return metadata;
    }

}