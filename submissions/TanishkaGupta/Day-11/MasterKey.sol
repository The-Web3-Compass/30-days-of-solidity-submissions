// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MasterKey {

    address public owner;
    string private secretData;

    // Event for ownership transfer
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // Event when secret data is updated
    event SecretUpdated(string newSecret);

    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict access
    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only owner allowed");
        _;
    }

    // Function to update secret data (only owner)
    function updateSecret(string memory _secret) public onlyOwner {
        secretData = _secret;
        emit SecretUpdated(_secret);
    }

    // Function to read secret data
    function getSecret() public view returns (string memory) {
        return secretData;
    }

    // Transfer ownership to another address
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");

        address oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}