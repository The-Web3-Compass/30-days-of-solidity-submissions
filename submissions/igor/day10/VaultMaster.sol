// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract VaultMaster is Ownable{
    event DepositEvent(address indexed account,uint256 value);
    event WithdrawEvent(address indexed account,uint256 value);

    function deposit()public payable{
        require(msg.value > 0, "value 0");
        emit DepositEvent(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function withdraw(address _to,uint256 _value) public onlyOwner{
        require(_value <= getBalance(),"invalid amount");
        
        (bool success,) = payable(_to).call{value: _value}("");
        require(success, "Tx failed");

        emit WithdrawEvent(_to, _value);
    } 

}