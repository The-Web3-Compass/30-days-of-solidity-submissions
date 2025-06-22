// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary files
import "./Ownable.sol";
import "./ISafeDepositBox.sol";

/**
 * @title BasicDepositBox
 * @author shivam
 * @notice A simple implementation of a safe deposit box.
 * @dev Inherits ownership functionality from Ownable and implements ISafeDepositBox interface
 */
contract BasicDepositBox is Ownable, ISafeDepositBox {
    /// @notice Stored secret
    string private secret;

    /// @notice Initializes the contract by setting initial owner
    /// @param _initialOwner Initial owner of box
    /// @param _vaultManager The address of the deploying VaultManager contract
    constructor(address _initialOwner, address _vaultManager) Ownable(_initialOwner, _vaultManager) {
        // initial owner is set by ownable constructor
    }

    /// @notice Store a secret string in the box
    /// @param _originalSender The address of the user initiating the action via VaultManager
    /// @param _secret Secret string to store
    function storeSecret(address _originalSender, string memory _secret) external override onlyAllowedCaller(_originalSender) {
        secret = _secret;
    }

    /// @notice Get the stored secret string
    /// @param _originalSender The address of the user initiating the action via VaultManager
    /// @dev Uses onlyAllowedCaller modifier inherited from Ownable.
    /// @return secret Stored secret string
    function getSecret(address _originalSender) external view override onlyAllowedCaller(_originalSender) returns (string memory) {
        return secret;
    }

    /// @notice Get current owner
    /// @return owner Address of current owner
    function getOwner() public view override(Ownable, ISafeDepositBox) returns (address) {
        // Call Ownable's public getOwner function
        return Ownable.getOwner();
    }

    /// @notice Transfers ownership of the contract to a new account (`newOwner`)
    /// @param _originalSender The address of the user initiating the action via VaultManager
    /// @param _newOwner Address of the new owner
    /// @dev Uses onlyAllowedCaller modifier inherited from Ownable and calls internal _transferOwnership.
    function transferOwnership(address _originalSender, address _newOwner) public override(Ownable, ISafeDepositBox) onlyAllowedCaller(_originalSender) {
        // Call the internal function directly to bypass Ownable's specific modifier logic on the public function
        Ownable.transferOwnership(_originalSender, _newOwner);
    }
}