// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleERC20 {
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint256 public decimals = 18;
    uint256 public totalSupply;

    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;

    event Transfer(address indexed _from,address indexed _to,uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply){
        totalSupply = initialSupply*(10**decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
    }

    function transfer(address _to,uint256 value)public virtual  returns(bool){
        require(_to!=address(0),"Invalid address");
        require(balanceOf[msg.sender] >= value,"Insufficient balance");
        _transfer(msg.sender,_to,value);
        return true;
    }
    function approve(address _spender,uint256 value)public returns(bool){
        require(_spender!=address(0),"Invalid address");
        allowance[msg.sender][_spender] = value;
        emit Approval(msg.sender, _spender, value);
        return true;
    }
    function transferFrom(address _from,address _to,uint256 _value) public virtual  returns(bool){
        require(_from!=address(0),"Invalid address");
        require(_to!=address(0),"Invalid address");
        require(balanceOf[_from] >= _value,"Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance too low");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function _transfer(address _from,address _to,uint256 value)internal {
        balanceOf[_from] -= value;
        balanceOf[_to] += value;
        emit Transfer(_from,_to,value);
    }
}