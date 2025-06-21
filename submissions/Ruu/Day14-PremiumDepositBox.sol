//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox{

    string private metadata;
    event MetadataUpdated(address indexed Owner);

    function GetBoxType() public pure override returns(string memory){
        return "Premium";

    }

    function SetMetadata(string calldata _metadata) external OnlyOwner{
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);

    }

    function GetMetadata() external view OnlyOwner returns(string memory){
        return metadata;

    }
    
}
