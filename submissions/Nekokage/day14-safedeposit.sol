// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 简化版保险箱管理器
contract SimpleVaultManager {
    // 存储每个用户的保险箱地址列表
    mapping(address => address[]) public userVaults;
    
    // 存储每个保险箱的名称
    mapping(address => string) public vaultNames;
    
    // 事件：当创建新保险箱时触发
    event VaultCreated(address indexed owner, address indexed vaultAddress);
    
    // 事件：当给保险箱命名时触发
    event VaultNamed(address indexed vaultAddress, string name);

    // 创建基础保险箱
    function createBasicVault() external returns (address) {
        // 创建新的保险箱合约
        BasicVault newVault = new BasicVault();
        address vaultAddress = address(newVault);
        
        // 记录到用户保险箱列表
        userVaults[msg.sender].push(vaultAddress);
        
        emit VaultCreated(msg.sender, vaultAddress);
        return vaultAddress;
    }

    // 给保险箱起名字
    function nameVault(address vaultAddress, string calldata name) external {
        // 检查调用者是否是保险箱的所有者
        BasicVault vault = BasicVault(vaultAddress);
        require(vault.owner() == msg.sender, "Only vault owner can name it");
        
        vaultNames[vaultAddress] = name;
        emit VaultNamed(vaultAddress, name);
    }

    // 在保险箱中存储秘密
    function storeSecret(address vaultAddress, string calldata secret) external {
        BasicVault vault = BasicVault(vaultAddress);
        require(vault.owner() == msg.sender, "Only vault owner can store secrets");
        
        vault.storeSecret(secret);
    }

    // 获取用户的所有保险箱
    function getUserVaults(address user) external view returns (address[] memory) {
        return userVaults[user];
    }

    // 获取保险箱信息
    function getVaultInfo(address vaultAddress) external view returns (
        address owner,
        string memory name
    ) {
        BasicVault vault = BasicVault(vaultAddress);
        return (
            vault.owner(),
            vaultNames[vaultAddress]
        );
    }
}

// 基础保险箱合约
contract BasicVault {
    address public owner;
    string private secret;
    uint256 public createdTime;
    
    event SecretStored(address indexed owner, uint256 timestamp);
    
    constructor() {
        owner = msg.sender;
        createdTime = block.timestamp;
    }
    
    // 存储秘密
    function storeSecret(string calldata _secret) external {
        require(msg.sender == owner, "Only owner can store secrets");
        secret = _secret;
        emit SecretStored(msg.sender, block.timestamp);
    }
    
    // 获取秘密（只有所有者可以查看）
    function getSecret() external view returns (string memory) {
        require(msg.sender == owner, "Only owner can view the secret");
        return secret;
    }
    
    // 转移所有权
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner can transfer");
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}