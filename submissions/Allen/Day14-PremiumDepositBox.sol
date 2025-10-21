// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Day14-BasicDepositBox.sol";

contract PremiumDepositBox is BasicDepositBox{
    
    // Private means only function within this contract can read or modify it,
    // even though its parent can't read.
    string private metadata;
    
    event MetadataUpdate(address indexed owner);

    function getBoxType() external pure override returns (string memory){
        return "Premium";
    }

    function setMeta(string calldata _metadata) external onlyOwner{
        metadata = _metadata;
        emit MetadataUpdate(msg.sender);
    } 

    function getMeta() external view onlyOwner returns (string memory){
        return metadata;
    }



}