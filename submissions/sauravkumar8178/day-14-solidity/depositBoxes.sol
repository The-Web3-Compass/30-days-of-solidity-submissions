// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { _transferOwnership(msg.sender); }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) { return _owner; }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address old = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }
}

interface IDepositBox {
    function storeSecret(bytes calldata secret) external payable;

    function retrieveSecret() external view returns (bytes memory);

    function transferBoxOwnership(address newOwner) external;

    function owner() external view returns (address);
}

contract BasicBox is Ownable, IDepositBox {
    bytes private _secret;
    event SecretStored(address indexed by, uint256 timestamp);
    event SecretCleared(address indexed by, uint256 timestamp);

    constructor(address initialOwner) {
        _transferOwnership(initialOwner == address(0) ? msg.sender : initialOwner);
    }

    function storeSecret(bytes calldata secret) external payable override {
        _secret = secret;
        emit SecretStored(msg.sender, block.timestamp);
    }

    function retrieveSecret() external view override onlyOwner returns (bytes memory) {
        return _secret;
    }

    function transferBoxOwnership(address newOwner) external override onlyOwner {
        transferOwnership(newOwner);
    }
}

contract PremiumBox is Ownable, IDepositBox {
    bytes private _secret;
    uint256 public storeFee; // wei
    uint256 public collectedFees;
    event SecretStored(address indexed by, uint256 amountPaid, uint256 timestamp);
    event FeesWithdrawn(address indexed by, uint256 amount);

    constructor(address initialOwner, uint256 _storeFee) {
        _transferOwnership(initialOwner == address(0) ? msg.sender : initialOwner);
        storeFee = _storeFee;
    }

    function storeSecret(bytes calldata secret) external payable override {
        require(msg.value >= storeFee, "PremiumBox: insufficient fee");
        collectedFees += msg.value;
        _secret = secret;
        emit SecretStored(msg.sender, msg.value, block.timestamp);
    }

    function retrieveSecret() external view override onlyOwner returns (bytes memory) {
        return _secret;
    }

    function transferBoxOwnership(address newOwner) external override onlyOwner {
        transferOwnership(newOwner);
    }

    function withdrawFees(address payable to) external onlyOwner {
        uint256 amount = collectedFees;
        require(amount > 0, "No fees");
        collectedFees = 0;
        (bool ok,) = to.call{value: amount}("");
        require(ok, "transfer failed");
        emit FeesWithdrawn(to, amount);
    }

    function setStoreFee(uint256 newFee) external onlyOwner {
        storeFee = newFee;
    }

    receive() external payable {
        collectedFees += msg.value;
    }
}

contract TimeLockedBox is Ownable, IDepositBox {
    bytes private _secret;
    uint256 public unlockTimestamp; 
    event SecretStored(address indexed by, uint256 unlockAt, uint256 timestamp);

    constructor(address initialOwner, uint256 initialUnlockTimestamp) {
        _transferOwnership(initialOwner == address(0) ? msg.sender : initialOwner);
        unlockTimestamp = initialUnlockTimestamp;
    }

    function storeSecret(bytes calldata secret) external payable override {
        _secret = secret;
        emit SecretStored(msg.sender, unlockTimestamp, block.timestamp);
    }

    function retrieveSecret() external view override onlyOwner returns (bytes memory) {
        require(block.timestamp >= unlockTimestamp, "TimeLockedBox: still locked");
        return _secret;
    }

    function transferBoxOwnership(address newOwner) external override onlyOwner {
        transferOwnership(newOwner);
    }

    function setUnlockTimestamp(uint256 newTimestamp) external onlyOwner {
        unlockTimestamp = newTimestamp;
    }
}

/// VaultManager: create/register boxes & interact via IDepositBox
contract VaultManager {
    struct BoxInfo {
        address addr;
        address createdBy;
        string boxType;
    }

    BoxInfo[] public boxes;
    mapping(address => uint256) public boxIndex; 

    event BoxCreated(address indexed box, address indexed creator, string boxType);
    event SecretStoredOnBox(address indexed box, address indexed caller, uint256 timestamp);
    event OwnershipTransferredOnBox(address indexed box, address indexed newOwner, uint256 timestamp);

    function createBasicBox() external returns (address) {
        BasicBox b = new BasicBox(msg.sender);
        _registerBox(address(b), msg.sender, "BasicBox");
        return address(b);
    }

    function createPremiumBox(uint256 fee) external returns (address) {
        PremiumBox b = new PremiumBox(msg.sender, fee);
        _registerBox(address(b), msg.sender, "PremiumBox");
        return address(b);
    }

    function createTimeLockedBox(uint256 unlockTimestamp) external returns (address) {
        TimeLockedBox b = new TimeLockedBox(msg.sender, unlockTimestamp);
        _registerBox(address(b), msg.sender, "TimeLockedBox");
        return address(b);
    }

    function registerBox(address boxAddr, string calldata boxType) external {
        require(boxAddr != address(0), "zero address");
        require(boxIndex[boxAddr] == 0, "already registered");
        _registerBox(boxAddr, msg.sender, boxType);
    }

    function _registerBox(address boxAddr, address creator, string memory boxType) internal {
        boxes.push(BoxInfo({addr: boxAddr, createdBy: creator, boxType: boxType}));
        boxIndex[boxAddr] = boxes.length; // store index+1
        emit BoxCreated(boxAddr, creator, boxType);
    }

    function storeOnBox(address boxAddr, bytes calldata secret) external payable {
        require(boxIndex[boxAddr] != 0, "box not registered");
        IDepositBox(boxAddr).storeSecret{value: msg.value}(secret);
        emit SecretStoredOnBox(boxAddr, msg.sender, block.timestamp);
    }

    function retrieveFromBox(address boxAddr) external view returns (bytes memory) {
        require(boxIndex[boxAddr] != 0, "box not registered");
        // IDepositBox implements owner-only retrieval — call will revert if caller not owner.
        return IDepositBox(boxAddr).retrieveSecret();
    }

    function transferBoxOwnership(address boxAddr, address newOwner) external {
        require(boxIndex[boxAddr] != 0, "box not registered");
        IDepositBox(boxAddr).transferBoxOwnership(newOwner);
        emit OwnershipTransferredOnBox(boxAddr, newOwner, block.timestamp);
    }

    function ownerOfBox(address boxAddr) external view returns (address) {
        require(boxIndex[boxAddr] != 0, "box not registered");
        return IDepositBox(boxAddr).owner();
    }

    function boxesCount() external view returns (uint256) {
        return boxes.length;
    }

    receive() external payable {}
}
