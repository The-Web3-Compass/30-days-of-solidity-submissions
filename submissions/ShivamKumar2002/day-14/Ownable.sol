// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Ownable
 * @author shivam
 * @notice A basic contract which can be owned.
 * @dev This contract is intended to be inherited by other contracts.
 */
contract Ownable {
    address private owner;
    /// @notice Address of the trusted VaultManager contract allowed to make calls on owner's behalf
    address public immutable vaultManagerAddress;

    /// @notice Event emitted when the ownership is transferred from `previousOwner` to `newOwner`.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Error thrown when caller is not owner
    error NotAllowed();

    /// @notice Initializes the contract by setting initial owner
    /// @param _vaultManager Address of the trusted VaultManager contract
    /// @param _initialOwner Initial owner of box
    constructor(address _initialOwner, address _vaultManager) {
        require(_initialOwner != address(0), "Ownable: initial owner is the zero address");
        require(_vaultManager != address(0), "Ownable: vault manager is the zero address");
        owner = _initialOwner;
        vaultManagerAddress = _vaultManager;
        emit OwnershipTransferred(address(0), _initialOwner);
    }

    /// @notice Get current owner
    /// @return owner Address of current owner
    function getOwner() public view virtual returns (address) {
        return owner;
    }

    /// @notice Ensures that caller is owner of the contract
    /// @custom:error NotAllowed if caller is not owner
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert NotAllowed();
        }
        _;
    }

    /// @notice Modifier to check if the caller is the owner OR the trusted VaultManager acting for the owner.
    /// @param _originalSender The claimed original user address (passed by VaultManager).
    modifier onlyAllowedCaller(address _originalSender) {
        if ((msg.sender != owner) && (msg.sender != vaultManagerAddress || _originalSender != owner)) {
            revert NotAllowed();
        }
        _;
    }

    /// @notice Transfers ownership of the contract to a new account (`newOwner`)
    /// @param _originalSender The address of the user initiating the action via VaultManager
    /// @param _newOwner Address of the new owner
    function transferOwnership(address _originalSender, address _newOwner) public virtual onlyAllowedCaller(_originalSender) {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}