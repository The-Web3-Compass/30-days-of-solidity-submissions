// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// Interface for deposit box functionality, ensuring standardized interaction
interface ISafeDepositBox {
    // Returns the current owner of the deposit box
    function owner() external view returns (address);

    // Stores a secret in the deposit box, restricted to the owner
    function storeSecret(bytes32 secret) external;

    // Retrieves the stored secret, restricted to the owner
    function retrieveSecret() external view returns (bytes32);

    // Transfers ownership of the deposit box to a new address
    function transferOwnership(address newOwner) external;

    // Emitted when a secret is stored
    event SecretStored(address indexed owner, bytes32 secret);

    // Emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// Abstract base contract implementing common deposit box logic
abstract contract SafeDepositBoxBase is ISafeDepositBox {
    address private _owner;
    bytes32 private _secret;

    // Ensures only the owner can call certain functions
    modifier onlyOwner() {
        require(msg.sender == _owner, "SafeDepositBox: caller is not the owner");
        _;
    }

    // Initializes the owner during deployment
    constructor(address initialOwner) {
        require(initialOwner != address(0), "SafeDepositBox: invalid owner address");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    // Returns the current owner
    function owner() public view override returns (address) {
        return _owner;
    }

    // Stores a secret, only callable by the owner
    function storeSecret(bytes32 secret) public virtual override onlyOwner {
        require(secret != bytes32(0), "SafeDepositBox: secret cannot be empty");
        _secret = secret;
        emit SecretStored(msg.sender, secret);
    }

    // Retrieves the stored secret, only accessible by the owner
    function retrieveSecret() public view virtual override onlyOwner returns (bytes32) {
        return _secret;
    }

    // Transfers ownership to a new address, only callable by the owner
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "SafeDepositBox: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Basic deposit box with minimal functionality
contract BasicSafeDepositBox is SafeDepositBoxBase {
    // Initializes the basic deposit box with an owner
    constructor(address initialOwner) SafeDepositBoxBase(initialOwner) {}
}

// Premium deposit box with additional secret history tracking
contract PremiumSafeDepositBox is SafeDepositBoxBase {
    bytes32[] private _secretHistory;

    // Initializes the premium deposit box with an owner
    constructor(address initialOwner) SafeDepositBoxBase(initialOwner) {}

    // Stores a secret and adds it to the history
    function storeSecret(bytes32 secret) public override onlyOwner {
        super.storeSecret(secret);
        _secretHistory.push(secret);
    }

    // Retrieves the history of stored secrets, only accessible by the owner
    function getSecretHistory() public view onlyOwner returns (bytes32[] memory) {
        return _secretHistory;
    }
}

// Time-locked deposit box with a release timestamp
contract TimeLockedSafeDepositBox is SafeDepositBoxBase {
    uint256 private _releaseTime;

    // Initializes the time-locked deposit box with an owner and lock duration
    constructor(address initialOwner, uint256 lockDuration) SafeDepositBoxBase(initialOwner) {
        require(lockDuration > 0, "TimeLockedSafeDepositBox: lock duration must be greater than 0");
        _releaseTime = block.timestamp + lockDuration;
    }

    // Stores a secret, only callable by the owner before the release time
    function storeSecret(bytes32 secret) public override onlyOwner {
        require(block.timestamp < _releaseTime, "TimeLockedSafeDepositBox: box is locked");
        super.storeSecret(secret);
    }

    // Retrieves the secret, only accessible by the owner after the release time
    function retrieveSecret() public view override onlyOwner returns (bytes32) {
        require(block.timestamp >= _releaseTime, "TimeLockedSafeDepositBox: secret still locked");
        return super.retrieveSecret();
    }

    // Returns the release time of the lock
    function getReleaseTime() public view returns (uint256) {
        return _releaseTime;
    }
}

// Central manager for interacting with all deposit boxes
contract VaultManager {
    // Mapping of user addresses to their deposit box addresses
    mapping(address => address[]) private _userBoxes;

    // Emitted when a new deposit box is created
    event BoxCreated(address indexed owner, address boxAddress, string boxType);

    // Creates a basic deposit box for the caller
    function createBasicBox() public returns (address) {
        BasicSafeDepositBox box = new BasicSafeDepositBox(msg.sender);
        _userBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    // Creates a premium deposit box for the caller
    function createPremiumBox() public returns (address) {
        PremiumSafeDepositBox box = new PremiumSafeDepositBox(msg.sender);
        _userBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    // Creates a time-locked deposit box for the caller with a specified lock duration
    function createTimeLockedBox(uint256 lockDuration) public returns (address) {
        TimeLockedSafeDepositBox box = new TimeLockedSafeDepositBox(msg.sender, lockDuration);
        _userBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }

    // Stores a secret in a specified deposit box
    function storeSecretInBox(address boxAddress, bytes32 secret) public {
        ISafeDepositBox box = ISafeDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: caller is not the box owner");
        box.storeSecret(secret);
    }

    // Retrieves a secret from a specified deposit box
    function retrieveSecretFromBox(address boxAddress) public view returns (bytes32) {
        ISafeDepositBox box = ISafeDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: caller is not the box owner");
        return box.retrieveSecret();
    }

    // Transfers ownership of a specified deposit box to a new address
    function transferBoxOwnership(address boxAddress, address newOwner) public {
        ISafeDepositBox box = ISafeDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: caller is not the box owner");
        box.transferOwnership(newOwner);
    }

    // Returns all deposit boxes owned by the caller
    function getUserBoxes(address user) public view returns (address[] memory) {
        return _userBoxes[user];
    }
}
