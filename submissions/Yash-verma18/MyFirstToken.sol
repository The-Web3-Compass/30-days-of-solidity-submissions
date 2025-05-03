// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyFirstToken {
    address public owner;
    uint256 public totalSupply = 100 * 10 ** 18;

    string public name ;
    string public symbol ;
    uint8 public constant decimal = 18;

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (string memory _tokenName, string memory _symbol) {    
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        name = _tokenName;
        symbol = _symbol;

         emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer (address _to, uint256 _amount) public {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _amount, "Not enough tokens");
       
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
    }

    function approve (address _spender, uint256 _amount) public returns (bool) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom (address _from, address _to ,uint256 _amount) public {
        require(_to != address(0), "Invalid reciepient address");
        require(allowance[_from][msg.sender] >= _amount, "Not enough allowance tokens");
        require(balanceOf[_from] >= _amount, "Not enough tokens");

        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        allowance[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);
    }

}