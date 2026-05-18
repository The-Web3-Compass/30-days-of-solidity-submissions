// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";
import "./VaultImplementations.sol";

contract VaultManager {
    mapping(address => IDepositBox[]) private userVaults;

    event VaultCreated(address indexed user, address indexed vault, string vaultType);

    function deployBasicDepositBox() external returns (address) {
        BasicDepositBox vault = new BasicDepositBox();
        userVaults[msg.sender].push(IDepositBox(address(vault)));

        emit VaultCreated(msg.sender, address(vault), "Basic");
        return address(vault);
    }

    function deployPremiumDepositBox() external returns (address) {
        PremiumDepositBox vault = new PremiumDepositBox();
        userVaults[msg.sender].push(IDepositBox(address(vault)));

        emit VaultCreated(msg.sender, address(vault), "Premium");
        return address(vault);
    }

    function deployTimeLockedDepositBox(uint256 lockDurationSeconds) external returns (address) {
        TimeLockedDepositBox vault = new TimeLockedDepositBox(lockDurationSeconds);
        userVaults[msg.sender].push(IDepositBox(address(vault)));

        emit VaultCreated(msg.sender, address(vault), "TimeLocked");
        return address(vault);
    }

    function getVaults(address user) external view returns (IDepositBox[] memory) {
        return userVaults[user];
    }

    function getMyVaults() external view returns (IDepositBox[] memory) {
        return userVaults[msg.sender];
    }
}

// duplicate VaultManager definition removed
