// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IDepositBox
 * @dev 保险箱接口定义，所有保险箱类型都必须实现此接口
 */
interface IDepositBox {
    // 事件
    event SecretStored(address indexed owner, uint256 timestamp);
    event SecretRetrieved(address indexed owner, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BoxLocked(address indexed owner, uint256 unlockTime);
    event BoxUnlocked(address indexed owner, uint256 timestamp);
    
    // 基本功能
    function storeSecret(string calldata secret) external;
    function retrieveSecret() external view returns (string memory);
    function transferOwnership(address newOwner) external;
    function getOwner() external view returns (address);
    
    // 状态查询
    function isLocked() external view returns (bool);
    function getBoxType() external pure returns (string memory);
    function getBoxInfo() external view returns (
        address owner,
        bool locked,
        string memory boxType,
        uint256 createdAt
    );
}

/**
 * @title BaseDepositBox
 * @dev 保险箱基础抽象合约，提供通用功能
 */
abstract contract BaseDepositBox is IDepositBox {
    // 状态变量
    address public owner;
    string internal secret;
    uint256 public createdAt;
    bool internal _locked;
    
    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseDepositBox: caller is not the owner");
        _;
    }
    
    modifier whenNotLocked() {
        require(!_locked, "BaseDepositBox: box is locked");
        _;
    }
    
    /**
     * @dev 构造函数
     */
    constructor() {
        owner = msg.sender;
        createdAt = block.timestamp;
        _locked = false;
    }
    
    /**
     * @dev 存储秘密
     */
    function storeSecret(string calldata _secret) external virtual override onlyOwner whenNotLocked {
        secret = _secret;
        emit SecretStored(owner, block.timestamp);
    }
    
    /**
     * @dev 获取秘密
     */
    function retrieveSecret() external view virtual override onlyOwner returns (string memory) {
        require(bytes(secret).length > 0, "BaseDepositBox: no secret stored");
        return secret;
    }
    
    /**
     * @dev 转移所有权
     */
    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "BaseDepositBox: new owner is the zero address");
        require(newOwner != owner, "BaseDepositBox: new owner is the same as current owner");
        
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev 获取所有者
     */
    function getOwner() external view override returns (address) {
        return owner;
    }
    
    /**
     * @dev 检查是否锁定
     */
    function isLocked() external view virtual override returns (bool) {
        return _locked;
    }
    
    /**
     * @dev 获取保险箱信息
     */
    function getBoxInfo() external view override returns (
        address boxOwner,
        bool locked,
        string memory boxType,
        uint256 boxCreatedAt
    ) {
        return (owner, _locked, getBoxType(), createdAt);
    }
    
    /**
     * @dev 抽象函数：获取保险箱类型（子合约必须实现）
     */
    function getBoxType() public pure virtual override returns (string memory);
}

/**
 * @title BasicDepositBox
 * @dev 基础保险箱，提供最基本的存储功能
 */
contract BasicDepositBox is BaseDepositBox {
    /**
     * @dev 返回保险箱类型
     */
    function getBoxType() public pure override returns (string memory) {
        return "Basic";
    }
}

/**
 * @title PremiumDepositBox
 * @dev 高级保险箱，支持密码保护功能
 */
contract PremiumDepositBox is BaseDepositBox {
    // 密码保护
    bytes32 private passwordHash; // 密码哈希
    bool public hasPassword; // 是否设置了密码
    
    // 事件
    event PasswordSet(address indexed owner, uint256 timestamp);
    event PasswordChanged(address indexed owner, uint256 timestamp);
    
    // 修饰符
    modifier requirePassword(string calldata password) {
        if (hasPassword) {
            require(
                keccak256(abi.encodePacked(password)) == passwordHash,
                "PremiumDepositBox: incorrect password"
            );
        }
        _;
    }
    
    /**
     * @dev 构造函数，支持设置初始密码
     * @param initialPassword 初始密码（如果为空则不设置密码）
     */
    constructor(string memory initialPassword) {
        if (bytes(initialPassword).length > 0) {
            passwordHash = keccak256(abi.encodePacked(initialPassword));
            hasPassword = true;
            emit PasswordSet(owner, block.timestamp);
        }
    }
    
    /**
     * @dev 设置密码（仅在未设置密码时可用）
     */
    function setPassword(string calldata password) external onlyOwner {
        require(!hasPassword, "PremiumDepositBox: password already set");
        require(bytes(password).length >= 6, "PremiumDepositBox: password too short");
        
        passwordHash = keccak256(abi.encodePacked(password));
        hasPassword = true;
        
        emit PasswordSet(owner, block.timestamp);
    }
    
    /**
     * @dev 更改密码
     */
    function changePassword(string calldata oldPassword, string calldata newPassword) external onlyOwner {
        require(hasPassword, "PremiumDepositBox: no password set");
        require(
            keccak256(abi.encodePacked(oldPassword)) == passwordHash,
            "PremiumDepositBox: incorrect old password"
        );
        require(bytes(newPassword).length >= 6, "PremiumDepositBox: new password too short");
        
        passwordHash = keccak256(abi.encodePacked(newPassword));
        
        emit PasswordChanged(owner, block.timestamp);
    }
    
    /**
     * @dev 验证密码
     */
    function verifyPassword(string calldata password) external view onlyOwner returns (bool) {
        if (!hasPassword) return true;
        return keccak256(abi.encodePacked(password)) == passwordHash;
    }
    

    
    /**
     * @dev 存储秘密（需要密码验证）
     */
    function storeSecretWithPassword(string calldata _secret, string calldata password) external onlyOwner whenNotLocked requirePassword(password) {
        secret = _secret;
        emit SecretStored(owner, block.timestamp);
    }
    
    /**
     * @dev 获取秘密（需要密码验证）
     */
    function retrieveSecretWithPassword(string calldata password) external view onlyOwner requirePassword(password) returns (string memory) {
        require(bytes(secret).length > 0, "PremiumDepositBox: no secret stored");
        return secret;
    }
    
    /**
     * @dev 保持向后兼容的存储秘密函数（无密码保护时使用）
     */
    function storeSecret(string calldata _secret) external override onlyOwner whenNotLocked {
        require(!hasPassword, "PremiumDepositBox: use storeSecretWithPassword for password-protected box");
        secret = _secret;
        emit SecretStored(owner, block.timestamp);
    }
    
    /**
     * @dev 保持向后兼容的获取秘密函数（无密码保护时使用）
     */
    function retrieveSecret() external view override onlyOwner returns (string memory) {
        require(!hasPassword, "PremiumDepositBox: use retrieveSecretWithPassword for password-protected box");
        require(bytes(secret).length > 0, "PremiumDepositBox: no secret stored");
        return secret;
    }
    
    /**
     * @dev 返回保险箱类型
     */
    function getBoxType() public pure override returns (string memory) {
        return "Premium";
    }
}

