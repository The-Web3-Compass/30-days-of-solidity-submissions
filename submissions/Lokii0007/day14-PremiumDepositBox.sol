// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./day14-BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {
    string private metadata;
    event MetadataUpdated(address indexed owner);

    function getBoxType()external pure virtual override returns(string memory){
        return "Premium deposit box";
    }

    function setMetadata(string calldata _metadata) external onlyOwner{
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }

    function getMetadata() public view returns(string memory){
        return metadata;
    }
}