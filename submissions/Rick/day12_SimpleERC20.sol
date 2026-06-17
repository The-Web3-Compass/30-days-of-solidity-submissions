// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC20 {
    // 代币全称
    string public name = "SimpleERC";
    // 代币简称
    string public symbol ="SIM";
    // 一枚标准代币 小数点后最多多少位
    uint8 public decimals = 18;
    // 代币总数量
    uint public totalSupply ;

    // 每个地址有多少代币
    mapping(address => uint) public  balanceOf;
    // A允许B使用多少代币
    mapping(address=>mapping(address=>uint)) public allowance;

    // 转账事件 A向B转了多少
    event Transfer(address indexed _from,address indexed _to ,uint _value);
    // _owner 向 _spender 授权了多少额度
    event Approval(address indexed _owner,address indexed _spender,uint _value);

    constructor(uint _initialAmount){
        totalSupply = _initialAmount * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier checkBalance(address _addr , uint _value){
        require(balanceOf[_addr] >= _value,"balance is not enough");
        _;
    }
    
    function transfer(address _to,uint _value) public virtual   checkBalance(msg.sender,_value) returns (bool){
        _transfer(msg.sender,_to,_value);
        return true;
    }

    // 提取的公共方法
    function _transfer(address _from,address _to,uint _value) internal{
        require(_to != address(0), unicode"不允许向零地址转账");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    // A授权B有多少代币转账权限
    function  approve(address spender, uint256 amount) public returns (bool){
        require(balanceOf[msg.sender] >= amount,"allowance is not enough");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // B 使用额度进行转账
    function transferFrom(address _from , address _to , uint _value) public virtual   checkBalance(_from,_value) returns (bool){
        require(allowance[_from][msg.sender] >= _value,"allowance is not enough");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}