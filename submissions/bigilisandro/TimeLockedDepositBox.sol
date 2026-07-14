// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDepositBox.sol";

contract TimeLockedDepositBox is IDepositBox {
    address private owner;
    bytes32 private storedSecret;
    bool private hasSecret;
    uint256 private lockUntil;
    uint256 private constant MINIMUM_LOCK_TIME = 1 days;
    uint256 private constant MAXIMUM_LOCK_TIME = 365 days;

    event LockPeriodSet(uint256 lockUntil);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier lockPeriodExpired() {
        require(block.timestamp >= lockUntil, "Lock period not expired");
        _;
    }

    function setLockPeriod(uint256 lockDuration) external onlyOwner {
        require(lockDuration >= MINIMUM_LOCK_TIME, "Lock time too short");
        require(lockDuration <= MAXIMUM_LOCK_TIME, "Lock time too long");
        lockUntil = block.timestamp + lockDuration;
        emit LockPeriodSet(lockUntil);
    }

    function storeSecret(bytes32 secretHash) external override onlyOwner {
        require(lockUntil > 0, "Lock period not set");
        storedSecret = secretHash;
        hasSecret = true;
        emit SecretStored(owner, secretHash);
    }

    function retrieveSecret() external override onlyOwner lockPeriodExpired returns (bytes32) {
        require(hasSecret, "No secret stored");
        emit SecretRetrieved(owner, storedSecret);
        return storedSecret;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getBoxType() external pure override returns (string memory) {
        return "TimeLocked";
    }

    function getLockUntil() external view returns (uint256) {
        return lockUntil;
    }

    function isLocked() external view returns (bool) {
        return block.timestamp < lockUntil;
    }
} 