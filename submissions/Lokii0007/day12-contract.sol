// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract MyFirstToken  {
   string public name = "Loki";
   string public symbol ="LOKI";
   uint public decimals = 18;
   uint public totalSupply;

   mapping(address => uint) balanceOf;
   mapping(address => mapping(address => uint)) allowance;

   event Transfer(address indexed from, address indexed to, uint value);
   event Approval(address indexed owner, address indexed spender, uint value);
   
   constructor(uint _initialSupply){
      totalSupply = _initialSupply * (10 ** decimals);
      balanceOf[msg.sender] = totalSupply;

      emit Transfer(address(0), msg.sender, _initialSupply);
   }

   function _transfer(address _from, address _to ,uint256 _value) internal {
      require(_to != address(0), "cant transfer to 0 address");

      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;

      emit  Transfer(_from, _to, _value);
   }

   function transfer(address _to, uint _value) public returns (bool success){
      require(balanceOf[msg.sender] >= _value , "not enough balance");

      _transfer(msg.sender, _to, _value);
      return true;
   }

   function transferFrom(address _from, address _to, uint _value) public  returns(bool){
      require(balanceOf[msg.sender] >= _value, "not enough balance");
      require(allowance[_from][msg.sender] >= _value, "not enough allowance");

      allowance[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value);
        
      return true;
   }

   function approve(address _spender, uint _value) public returns (bool){
    allowance[msg.sender][_spender] -= _value;

    emit Approval(msg.sender, _spender, _value);
    return true;
   }

   
}