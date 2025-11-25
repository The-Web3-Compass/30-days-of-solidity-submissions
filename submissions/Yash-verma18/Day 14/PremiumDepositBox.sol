// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {
    string private metadata;
    event MetadataUpdated(address indexed _owner);

    constructor(address _owner) BaseDepositBox(_owner) {}

    function getBoxType() public pure returns (string memory) {
        return "Premium";
    }

    function setMetadata(string calldata _metadata) external onlyOwner {
        metadata = _metadata;
        emit MetadataUpdated(msg.sender);
    }

    function getMetadata() external view onlyOwner returns (string memory) {
        return metadata;
    }
}
