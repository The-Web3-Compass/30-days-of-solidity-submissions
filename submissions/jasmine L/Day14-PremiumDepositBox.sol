// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Day14-BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox{
    string  private metadata;

    event metadataUpdated(address indexed owner);

    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }

    function setMeta(string calldata _metadata) public onlyOwner{
        metadata =_metadata;
        emit metadataUpdated(msg.sender);
    }

    function getMetadata() public view onlyOwner returns(string memory){
        return metadata;
    } 
}
