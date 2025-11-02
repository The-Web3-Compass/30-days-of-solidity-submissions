//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract SimpleERC20 {
    string public name = "SimpleTolen";
    string public symbol= "SIM";

    //decimal 可分割程度
    uint8 public decimals = 18;

    //当前代币总数
    uint256 public totalSupply;
    
    //每个地址有多少钱
    mapping(address => uint256) public balanceOf;

    //嵌套映射，谁被允许代表谁花费多少
    mapping(address =>mapping(address => uint256)) public allowance;

    //event: 和外界交互的部分--显示交易历史，和显示代理
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender, totalSupply);

    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }



}