// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleERC20
 * @dev 一个基础的 ERC-20 代币合约。
 */
contract SimpleERC20 {

    // --- 状态变量 ---
    string public name = "Simple Token";
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // 映射：地址 => 余额
    mapping(address => uint256) public balanceOf;
    // 映射：持有者地址 => (被授权者地址 => 授权额度)
    mapping(address => mapping(address => uint256)) public allowance;

    // --- 事件 ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev 构造函数，在部署时铸造初始供应量。
     */
    constructor(uint256 _initialSupply) {
        uint256 scaledSupply = _initialSupply * (10**uint256(decimals));
        totalSupply = scaledSupply;
        balanceOf[msg.sender] = scaledSupply;
        emit Transfer(address(0), msg.sender, scaledSupply);
    }

    /**
     * @dev 直接转账函数。
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev 授权函数。
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev 委托转账函数。
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowance[_from][msg.sender] >= _value, "ERC20: allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev 内部核心转账逻辑，由 transfer 和 transferFrom 调用。
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
    }
}
