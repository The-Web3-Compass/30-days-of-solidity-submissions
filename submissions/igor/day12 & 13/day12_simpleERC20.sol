// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract simpleERC20 {
    string public name = "SimpleToken";
    string public symbol = "SIM";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) balanceOf;
    mapping(address => mapping(address => uint256))allowance;

    event Transfer(address indexed _from,address indexed _to, uint256 value);
    event Approval(address indexed _owner,address indexed _taker,uint256 value);

    constructor(uint256 _initialSupply){
        totalSupply = _initialSupply * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
    }

    function _transfer(address _from, address _to,uint256 _value) internal{
        require(_to != address(0),"address invalid!");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from,_to,_value);
    }

    function trasnfer(address _to,uint256 _value) public{
        require(_to != address(0),"address invalid!");
        _transfer(msg.sender,_to,_value);
    }

    function transferFrom(address _from,address _to,uint256 _value)public{
        require(_to != address(0),"address invalid!");
        _transfer(_from,_to,_value);
    }

    function approve(address _taker,uint256 _value)public{
        allowance[msg.sender][_taker] = _value;
        emit Approval(msg.sender,_taker,_value);
    }


}