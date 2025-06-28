// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LockableERC20
 * @dev 这是一个增加了转账锁定功能的基础ERC20合约。
 * 它的 _beforeTokenTransfer 函数被标记为 virtual，允许子合约重写其行为。
 */
contract LockableERC20 {

    // --- 状态变量 ---
    address public owner;
    bool public transfersLocked;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- 事件 ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // --- 修改器 ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    /**
     * @dev 构造函数，初始化代币并设置所有者。
     */
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        
        uint256 scaledSupply = _initialSupply * (10**uint256(decimals));
        totalSupply = scaledSupply;
        balanceOf[msg.sender] = scaledSupply;
        emit Transfer(address(0), msg.sender, scaledSupply);
    }

    // --- 锁定/解锁函数 (仅限所有者) ---
    function lock() public onlyOwner {
        transfersLocked = true;
    }

    function unlock() public onlyOwner {
        transfersLocked = false;
    }
    
    /**
     * @dev 在每次代币转移前执行的“钩子”函数。
     * 标记为 `virtual` 意味着子合约可以重写(override)这个函数。
     * 新增了 from, to, value 参数以支持更复杂的逻辑。
     */
    function _beforeTokenTransfer(address /*from*/, address /*to*/, uint256 /*value*/) internal view virtual {
        require(!transfersLocked, "ERC20: transfers are locked");
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        // 调用钩子函数并传入参数
        _beforeTokenTransfer(_from, _to, _value);
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowance[_from][msg.sender] >= _value, "ERC20: allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}
