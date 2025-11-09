// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {
    string public name = "ThreeBody";
    string public symbol = "TB";
    uint256 public decimals = 18;
    uint256 public totalSupply; // 单位为wei

    // 余额及授权额度
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // 定义转账几授权事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // 转账函数
    function transfer(address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // 授权
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // 授权人转账
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // 转账函数, 只允许内部调用
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
}