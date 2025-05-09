// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.18;

import {BaseDepositBox} from "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {

    string private metadata;
    event MetadataUpdated(address indexed owner);

    constructor(address _owner) {
        owner = _owner;
        depositTime = block.timestamp;
    }

    function getBoxType() public pure override returns(string memory) {
        return "Premium Deposit Box";
    }

    function setMetadata(string calldata _metadata) external {
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }

    function getMetadata() external view returns(string memory) {
        return metadata;

    }
 }

