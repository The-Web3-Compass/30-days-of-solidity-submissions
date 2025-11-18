// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseDepositBox.sol";

// PremiumDepositBox extends the BaseDepositBox with additional metadata functionality
contract PremiumDepositBox is BaseDepositBox {

    // Private variable to store metadata associated with the premium deposit box
    string private metadata;

    // Event emitted when the metadata is updated
    event MetadataUpdated(address indexed owner);

    // Returns the type of the deposit box as "Premium"
    function getBoxType() override public pure returns(string memory) {
        return "Premium";
    }

    // Allows the owner to set or update the metadata
    function setMetadata(string calldata _metadata) external onlyOwner {
        metadata = _metadata;
        emit MetadataUpdated(msg.sender); // Emit event to log metadata change
    }

    // Allows the owner to view the stored metadata
    function getMetadata() external view onlyOwner returns(string memory) {
        return metadata;
    }
}