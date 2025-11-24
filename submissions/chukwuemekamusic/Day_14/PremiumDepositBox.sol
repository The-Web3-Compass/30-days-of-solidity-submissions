// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseDepositBox} from "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {
    string private metadata;
    mapping (address => bool) public authorizedViewers;

    event MetadataUpdated(address indexed owner, uint256 updatedTime);


    modifier onlyAuthorizedViewers {
        if (!authorizedViewers[msg.sender]) revert BaseDeposit_UnAuthorized();
        _;
    }

    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }

    function getSecret() public view override onlyAuthorizedViewers returns(string memory){
        return _revealSecret();
    }

    function setMetadata(string calldata _metadata) external onlyOwner {
        metadata = _metadata;
        emit MetadataUpdated(msg.sender, block.timestamp);
    }

    function getMetadata() external view onlyAuthorizedViewers returns (string memory) {
        return metadata;
    }
}
