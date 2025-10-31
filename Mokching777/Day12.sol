// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20{
    string public name = "SimpleMokching";
    string public symbol = "MJ";
    uint8 public decimals = 17;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor (uint256 _initialSupply){
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
    require(balanceOf[msg.sender] >= _value, "Not Enough Balance.");
    _transfer(msg.sender, _to, _value);
    return true;
    }

    function _transfer(address _from,address _to,uint256 _value)internal {
        require(_to != address(0),"Invalid address.");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender,uint256 _value) public returns (bool){
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

    //Advanced: Increase Token Destruction
    function burn(uint256 _amount) public returns (bool) {
    require(balanceOf[msg.sender] >= _amount, "Not enough balance to burn");

    balanceOf[msg.sender] -= _amount;
    totalSupply -= _amount;

    emit Transfer(msg.sender, address(0), _amount);
    return true;
    }
}
