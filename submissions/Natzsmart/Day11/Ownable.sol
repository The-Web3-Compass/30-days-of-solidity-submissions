// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Ownable - A simple contract to manage contract ownership
contract Ownable {
    // Stores the address of the current owner
    address private owner;

    // Event emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Sets the deployer as the initial owner
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender); // Emit event indicating initial ownership
    }

    /// @notice Modifier to restrict functions to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    /// @notice Returns the address of the current owner
    /// @return The address of the contract owner
    function ownerAddress() public view returns (address) {
        return owner;
    }

    /// @notice Allows the current owner to transfer ownership to a new address
    /// @param _newOwner The address to transfer ownership to
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address"); // Prevent transferring to zero address
        address previous = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previous, _newOwner); // Emit event for tracking
    }
}