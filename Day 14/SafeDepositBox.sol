// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Common interface for all deposit boxes
interface IDepositBox {
    function deposit(string calldata secret) external;
    function getSecret() external view returns (string memory);
    function transferOwnership(address newOwner) external;
    function getOwner() external view returns (address);
}

// Basic deposit box implementing the interface
contract SafeDepositBox is IDepositBox {
    address private owner;
    string private secret;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function deposit(string calldata _secret) external override onlyOwner {
        secret = _secret;
    }

    function getSecret() external view override onlyOwner returns (string memory) {
        return secret;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }
}

// VaultManager interacts with multiple deposit boxes
contract VaultManager {
    mapping(address => address[]) public userVaults;

    event VaultCreated(address indexed owner, address vaultAddress);

    // Deploy a new personal deposit box
    function createVault() external {
        SafeDepositBox newVault = new SafeDepositBox(msg.sender);
        userVaults[msg.sender].push(address(newVault));
        emit VaultCreated(msg.sender, address(newVault));
    }

    // View all vaults owned by a user
    function getVaults(address user) external view returns (address[] memory) {
        return userVaults[user];
    }
}
