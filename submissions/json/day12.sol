// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract CoolCoinERC20 {
    string public name = "CoolCoin";
    string public symbol = "COOL";
    // 小数位数
    uint8 public decimals = 18;
    // 总发行量
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // 转账事件，作用是记录谁转账给谁多少代币
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 批准事件，作用是记录谁批准了谁花费多少代币
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // 初始化发行量
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    // 空投？
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // 授权某个地址可以花费多少代币
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // from 转账 to value 代币
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");
        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }
}