//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

contract SimpleERC20{
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply){
        totalSupply = _initialSupply * (10**uint(decimals));
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");
        require(balanceOf[msg.sender] >= _value, "Not enough balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to,  _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns(bool) {
        require(_spender != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender,  _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");
        require(allowance[_from][msg.sender] >= _value, "Not enough balance");

        allowance[_from][msg.sender] -= _value;

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to,  _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Not enough balance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to,  _value);
    }
}
