// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract PremiumDepositBox is IDepositBox {
    address private owner;
    mapping(bytes32 => bool) private secrets;
    mapping(address => uint256) private accessLogs;
    uint256 private secretCount;
    uint256 private constant MAX_SECRETS = 5;

    event AccessLogged(address indexed user, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    function storeSecret(bytes32 secretHash) external override onlyOwner {
        require(secretCount < MAX_SECRETS, "Maximum secrets reached");
        require(!secrets[secretHash], "Secret already exists");
        
        secrets[secretHash] = true;
        secretCount++;
        emit SecretStored(owner, secretHash);
    }

    function retrieveSecret() external override onlyOwner returns (bytes32) {
        // In premium boxes, we return the most recently stored secret
        // This is a simplification - in a real implementation, you'd want to
        // track the order of secrets and allow retrieving specific ones
        bytes32[] memory allSecrets = getAllSecrets();
        require(allSecrets.length > 0, "No secrets stored");
        
        bytes32 secret = allSecrets[allSecrets.length - 1];
        emit SecretRetrieved(owner, secret);
        logAccess(msg.sender);
        return secret;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getBoxType() external pure override returns (string memory) {
        return "Premium";
    }

    function getAllSecrets() public view onlyOwner returns (bytes32[] memory) {
        bytes32[] memory allSecrets = new bytes32[](secretCount);
        uint256 index = 0;
        
        // This is a simplified implementation. In a real contract,
        // you'd want to maintain an ordered list of secrets
        for (uint256 i = 0; i < secretCount; i++) {
            if (secrets[bytes32(i)]) {
                allSecrets[index] = bytes32(i);
                index++;
            }
        }
        return allSecrets;
    }

    function getAccessLogs(address user) external view onlyOwner returns (uint256) {
        return accessLogs[user];
    }

    function logAccess(address user) internal {
        accessLogs[user]++;
        emit AccessLogged(user, block.timestamp);
    }
} 