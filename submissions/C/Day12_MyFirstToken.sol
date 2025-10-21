// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {
    string public name = "SimpleToken"; // 令牌全名
    string public symbol = "SMI";  // 空头代码
    uint8 public decimals = 18;  // 代币18位小数
    uint256 public totalSupply;  // 代币总数

    mapping(address => uint256) public balanceOf; // 跟踪用户余额
    mapping(address => mapping(address => uint256)) public allowance; // 跟踪授权用户可用余额
    
    event Transfer(address indexed from, address indexed to, uint256 value); // 转移代币事件
    event Approval(address indexed owner, address indexed spender, uint256 value);// 批准转移代币事件

    // 初始化供应代币总额
    constructor(uint256 _initialSupply){
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    // 转移代币前端触发
    function transfer(address _to, uint256 _value)public returns(bool){
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    // 批准转移代币
    function approve(address _spender, uint256 _value) public returns(bool){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    // 进行批准转移代币
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
        require(balanceOf[_from] >= _value,"Not enough balance");
        require(allowance[_from][msg.sender] >= _value,"Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    // 转移代币后端处理
    function _transfer(address _from, address _to, uint256 _value) internal{
        require(_to != address(0), "");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
}