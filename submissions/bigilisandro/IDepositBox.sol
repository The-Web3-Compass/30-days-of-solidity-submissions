// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositBox {
    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner, bytes32 indexed secretHash);
    event SecretRetrieved(address indexed owner, bytes32 indexed secretHash);
    
    // Functions
    function storeSecret(bytes32 secretHash) external;
    function retrieveSecret() external returns (bytes32);
    function transferOwnership(address newOwner) external;
    function getOwner() external view returns (address);
    function getBoxType() external pure returns (string memory);
} 