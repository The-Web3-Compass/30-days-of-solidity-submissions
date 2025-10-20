// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SendSomeTokens {
    mapping(address => uint) public balances;    

    function deposit( ) payable public {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Dont have enough tokens");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transferTo(address _user, uint _amount) public {
        require(_user != address(0), "Invalid Address");
        require(balances[msg.sender] >= _amount, "Dont have enough tokens");
        balances[msg.sender] -= _amount;
        balances[_user] += _amount;
    }
}