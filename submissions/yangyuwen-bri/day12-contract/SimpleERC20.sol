// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

contract SimpleERC20{
    //token meta data
    string public name = "SimpleToken"; //代币全称
    string public symple = "SIM"; //交易代码
    uint8 public decimals = 18; //可分割性：大多使用18位小数
    uint256 public totalSupply;//代币供应量

    mapping(address => uint256) public balance0f;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply){
        totalSupply = _initialSupply * 10 ** decimals; //使用小数表示精度 like ETH use wei
        balance0f[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply); //代币并非来自其他用户，而是凭空产生的
    }

    function transfer(address _to, uint256 _value) public virtual returns(bool){
        require(balance0f[msg.sender] >= _value, "not enough balance.");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns(bool){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return(true);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns(bool){
        require(balance0f[_from] >= _value, "not enough balance.");
        require(allowance[_from][msg.sender] >= _value, "allowance too low.");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal{
        require(_to != address(0), "invalid address.");
        balance0f[_from] -= _value;
        balance0f[_to] += _value;
        emit Transfer(_from, _to, _value);
    } 


}