// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ERC20 代币接口定义
interface IERC20 {
    function totalSupply() external view returns (uint256);               // 查询总供应量
    function balanceOf(address account) external view returns (uint256); // 查询某地址余额
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);                                                  // 向某地址转账
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);                                               // 查看授权额度
    function approve(address spender, uint256 amount) external returns (bool); // 授权额度
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);                                                  // 授权转账
}

/// @title Ownable 权限控制合约
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    /// @notice 仅限合约拥有者调用的函数
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice 转移所有权
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/// @title ERC20 合约实现
contract ERC20 is IERC20, Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);   // 转账事件
    event Approval(address indexed owner, address indexed spender, uint256 value); // 授权事件

    uint256 public totalSupply;                    // 代币总供应量
    mapping(address => uint256) public balanceOf;  // 每个地址的余额
    mapping(address => mapping(address => uint256)) public allowance; // 授权额度映射
    string public name;        // 代币名称
    string public symbol;      // 代币符号
    uint8 public decimals;     // 精度（小数位数）

    /// @dev 构造函数，初始化代币的名称、符号和小数位数
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @notice 用户直接转账
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(recipient != msg.sender, "Cannot transfer to self");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;         // 从发送者扣除
        balanceOf[recipient] += amount;          // 给接收者增加
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice 用户授权某地址可花费其代币
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Approve to zero address");

        allowance[msg.sender][spender] = amount; // 设置授权额度
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice 授权转账（spender 使用 owner 的代币）
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool)
    {
        require(sender != address(0) && recipient != address(0), "Invalid address");
        require(sender != recipient, "Cannot transfer to self");
        require(balanceOf[sender] >= amount, "Insufficient sender balance");
        require(allowance[sender][msg.sender] >= amount, "Insufficient allowance");

        allowance[sender][msg.sender] -= amount;  // 减少剩余授权额度
        balanceOf[sender] -= amount;              // 扣除发送者余额
        balanceOf[recipient] += amount;           // 增加接收者余额
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /// @dev 内部函数：铸造新币
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");

        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount); // 从 0 地址转出代表铸币
    }

    /// @dev 内部函数：销毁代币
    function _burn(address from, uint256 amount) internal {
        require(balanceOf[from] >= amount, "Burn amount exceeds balance");

        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount); // 转到 0 地址代表销毁
    }

    /// @notice 外部调用接口：铸币
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice 外部调用接口：销毁代币
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

/// @title 自定义代币合约
contract MyFirstToken is ERC20 {

    /// @notice 部署时初始化参数并铸造代币给部署者
    constructor(string memory name, string memory symbol, uint8 decimals)
        ERC20(name, symbol, decimals)
    {
        _mint(msg.sender, 100 * 10 ** uint256(decimals)); // 初始发行给部署者
    }
}