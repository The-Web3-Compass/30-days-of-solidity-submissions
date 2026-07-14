// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";
import "./VaultBoxes.sol";

contract VaultManager {
    mapping(address => IDepositBox[]) public userVaults;
    
    event VaultCreated(address indexed user, address vault, string vaultType);
    
    function createBasicVault() external returns (address) {
        BasicDepositBox vault = new BasicDepositBox();
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "Basic");
        return address(vault);
    }
    
    function createPremiumVault() external returns (address) {
        PremiumDepositBox vault = new PremiumDepositBox();
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "Premium");
        return address(vault);
    }
    
    function createTimeLockedVault(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox vault = new TimeLockedDepositBox(lockDuration);
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "TimeLocked");
        return address(vault);
    }

    function createMultiSigDepositVault(address[] memory owners, uint256 required) external returns (address) {
        MultiSigDepositBox vault = new MultiSigDepositBox(owners, required);
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "MultiSig");
        return address(vault);
    }

    function createNFTDepositVault() external returns (address) {
        NFTDepositBox vault = new NFTDepositBox();
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "NFT");
        return address(vault);
    }

    function createRecurringDepositBox( uint amount, uint interval) external returns (address) {
        RecurringDepositBox vault = new RecurringDepositBox(amount, interval);
        userVaults[msg.sender].push(IDepositBox(address(vault)));
        emit VaultCreated(msg.sender, address(vault), "Recurring");
        return address(vault);
    }
    
    function getUserVaults(address user) external view returns (IDepositBox[] memory) {
        return userVaults[user];
    }
    
    function getVaultInfo(address vaultAddress) external view returns (
        string memory vaultType,
        address owner,
        uint256 depositTime
    ) {
        IDepositBox vault = IDepositBox(vaultAddress);
        return (
            vault.getBoxType(),
            vault.getOwner(),
            vault.getDepositTime()
        );
    }
}