/**
 * @title TimeLockedDepositBox
 * @dev 时间锁定保险箱，支持设置解锁时间
 */
contract TimeLockedDepositBox is BaseDepositBox {
    uint256 public unlockTime;
    uint256 public lockDuration;
    
    // 事件
    event TimeLockSet(address indexed owner, uint256 unlockTime, uint256 duration);
    
    /**
     * @dev 构造函数
     * @param _lockDuration 锁定持续时间（秒）
     */
    constructor(uint256 _lockDuration) {
        lockDuration = _lockDuration;
        if (_lockDuration > 0) {
            unlockTime = block.timestamp + _lockDuration;
            _locked = true;
            emit TimeLockSet(owner, unlockTime, _lockDuration);
        }
    }
    
    /**
     * @dev 设置时间锁
     */
    function setTimeLock(uint256 duration) external onlyOwner {
        require(duration > 0, "TimeLockedDepositBox: duration must be greater than 0");
        
        unlockTime = block.timestamp + duration;
        lockDuration = duration;
        _locked = true;
        
        emit BoxLocked(owner, unlockTime);
        emit TimeLockSet(owner, unlockTime, duration);
    }
    
    /**
     * @dev 检查是否可以解锁
     */
    function canUnlock() public view returns (bool) {
        return block.timestamp >= unlockTime;
    }
    
    /**
     * @dev 解锁保险箱
     */
    function unlock() external onlyOwner {
        require(_locked, "TimeLockedDepositBox: box is not locked");
        require(canUnlock(), "TimeLockedDepositBox: unlock time not reached");
        
        _locked = false;
        emit BoxUnlocked(owner, block.timestamp);
    }
    
    /**
     * @dev 重写锁定状态检查
     */
    function isLocked() external view override returns (bool) {
        if (!_locked) return false;
        return !canUnlock();
    }
    
    /**
     * @dev 获取剩余锁定时间
     */
    function getRemainingLockTime() external view returns (uint256) {
        if (!_locked || canUnlock()) return 0;
        return unlockTime - block.timestamp;
    }
    
    /**
     * @dev 返回保险箱类型
     */
    function getBoxType() public pure override returns (string memory) {
        return "TimeLocked";
    }
}

/**
 * @title VaultManager
 * @dev 中央保险箱管理合约，统一管理所有类型的保险箱
 */
contract VaultManager {
    // 状态变量
    address public admin;
    uint256 public totalBoxes;
    
    // 保险箱注册表
    mapping(address => bool) public registeredBoxes;
    mapping(address => address[]) public userBoxes;
    
    // 事件
    event BoxCreated(address indexed boxAddress, address indexed owner, string boxType);
    
    /**
     * @dev 构造函数
     */
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev 创建基础保险箱
     */
    function createBasicBox() external returns (address) {
        BasicDepositBox newBox = new BasicDepositBox();
        newBox.transferOwnership(msg.sender);
        
        address boxAddress = address(newBox);
        _registerBox(boxAddress, msg.sender);
        
        emit BoxCreated(boxAddress, msg.sender, "Basic");
        return boxAddress;
    }
    
    /**
     * @dev 创建高级保险箱
     */
    function createPremiumBox(string calldata password) external returns (address) {
        PremiumDepositBox newBox = new PremiumDepositBox(password);
        newBox.transferOwnership(msg.sender);
        
        address boxAddress = address(newBox);
        _registerBox(boxAddress, msg.sender);
        
        emit BoxCreated(boxAddress, msg.sender, "Premium");
        return boxAddress;
    }
    
    /**
     * @dev 创建时间锁定保险箱
     */
    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox newBox = new TimeLockedDepositBox(lockDuration);
        newBox.transferOwnership(msg.sender);
        
        address boxAddress = address(newBox);
        _registerBox(boxAddress, msg.sender);
        
        emit BoxCreated(boxAddress, msg.sender, "TimeLocked");
        return boxAddress;
    }
    
    /**
     * @dev 内部函数：注册保险箱
     */
    function _registerBox(address boxAddress, address owner) internal {
        registeredBoxes[boxAddress] = true;
        userBoxes[owner].push(boxAddress);
        totalBoxes++;
    }
    
    /**
     * @dev 获取用户的保险箱列表
     */
    function getUserBoxes(address user) external view returns (address[] memory) {
        return userBoxes[user];
    }
    
    /**
     * @dev 检查保险箱是否已注册
     */
    function isBoxRegistered(address boxAddress) external view returns (bool) {
        return registeredBoxes[boxAddress];
    }
}
