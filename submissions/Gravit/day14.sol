// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ISafeDepositBox {
    function owner() external view returns (address);
    function storeSecret(bytes32 secret) external;
    function retrieveSecret() external view returns (bytes32);
    function transferOwnership(address newOwner) external;
    event SecretStored(address indexed owner, bytes32 secret);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

abstract contract SafeDepositBoxBase is ISafeDepositBox {
    address private _owner;
    bytes32 private _secret;

    modifier onlyOwner() {
        require(msg.sender == _owner, "SafeDepositBox: caller is not the owner");
        _;
    }

    constructor(address initialOwner) {
        require(initialOwner != address(0), "SafeDepositBox: invalid owner address");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    function storeSecret(bytes32 secret) public virtual override onlyOwner {
        require(secret != bytes32(0), "SafeDepositBox: secret cannot be empty");
        _secret = secret;
        emit SecretStored(msg.sender, secret);
    }

    function retrieveSecret() public view virtual override onlyOwner returns (bytes32) {
        return _secret;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "SafeDepositBox: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BasicSafeDepositBox is SafeDepositBoxBase {
    constructor(address initialOwner) SafeDepositBoxBase(initialOwner) {}
}

contract PremiumSafeDepositBox is SafeDepositBoxBase {
    bytes32[] private _secretHistory;

    constructor(address initialOwner) SafeDepositBoxBase(initialOwner) {}

    function storeSecret(bytes32 secret) public override onlyOwner {
        super.storeSecret(secret);
        _secretHistory.push(secret);
    }

    function getSecretHistory() public view onlyOwner returns (bytes32[] memory) {
        return _secretHistory;
    }
}

contract TimeLockedSafeDepositBox is SafeDepositBoxBase {
    uint256 private _releaseTime;

    constructor(address initialOwner, uint256 lockDuration) SafeDepositBoxBase(initialOwner) {
        require(lockDuration > 0, "TimeLockedSafeDepositBox: lock duration must be greater than 0");
        _releaseTime = block.timestamp + lockDuration;
    }

    function storeSecret(bytes32 secret) public override onlyOwner {
        require(block.timestamp < _releaseTime, "TimeLockedSafeDepositBox: box is locked");
        super.storeSecret(secret);
    }

    function retrieveSecret() public view override onlyOwner returns (bytes32) {
        require(block.timestamp >= _releaseTime, "TimeLockedSafeDepositBox: secret still locked");
        return super.retrieveSecret();
    }

    function getReleaseTime() public view returns (uint256) {
        return _releaseTime;
    }
}

contract VaultManager {
    mapping(address => address[]) private _userBoxes;

    event BoxCreated(address indexed owner, address boxAddress, string boxType);

    function createBasicBox() public returns (address) {
        BasicSafeDepositBox box = new BasicSafeDepositBox(msg.sender);
        _userBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Basic");
        return address(box);
    }

    function createPremiumBox() public returns (address) {
        PremiumSafeDepositBox box = new PremiumSafeDepositBox(msg.sender);
        _userBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "Premium");
        return address(box);
    }

    function createTimeLockedBox(uint256 lockDuration) public returns (address) {
        TimeLockedSafeDepositBox box = new TimeLockedSafeDepositBox(msg.sender, lockDuration);
        _userBoxes[msg.sender].push(address(box));
        emit BoxCreated(msg.sender, address(box), "TimeLocked");
        return address(box);
    }

    function storeSecretInBox(address boxAddress, bytes32 secret) public {
        ISafeDepositBox box = ISafeDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: caller is not the box owner");
        box.storeSecret(secret);
    }

    function retrieveSecretFromBox(address boxAddress) public view returns (bytes32) {
        ISafeDepositBox box = ISafeDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: caller is not the box owner");
        return box.retrieveSecret();
    }

    function transferBoxOwnership(address boxAddress, address newOwner) public {
        ISafeDepositBox box = ISafeDepositBox(boxAddress);
        require(box.owner() == msg.sender, "VaultManager: caller is not the box owner");
        box.transferOwnership(newOwner);
    }

    function getUserBoxes(address user) public view returns (address[] memory) {
        return _userBoxes[user];
    }
}
