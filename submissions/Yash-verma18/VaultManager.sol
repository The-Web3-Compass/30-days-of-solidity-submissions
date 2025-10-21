// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BasicVaultBox, PremiumVaultBox, IVaultBox} from "./VaultBoxes.sol";

contract VaultManager {
    mapping(address => address[]) public userVaults;

    function createBasicVault() public returns (address) {
        address vaultAddress = address(new BasicVaultBox(msg.sender, "basic"));
        userVaults[msg.sender].push(vaultAddress);
        return vaultAddress;
    }

    function createPremiumVault() public returns (address) {
        address vaultAddress = address(
            new PremiumVaultBox(msg.sender, "premium")
        );
        userVaults[msg.sender].push(vaultAddress);
        return vaultAddress;
    }

    function getMyVaults() public view returns (address[] memory) {
        return userVaults[msg.sender];
    }

    // ----------------- VaultManager → IVaultBox Interaction (contract to contract conversation)-----------------
    function getVaultType(address vault) public view returns (string memory) {
        string memory typeOfVault = IVaultBox(vault).typeOfBox();
        return typeOfVault;
    }

    function addItemsInVault(
        address vault,
        string memory item
    ) public returns (bool) {
        IVaultBox(vault).addValuables(item, msg.sender);
        return true;
    }

    function depositETHToVault(address vault) public payable returns (bool) {
        bool success = IVaultBox(vault).depositETH{value: msg.value}(
            msg.sender
        );
        require(success, "Deposit failed");
        return true;
    }

    function withdrawAllFromVault(address vault) public returns (bool) {
        bool success = IVaultBox(vault).withdraw(msg.sender);
        require(success, "Withdraw failed");
        return true;
    }

    function transferOwnerOfVault(
        address vault,
        address newOwner
    ) public returns (bool) {
        bool success = IVaultBox(vault).transferOwnership(newOwner, msg.sender);
        require(success, "Onwership transaction failed");
        return true;
    }

    // extra utility functions
    function getVaultBalance(address vault) public view returns (uint256) {
        return address(vault).balance;
    }

    // Premium vault interaction
    function grantVipAccessToPremiumVault(
        address vault,
        address user
    ) public returns (bool) {
        require(IVaultBox(vault).ownerOfBox() == msg.sender, "Not vault owner");

        PremiumVaultBox(payable(vault)).grantVIP(user, msg.sender);
        return true;
    }

    function isVip(address vault, address user) public view returns (bool) {
        return PremiumVaultBox(payable(vault)).vipAccess(user);
    }
}
