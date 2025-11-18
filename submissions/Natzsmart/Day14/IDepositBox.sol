// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

// Interface for a DepositBox contract
interface IDepositBox {

    // Returns the address of the current owner of the deposit box
    function getOwner() external view returns(address);

    // Transfers ownership of the deposit box to a new address
    function transferOwnership(address newOwner) external;

    // Allows storing a secret in the deposit box
    function storeSecret(string calldata secret) external;

    // Returns the stored secret (could be used for access control)
    function getSecret() external view returns (string memory);

    // Returns a constant string representing the type of the box
    function getBoxType() external pure returns(string memory);

    // Returns the timestamp of when the deposit was made
    function getDepositTime() external view returns(uint256);
}