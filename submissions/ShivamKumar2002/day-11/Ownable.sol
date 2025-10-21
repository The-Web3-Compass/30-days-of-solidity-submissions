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

    /// @notice Event emitted when the ownership is transferred from `previousOwner` to `newOwner`.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Error thrown when caller is not owner
    error NotAllowed();

    /// @notice Initializes the contract by setting the contract creator as the initial owner.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /// @notice Get current owner
    /// @return owner Address of current owner
    function getOwner() external view returns (address) {
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

    /// @notice Transfers ownership of the contract to a new account (`newOwner`)
    /// @param _newOwner Address of the new owner
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "invalid new owner address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}