// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing the IDepositBox interface
import "./IDepositBox.sol";

// Define an abstract contract that implements the IDepositBox interface
abstract contract BaseDepositBox is IDepositBox {

    // Private variables to store owner address, secret string, and deposit timestamp
    address private owner;
    string private secret;
    uint256 private depositTime;

    // Event emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Event emitted when a secret is stored
    event SecretStored(address indexed owner);

    // Constructor sets the deployer as the initial owner and records the deposit time
    constructor(){
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    // Modifier to restrict access to only the current owner
    modifier onlyOwner(){
        require(owner == msg.sender, "Not the owner");
        _;
    }

    // Returns the current owner's address
    function getOwner() public view override returns (address){
        return owner;
    }

    // Allows the current owner to transfer ownership to a new address
    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "Invalid Address");
        emit OwnershipTransferred(owner, newOwner); 
        owner = newOwner;
    }

    // Stores a secret string; only the owner can call this
    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    // Returns the stored secret; only accessible to the owner
    function getSecret() public view virtual override onlyOwner returns (string memory) {
        return secret;
    }

    // Returns the time when the deposit box was created; only accessible to the owner
    function getDepositTime() external view virtual override onlyOwner returns (uint256) {
        return depositTime;
    }
}