// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDepositBox.sol";

contract VaultManager {
    mapping(address => address[]) public userVaults;

    event VaultCreated(address indexed user, address vault);
    event OwnershipTransferred(address indexed from, address indexed to, address vault);

    function registerVault(address user, address vault) external {
        userVaults[user].push(vault);
        emit VaultCreated(user, vault);
    }

    function transferVaultOwnership(address vault, address newOwner) external {
        IDepositBox box = IDepositBox(vault);
        require(msg.sender == box.owner(), "Not vault owner");
        box.transferOwnership(newOwner);
        emit OwnershipTransferred(msg.sender, newOwner, vault);
    }

    function totalVaults(address user) external view returns (uint256) {
        return userVaults[user].length;
    }
}
