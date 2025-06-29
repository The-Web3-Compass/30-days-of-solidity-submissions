// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Ownable
 * @dev 可重用的所有权管理基础合约
 * 提供基本的访问控制机制，其中有一个账户（所有者）可以被授予对特定功能的独占访问权限
 */
contract Ownable {
    address private _owner;
    
    // 事件：所有权转移
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev 构造函数，设置合约的初始所有者为部署者
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    /**
     * @dev 返回当前所有者的地址
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    /**
     * @dev 修饰符：限制只有所有者可以调用
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev 将所有权转移给新的地址
     * @param newOwner 新所有者的地址
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(newOwner != _owner, "Ownable: new owner is the same as current owner");
        
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev 内部函数：检查调用者是否为所有者
     */
    function _checkOwner() internal view {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }
}

/**
 * @title VaultMaster
 * @dev 安全金库合约，继承自Ownable
 * 只有主密钥持有者（所有者）可以控制资金和转移所有权
 * 这是一个数字保险箱，只有主密钥持有者可以访问或委托控制权
 */
contract VaultMaster is Ownable {
    // 金库状态
    uint256 private _totalDeposits;
    
    // 映射：记录每个地址的存款
    mapping(address => uint256) private _deposits;
    
    // 事件：存款
    event Deposit(address indexed depositor, uint256 amount, uint256 timestamp);
    
    // 事件：提取
    event Withdrawal(address indexed owner, uint256 amount, uint256 timestamp);
    
    /**
     * @dev 构造函数
     */
    constructor() Ownable() {
    }
    
    /**
     * @dev 接收以太币存款
     */
    receive() external payable {
        require(msg.value > 0, "VaultMaster: deposit amount must be greater than 0");
        
        _deposits[msg.sender] += msg.value;
        _totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev 存款函数
     */
    function deposit() external payable {
        require(msg.value > 0, "VaultMaster: deposit amount must be greater than 0");
        
        _deposits[msg.sender] += msg.value;
        _totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev 只有所有者可以提取指定金额
     * @param amount 要提取的金额
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "VaultMaster: withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "VaultMaster: insufficient balance");
        
        payable(owner()).transfer(amount);
        emit Withdrawal(owner(), amount, block.timestamp);
    }
    
    /**
     * @dev 只有所有者可以提取所有资金
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "VaultMaster: no funds to withdraw");
        
        payable(owner()).transfer(balance);
        emit Withdrawal(owner(), balance, block.timestamp);
    }

    
    /**
     * @dev 获取金库总余额
     */
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 获取总存款记录
     */
    function getTotalDeposits() external view returns (uint256) {
        return _totalDeposits;
    }
    
    /**
     * @dev 获取指定地址的存款记录
     * @param depositor 存款人地址
     */
    function getDepositorBalance(address depositor) external view returns (uint256) {
        return _deposits[depositor];
    }
    

    
    /**
     * @dev 获取合约信息
     */
    function getVaultInfo() external view returns (
        address vaultOwner,
        uint256 currentBalance,
        uint256 totalDepositsRecord
    ) {
        return (
            owner(),
            address(this).balance,
            _totalDeposits
        );
    }
    
    /**
     * @dev 重写所有权转移函数，添加额外的安全检查
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "VaultMaster: new owner cannot be zero address");
        require(newOwner != address(this), "VaultMaster: new owner cannot be the contract itself");
        
        // 调用父合约的转移函数
        super.transferOwnership(newOwner);
    }
    

}
