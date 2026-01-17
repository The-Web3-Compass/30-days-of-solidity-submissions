// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
contract VaultMaster is Ownable{
    event DepositSuccessful(address indexed accout ,uint256 value );
    event WithdrawSuccessful(address indexed recipient , uint256 value);

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value > 0 ,"failed");
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdraw(address _to ,uint256 _amount) public onlyOwner{
        require(_amount <= getBalance(),"insufficient balance");

        (bool success,)  = payable(_to).call{value:_amount}("");
        require(success,"transfer failed");

        emit WithdrawSuccessful(_to, _amount);

    }
}